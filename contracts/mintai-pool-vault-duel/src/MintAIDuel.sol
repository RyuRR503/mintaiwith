// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IDuelVaultFactory {
    function launcherFactory() external view returns (address);
}

interface IDuelVault {
    function armDuel() external payable returns (uint256 requestId);
    function burnDuelCard(uint256 id) external;
    function repayDuelTick() external payable;
    function fundTrigger() external payable;
    function duelFee() external view returns (uint256);
    function duelBudget() external view returns (uint256);
}

interface IDuelCards {
    function list(uint256[] calldata tokenIds, uint256[] calldata prices) external;
    function proceedsOwed(address who) external view returns (uint256);
    function withdrawProceeds(address to) external returns (uint256);
}

/// @title MintAIDuel
/// @notice 100 rooms for MINT.AI. Each room holds one waiting card. A player names the room: an empty
///         room waits, and a room that already has someone starts that match. Other rooms stay as they are.
///         A separate 0.1 BNB budget on the vault pays the Flap Trigger fee when it can. Floor tax does
///         not refill that budget. When it cannot cover the fee, the waiting player already deposited
///         half and the joining player deposits the rest. If the budget covers the match, both deposits
///         come back. Wins are stored on the card that won, not on the address. The 6th win of that card
///         burns the card just won and the count on the surviving card returns to zero.
///         The callback is earliest 60 seconds later and reads the previous block. It does not revert.
///         One hour after the match starts, if it still has no winner, settle returns both cards.
///         Deployed behind the vault factory's duel beacon. New variables go at the end.
contract MintAIDuel is Initializable, ReentrancyGuardUpgradeable {
    /// @notice Earliest moment settle can return both cards. The callback may still draw before this.
    uint256 public constant REFUND_DELAY = 1 hours;
    /// @dev Earliest Trigger callback. The vault asks for this delay. The callback reads the previous block.
    uint256 public constant TRIGGER_DELAY = 60;
    uint256 public constant BURN_ON_WIN = 6;
    /// @dev Smallest legal ask. The 6th-win card is listed at this price and burned through the vault's
    ///      existing floorBuy. The price is paid from the trigger reserve and returned in the same transaction.
    uint256 public constant BURN_PRICE = 0.00001 ether;
    /// @dev Rooms 1..100. Each room waits for one card. A started match leaves the room immediately.
    uint256 public constant ROOM_COUNT = 100;

    address public vaultFactory;

    address public cards;
    address public vault;
    uint256 public nextMatch;

    struct Room {
        address player;
        uint256 card;
        uint256 deposit;
    }

    /// @dev Room number the address is waiting in. 0 means this address is not waiting.
    mapping(address => uint256) public waitingRoom;
    mapping(uint256 => Room) private _rooms;

    struct Match {
        address a;
        address b;
        uint256 cardA;
        uint256 cardB;
        uint64 lockBlock;
        uint256 requestId;
        bool open;
    }

    mapping(uint256 => Match) public matches;
    mapping(uint256 => uint256) public requestMatch;
    /// @dev Wins of the card the player fought with. A new card starts at zero. Transferring the card
    ///      keeps the count. The address is not what is counted.
    mapping(uint256 => uint256) public cardWins;
    mapping(address => uint256) public refundOf;
    /// @dev Match start. New storage stays at the end so a later beacon upgrade does not move old fields.
    mapping(uint256 => uint64) public openedAt;

    event CardsBound(address indexed cards);
    event VaultBound(address indexed vault);
    event Waiting(address indexed player, uint256 indexed tokenId, uint256 indexed roomId);
    event WaitingCancelled(address indexed player, uint256 indexed tokenId, uint256 indexed roomId);
    event DuelStarted(
        uint256 indexed matchId,
        address indexed a,
        address indexed b,
        uint256 cardA,
        uint256 cardB,
        uint256 lockBlock,
        uint256 requestId
    );
    event DuelSettled(
        uint256 indexed matchId, address indexed winner, address indexed loser, uint256 wonCard, bool burned, uint256 winsAfter
    );
    event DuelRefunded(uint256 indexed matchId);

    error NotFactory();
    error NotLauncher();
    error NotVault();
    error AlreadyBound();
    error NotBound();
    error SelfDuel();
    error NotWaiting();
    error BadRoom();
    error AlreadyWaiting();
    error NotOpen();
    error TooEarly();
    error HashMissing();
    error ShortPaid();
    error NotSelf();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Vault factory calls this through the proxy constructor.
    function initialize(address vaultFactory_) external initializer {
        __ReentrancyGuard_init();
        if (vaultFactory_ == address(0)) revert NotFactory();
        vaultFactory = vaultFactory_;
    }

    receive() external payable {}

    function bindCards(address cards_) external {
        if (cards != address(0)) revert AlreadyBound();
        if (cards_ == address(0)) revert NotBound();
        if (msg.sender != IDuelVaultFactory(vaultFactory).launcherFactory()) revert NotLauncher();
        cards = cards_;
        emit CardsBound(cards_);
    }

    function bindVault(address vault_) external {
        if (msg.sender != vaultFactory) revert NotFactory();
        if (vault != address(0)) revert AlreadyBound();
        if (vault_ == address(0)) revert NotBound();
        vault = vault_;
        emit VaultBound(vault_);
    }

    /// @notice Who is waiting in `roomId`, the card, and the deposit. An empty room returns zero.
    function roomOf(uint256 roomId) external view returns (address player, uint256 card, uint256 deposit) {
        Room storage room = _rooms[roomId];
        return (room.player, room.card, room.deposit);
    }

    /// @notice Put one card in `roomId` (1..100). An empty room waits. A room with someone else starts
    ///         the match and frees the room. The waiting player deposits half of the current trigger fee.
    ///         The joining player deposits the other half. One address cannot wait in two rooms, and
    ///         cannot play both sides of the same room. Returns 0 when the card is only waiting.
    function enter(uint256 roomId, uint256 tokenId) external payable nonReentrant returns (uint256 matchId) {
        if (cards == address(0) || vault == address(0)) revert NotBound();
        if (roomId == 0 || roomId > ROOM_COUNT) revert BadRoom();
        Room storage room = _rooms[roomId];
        uint256 seated = waitingRoom[msg.sender];
        if (seated != 0) {
            if (seated == roomId && room.player == msg.sender) revert SelfDuel();
            revert AlreadyWaiting();
        }
        uint256 fee = IDuelVault(vault).duelFee();
        uint256 due = room.player == address(0) ? fee / 2 : fee - room.deposit;
        if (msg.value != due) revert ShortPaid();
        IERC721(cards).transferFrom(msg.sender, address(this), tokenId);
        if (room.player == address(0)) {
            room.player = msg.sender;
            room.card = tokenId;
            room.deposit = msg.value;
            waitingRoom[msg.sender] = roomId;
            emit Waiting(msg.sender, tokenId, roomId);
            return 0;
        }
        address host = room.player;
        uint256 hostCard = room.card;
        uint256 hostDeposit = room.deposit;
        room.player = address(0);
        room.card = 0;
        room.deposit = 0;
        waitingRoom[host] = 0;
        uint256 requestId;
        if (IDuelVault(vault).duelBudget() >= fee && fee != 0) {
            requestId = IDuelVault(vault).armDuel();
            _refund(host, hostDeposit);
            _refund(msg.sender, msg.value);
        } else {
            requestId = IDuelVault(vault).armDuel{value: hostDeposit + msg.value}();
        }
        matchId = ++nextMatch;
        matches[matchId] = Match({
            a: host,
            b: msg.sender,
            cardA: hostCard,
            cardB: tokenId,
            lockBlock: uint64(block.number),
            requestId: requestId,
            open: true
        });
        requestMatch[requestId] = matchId;
        openedAt[matchId] = uint64(block.timestamp);
        emit DuelStarted(matchId, host, msg.sender, hostCard, tokenId, block.number, requestId);
    }

    /// @notice Take back the waiting card, its deposit, and the dividend it earned while waiting.
    ///         A started match cannot be cancelled.
    function cancel() external nonReentrant {
        uint256 roomId = waitingRoom[msg.sender];
        if (roomId == 0) revert NotWaiting();
        Room storage room = _rooms[roomId];
        if (room.player != msg.sender) revert NotWaiting();
        uint256 tokenId = room.card;
        uint256 deposit = room.deposit;
        room.player = address(0);
        room.card = 0;
        room.deposit = 0;
        waitingRoom[msg.sender] = 0;
        _give(tokenId, msg.sender);
        _flush(msg.sender);
        _refund(msg.sender, deposit);
        emit WaitingCancelled(msg.sender, tokenId, roomId);
    }

    /// @notice Pull a deposit the contract could not send.
    function withdrawRefund() external nonReentrant {
        uint256 amount = refundOf[msg.sender];
        if (amount == 0) revert ShortPaid();
        refundOf[msg.sender] = 0;
        (bool ok,) = msg.sender.call{value: amount}("");
        if (!ok) revert ShortPaid();
    }

    /// @notice Flap Trigger entry, forwarded by the vault. An id that was never a duel request returns
    ///         false so the vault can reject it. A closed match, a missing hash, or a failed settlement
    ///         returns true and does not revert. The hash is the block before this call.
    function onTrigger(uint256 requestId) external nonReentrant returns (bool) {
        if (msg.sender != vault) revert NotVault();
        uint256 matchId = requestMatch[requestId];
        if (matchId == 0) return false;
        if (!matches[matchId].open) return true;
        bytes32 hash = blockhash(block.number - 1);
        if (hash == bytes32(0)) {
            _refundMatch(matchId);
            return true;
        }
        try this.draw(matchId, hash) {} catch {
            if (matches[matchId].open) _refundMatch(matchId);
        }
        return true;
    }

    /// @dev Trigger-only draw. A direct call reverts. State rolls back if settlement fails.
    function draw(uint256 matchId, bytes32 hash) external {
        if (msg.sender != address(this)) revert NotSelf();
        _draw(matchId, hash);
    }

    /// @notice One hour after the match starts, return both cards if it still has no winner.
    function settle(uint256 matchId) external nonReentrant {
        Match storage m = matches[matchId];
        if (!m.open) revert NotOpen();
        if (block.timestamp < uint256(openedAt[matchId]) + REFUND_DELAY) revert TooEarly();
        _refundMatch(matchId);
    }

    /// @notice Kept for callers. An open match does not reveal its winner before the callback.
    function preview(uint256) external pure returns (address winner, bool ready) {
        return (address(0), false);
    }

    function _refundMatch(uint256 matchId) private {
        Match storage m = matches[matchId];
        if (!m.open) return;
        m.open = false;
        _give(m.cardA, m.a);
        _flush(m.a);
        _give(m.cardB, m.b);
        _flush(m.b);
        emit DuelRefunded(matchId);
    }

    function _draw(uint256 matchId, bytes32 hash) private {
        Match storage m = matches[matchId];
        if (!m.open) revert NotOpen();
        if (hash == bytes32(0)) revert HashMissing();
        bool aWins = _winnerOf(m, hash) == m.a;
        address winner = aWins ? m.a : m.b;
        address loser = aWins ? m.b : m.a;
        uint256 ownCard = aWins ? m.cardA : m.cardB;
        uint256 wonCard = aWins ? m.cardB : m.cardA;
        uint256 n = cardWins[ownCard] + 1;
        bool burned = n == BURN_ON_WIN;
        cardWins[ownCard] = burned ? 0 : n;
        m.open = false;
        _give(ownCard, winner);
        if (burned) _burn(wonCard, winner);
        else _give(wonCard, winner);
        _flush(winner);
        emit DuelSettled(matchId, winner, loser, wonCard, burned, cardWins[ownCard]);
    }

    function _winnerOf(Match memory m, bytes32 hash) private pure returns (address) {
        return uint256(keccak256(abi.encodePacked(hash, m.cardA, m.cardB))) & 1 == 0 ? m.a : m.b;
    }

    function _give(uint256 tokenId, address to) private {
        IERC721(cards).transferFrom(address(this), to, tokenId);
    }

    /// @dev List the card at the minimum ask and burn it through the vault. The ask is returned to the
    ///      trigger reserve. Any dividend the card earned while locked is forwarded to `to`.
    function _burn(uint256 tokenId, address to) private {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory prices = new uint256[](1);
        ids[0] = tokenId;
        prices[0] = BURN_PRICE;
        IDuelCards(cards).list(ids, prices);
        uint256 before = address(this).balance;
        IDuelVault(vault).burnDuelCard(tokenId);
        _pullProceeds();
        uint256 got = address(this).balance - before;
        if (got < BURN_PRICE) revert ShortPaid();
        IDuelVault(vault).repayDuelTick{value: BURN_PRICE}();
        _sendOrReserve(to, got - BURN_PRICE);
    }

    function _flush(address to) private {
        uint256 before = address(this).balance;
        _pullProceeds();
        _sendOrReserve(to, address(this).balance - before);
    }

    function _pullProceeds() private {
        if (IDuelCards(cards).proceedsOwed(address(this)) != 0) {
            IDuelCards(cards).withdrawProceeds(address(this));
        }
    }

    function _sendOrReserve(address to, uint256 amount) private {
        if (amount == 0) return;
        (bool ok,) = to.call{value: amount}("");
        if (!ok) IDuelVault(vault).fundTrigger{value: amount}();
    }

    function _refund(address to, uint256 amount) private {
        if (amount == 0) return;
        (bool ok,) = to.call{value: amount}("");
        if (!ok) refundOf[to] += amount;
    }
}
