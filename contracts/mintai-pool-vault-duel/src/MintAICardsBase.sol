// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {LaunchVaultAddresses} from "./flap/LaunchVaultAddresses.sol";
import {IMintAIVault} from "./MintAIInterfaces.sol";

/// @notice Storage and shared accounting for the cards proxy.
///         MintAICardMarket delegatecalls into this same layout. Do not reorder or insert variables.
abstract contract MintAICardsBase is Initializable, ReentrancyGuardUpgradeable, ERC721Upgradeable {
    struct Listing {
        address seller;
        uint96 price;
    }

    struct Bid {
        address bidder;
        uint96 price;
        uint32 remaining;
    }

    uint256 public constant PAID_CAP = 738_889;
    uint256 internal constant TEAM_CAP = 38_888;
    uint256 internal constant FIRST_BATCH = 20_000;
    uint256 internal constant PRESALE_PRICE = 0.00245 ether;
    uint256 public constant MINT_PRICE = 0.0049 ether;
    uint256 internal constant UNLOCK_EVERY = 19;
    uint256 public constant OPS_BPS = 2_500;
    uint256 internal constant MARKET_FEE_BPS = 100;
    uint256 internal constant BPS = 10_000;
    uint256 internal constant MAX_MINT_PER_TX = 10;
    uint256 internal constant TEAM_MINT_CHUNK = 100;
    uint256 internal constant MAX_BATCH = 250;
    uint256 internal constant OPS_PUSH_GAS = 50_000;
    /// @dev Same Agent ID NFT the existing MINT.AI vaults check. Holding one is enough.
    address public constant AGENT_ID_NFT = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;
    /// @notice Pool Launch Portal. Same address on BSC mainnet and testnet.
    address public constant portal = 0x000042108465206185A077Edc3F3fd2b49060000;
    uint256 public constant MAX_MINTS = 10;
    uint256 internal constant PRESALE_WINDOW = 7 days;
    address internal constant PANCAKE_V2_MAINNET = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address internal constant PANCAKE_V2_TESTNET = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    uint256 internal constant LADDER_STREAM = 7 days;
    /// @dev Smallest ladder payment that may open or top up a dividend stream.
    uint256 internal constant MIN_LADDER_STREAM = 0.01 ether;
    uint256 internal constant PRICE_TICK = 0.00001 ether;
    uint256 internal constant MAX_TICK = 1 << 20;
    uint256 internal constant ACC = 1e18;

    address public owner;
    address public opsWallet;
    address public teamWallet;
    address public router;
    address public factory;
    uint256 public presaleDeadline;

    string public tokenName;
    string public tokenSymbol;
    string public tokenMeta;
    bytes32 public salt;
    /// @dev Set in the transaction that mints the 20,000th presale card and opens the pool.
    uint256 public presaleFilledAt;
    bool public saltLocked;

    address public launchedToken;
    address public launchedPool;
    address public vault;
    bool public launched;
    bool public launching;

    uint256 public paidMinted;
    uint256 public teamMinted;
    uint256 public lastTokenId;
    uint256 public presaleEscrow;

    /// @dev Every BNB wei this contract owes: presaleEscrow + dividendLiability + pendingDividend
    ///      + streamRemaining + sideStreamRemaining + opsOwed + bidEscrow + proceedsLiability.
    uint256 public booked;

    uint256 public totalWeight;
    uint256 public accRewardPerShare;
    uint256 public dividendLiability;
    uint256 public pendingDividend;
    uint256 public streamRemaining;
    uint256 public streamRate;
    uint256 public streamEnd;
    uint256 public streamLast;
    uint256 public opsOwed;

    uint256 public totalDividendIn;
    uint256 public totalDividendPaid;
    uint256 public totalOpsPaid;

    mapping(address => uint256) public mintsUsed;
    /// @dev Presale cards minted by each address; MintAIVault vests 8,440 tokens per card from launch.
    mapping(address => uint256) public presaleCards;
    mapping(uint256 => bool) public isTeamCard;
    mapping(uint256 => uint256) public rewardDebt;

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Bid) public bids;
    uint256 public nextBidId;
    uint256 public bidEscrow;
    mapping(address => uint256) public proceedsOwed;
    uint256 public proceedsLiability;
    uint256 public totalMarketFees;
    /// @dev One bit per listed card id / open bid id, paged by MintAICardsLens.
    mapping(uint256 => uint256) public listedBits;
    mapping(uint256 => uint256) public openBidBits;
    /// @dev Listings per price tick, one bit per non-empty tick, one bit per non-empty tickBits word,
    ///      and a lower bound for the lowest listed tick.
    mapping(uint256 => uint256) public tickCount;
    mapping(uint256 => uint256) public tickBits;
    mapping(uint256 => uint256) public tickWordBits;
    uint256 public floorHint;
    /// @dev Listed ids per `tick << 1 | post`, where post = 1 for post-open paid cards and 0 for presale and
    ///      team cards. Newest first; 0 ends a list.
    mapping(uint256 => uint256) public tickHead;
    mapping(uint256 => uint256) public nextListed;
    mapping(uint256 => uint256) internal prevListed;
    /// @dev 1-based team ordinal => the second a paid mint unlocked it. The token vest starts then.
    mapping(uint256 => uint40) public teamUnlockAt;
    /// @dev Ladder BNB that arrived while `streamRemaining` was still paying out. The first payment
    ///      has its own 7 days. A later payment keeps that end and only raises the rate.
    uint256 public sideStreamRemaining;
    uint256 public sideStreamRate;
    uint256 public sideStreamEnd;
    uint256 public sideStreamLast;

    event PaidMint(address indexed minter, uint256 indexed tokenId, uint256 paidIndex, uint256 price);
    event TeamCardMinted(uint256 indexed tokenId, uint256 ordinal);
    event Refunded(uint256 indexed tokenId, address indexed to, uint256 amount);
    event Launched(address indexed token, address indexed pair, address indexed vault, uint256 opsShare);
    event DividendIndexed(uint256 amount, uint256 weight);
    event DividendClaimed(address indexed to, uint256 amount);
    event OpsPaid(address indexed to, uint256 amount);
    event OpsDeferred(address indexed to, uint256 amount);
    event Listed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event Unlisted(uint256 indexed tokenId, address indexed seller);
    event Sold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price, uint256 fee);
    event BidPlaced(uint256 indexed bidId, address indexed bidder, uint256 price, uint256 quantity);
    event BidCancelled(uint256 indexed bidId, address indexed bidder, uint256 refund);
    event ProceedsCredited(address indexed to, uint256 amount);
    event ProceedsWithdrawn(address indexed from, address indexed to, uint256 amount);
    event RoleUpdated(string role, address indexed previous, address indexed next);

    error ZeroAddress();
    error NotOwnerOrGuardian();
    error NotGuardian();
    error NotVault();
    error NotLaunched();
    error AlreadyLaunched();
    error PresaleClosed();
    error PresaleNotFailed();
    error PresaleFull();
    error PresaleNotSoldOut();
    error LaunchClosed();
    error SoldOut();
    error AgentIdRequired();
    error MintCapReached();
    error BadCount();
    error WrongPayment(uint256 expected, uint256 sent);
    error NotCardOwner();
    error NotTeam();
    error TeamNotUnlocked();
    error TransferLocked();
    error NothingToClaim();
    error PayFailed();
    error BadOrder();
    error BadPrice();
    error NotBidder();
    error BidFilled();
    error NothingBought();
    error OccupiedFunds(uint256 free, uint256 requested);
    error LaunchFailed();
    error SaltNotLocked();
    error BadRouter();
    error ZeroMinTokens();
    error LadderTooSmall(uint256 amount);

    modifier onlyOwnerOrGuardian() {
        if (msg.sender != owner && msg.sender != LaunchVaultAddresses.guardian()) revert NotOwnerOrGuardian();
        _;
    }

    function _lowBit(uint256 bits) internal pure returns (uint256 r) {
        while (bits & 1 == 0) {
            bits >>= 1;
            unchecked {
                ++r;
            }
        }
    }

    function _addWeight(uint256 tokenId) internal {
        _accrueStream();
        _index(0);
        rewardDebt[tokenId] = accRewardPerShare;
        totalWeight += 1;
    }

    /// @dev Spread `amount` plus any undistributed remainder over the current cards.
    function _index(uint256 amount) internal {
        uint256 pending = pendingDividend + amount;
        uint256 weight = totalWeight;
        if (pending == 0 || weight == 0) {
            pendingDividend = pending;
            return;
        }
        uint256 share = pending * ACC / weight;
        if (share == 0) {
            pendingDividend = pending;
            return;
        }
        accRewardPerShare += share;
        uint256 used = (share * weight + ACC - 1) / ACC;
        if (used > pending) used = pending;
        pendingDividend = pending - used;
        dividendLiability += used;
        emit DividendIndexed(used, weight);
    }

    function _streamDue() internal view returns (uint256 due) {
        if (streamRemaining == 0) return 0;
        if (block.timestamp >= streamEnd) return streamRemaining;
        due = (block.timestamp - streamLast) * streamRate / ACC;
        if (due > streamRemaining) due = streamRemaining;
    }

    function _sideDue() internal view returns (uint256 due) {
        if (sideStreamRemaining == 0) return 0;
        if (block.timestamp >= sideStreamEnd) return sideStreamRemaining;
        due = (block.timestamp - sideStreamLast) * sideStreamRate / ACC;
        if (due > sideStreamRemaining) due = sideStreamRemaining;
    }

    function _accrueStream() internal {
        uint256 due = _streamDue();
        uint256 side = _sideDue();
        if (due + side == 0) return;
        if (due != 0) {
            streamRemaining -= due;
            streamLast = block.timestamp;
            if (streamRemaining == 0) streamRate = 0;
        }
        if (side != 0) {
            sideStreamRemaining -= side;
            sideStreamLast = block.timestamp;
            if (sideStreamRemaining == 0) sideStreamRate = 0;
        }
        _index(due + side);
    }

    function _settleDividend(uint256 tokenId) internal returns (uint256 amount) {
        uint256 acc = accRewardPerShare;
        amount = (acc - rewardDebt[tokenId]) / ACC;
        rewardDebt[tokenId] = acc;
        dividendLiability -= amount;
        totalDividendPaid += amount;
    }

    /// @dev Moves a sold card. The seller gets price - 1% fee plus the card's dividend so far.
    function _settleSale(uint256 tokenId, address seller, address buyer, uint256 price)
        internal
        returns (uint256 toSeller)
    {
        uint256 fee = price * MARKET_FEE_BPS / BPS;
        opsOwed += fee;
        totalMarketFees += fee;
        uint256 dividend = _settleDividend(tokenId);
        _transfer(seller, buyer, tokenId);
        toSeller = price - fee + dividend;
        emit Sold(tokenId, seller, buyer, price, fee);
    }

    /// @dev Transfers are locked before launch. On a plain transfer the card's dividend so far is credited to
    ///      the sender as withdrawable proceeds. Burns (presale refunds, floor buys) remove the card's weight;
    ///      callers settle the dividend first.
    function _update(address to, uint256 tokenId, address auth) internal override returns (address from) {
        address prev = _ownerOf(tokenId);
        if (prev != address(0) && to != address(0)) {
            if (!launched) revert TransferLocked();
            _accrueStream();
            uint256 earned = _settleDividend(tokenId);
            if (earned != 0) {
                proceedsOwed[prev] += earned;
                proceedsLiability += earned;
                emit ProceedsCredited(prev, earned);
            }
            if (vault != address(0)) IMintAIVault(vault).moveCardVest(to, tokenId);
        } else if (prev != address(0)) {
            totalWeight -= 1;
        }
        from = super._update(to, tokenId, auth);
        if (listings[tokenId].seller != address(0)) _clearListing(tokenId);
    }

    function _clearListing(uint256 id) internal {
        uint256 tick = listings[id].price / PRICE_TICK;
        delete listings[id];
        listedBits[id >> 8] &= ~(1 << (id & 255));
        uint256 next = nextListed[id];
        uint256 prev = prevListed[id];
        if (prev == 0) tickHead[tick << 1 | (id > FIRST_BATCH && !isTeamCard[id] ? 1 : 0)] = next;
        else nextListed[prev] = next;
        if (next != 0) prevListed[next] = prev;
        delete nextListed[id];
        delete prevListed[id];
        if (--tickCount[tick] == 0) {
            uint256 w = tick >> 8;
            uint256 bits = tickBits[w] & ~(1 << (tick & 255));
            tickBits[w] = bits;
            if (bits == 0) tickWordBits[w >> 8] &= ~(1 << (w & 255));
        }
    }

    function _pushOps() internal {
        uint256 amount = opsOwed;
        if (amount == 0) return;
        address to = opsWallet;
        opsOwed = 0;
        booked -= amount;
        uint256 gasCap = OPS_PUSH_GAS;
        bool ok;
        assembly {
            ok := call(gasCap, to, amount, 0, 0, 0, 0)
        }
        if (ok) {
            totalOpsPaid += amount;
            emit OpsPaid(to, amount);
        } else {
            opsOwed = amount;
            booked += amount;
            emit OpsDeferred(to, amount);
        }
    }

    function _sendBnb(address to, uint256 amount) internal {
        booked -= amount;
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert PayFailed();
    }

    function _payOrCredit(address to, uint256 amount) internal {
        if (amount == 0) return;
        booked -= amount;
        uint256 gasCap = OPS_PUSH_GAS;
        bool ok;
        assembly {
            ok := call(gasCap, to, amount, 0, 0, 0, 0)
        }
        if (!ok) {
            booked += amount;
            proceedsOwed[to] += amount;
            proceedsLiability += amount;
            emit ProceedsCredited(to, amount);
        }
    }
}
