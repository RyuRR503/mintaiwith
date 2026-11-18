// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {LaunchVaultAddresses} from "./flap/LaunchVaultAddresses.sol";
import {
    FeeSlotType,
    FeeConfig,
    FeeConfigVault,
    CreateTaxTokenParams,
    DistributionTarget,
    Distribution,
    CreatorBuyParams,
    IDirectLaunchPortal
} from "./flap/IDirectPoolLaunch.sol";
import {MintAIParams as P} from "./MintAIParams.sol";
import {IMintAIVault, IMintAIFactory} from "./MintAIInterfaces.sol";
import {MintAICardsBase} from "./MintAICardsBase.sol";

/**
 * @title MintAICards
 * @notice MINT.AI cards. The NFT collection name and symbol are both MINT.AI. Sells the presale, launches the token through Flap Pool Launch, then keeps
 *         selling cards at a flat price, splits BNB dividends, runs the card market and spends
 *         the floor fund on the cheapest listed cards.
 *
 * Cards
 *   - 777,777 cards: 738,889 paid and 38,888 team cards. Every 19 paid cards unlock 1 team card.
 *   - Presale cards (the first 20,000 paid cards) cost 0.00245 BNB. Every later paid card costs 0.0049 BNB.
 *   - Buyers must hold an Agent ID NFT (balanceOf > 0 on the shared Agent ID contract). Each address can
 *     mint 10 paid cards in its lifetime. Burning does not restore the quota. The card market does not use it.
 *
 * Presale
 *   - BNB is escrowed here. Cards cannot be transferred before launch.
 *   - The sale runs for 7 days from creation. If 20,000 are not sold by then, every holder can burn
 *     for a full refund. The mint that sells the 20,000th card launches in that same transaction.
 *     A sold-out presale cannot be refunded.
 *   - Launch sends 36.75 BNB + 124,672,000 tokens into the pool (LP burned),
 *     the vault receives the other 653,105,777 tokens, and 12.25 BNB (25% of the presale) goes to the ops wallet.
 *     A failed presale still refunds the full 0.00245; the 25% is taken only when launch succeeds.
 *
 * Tokens (MintAIVault holds the schedules; all vest linearly over 5 days and stay with the receiving address)
 *   - Each presale card: 8,440 tokens from the vault reserve, vesting from launch.
 *   - Each team card: 8,440 tokens from the vault reserve, vesting from the second that paid mint unlocked it.
 *   - Each post-open paid card: 25% of the payment to ops; 75% buys tokens on the pool at the current price.
 *     10% of what is bought is burned, 90% vests to the minter from the mint. The amount is fixed at the mint.
 *
 * Dividends
 *   - 50% of the vault's tax revenue and all ladder proceeds (streamed over 7 days) are split equally per card.
 *   - New cards do not share revenue that arrived before them. On any transfer the seller keeps what the
 *     card earned so far.
 *
 * Floor fund
 *   - 30% of the vault's tax revenue, held and spent by MintAIVault through floorBuy (see MintAIVault).
 *     Listings are kept in one list per price tick and card class so the vault can walk them cheapest first.
 *
 * Market
 *   - Sell orders without escrow and buy orders with escrow. 1% of every fill goes to the ops wallet.
 *     Ask prices are multiples of 0.00001 BNB below 10.48576 BNB.
 */
contract MintAICards is MintAICardsBase {
    struct InitParams {
        address owner;
        address opsWallet;
        address teamWallet;
        address router;
        string tokenName;
        string tokenSymbol;
        string tokenMeta;
        bytes32 salt;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Called by the launcher factory while it creates this proxy. `vaultFactory_` is the pl-v1 factory.
    function initialize(InitParams calldata init, address vaultFactory_) external payable initializer {
        __ERC721_init("MINT.AI", "MINT.AI");
        __ReentrancyGuard_init();
        if (
            init.owner == address(0) || init.opsWallet == address(0) || init.teamWallet == address(0)
                || vaultFactory_ == address(0)
        ) revert ZeroAddress();
        address pancake = block.chainid == 56 ? PANCAKE_V2_MAINNET : PANCAKE_V2_TESTNET;
        if (init.router != pancake) revert BadRouter();
        owner = init.owner;
        opsWallet = init.opsWallet;
        teamWallet = init.teamWallet;
        router = pancake;
        presaleDeadline = block.timestamp + PRESALE_WINDOW;
        tokenName = init.tokenName;
        tokenSymbol = init.tokenSymbol;
        tokenMeta = init.tokenMeta;
        salt = init.salt;
        factory = vaultFactory_;
        _screen(init.tokenName, init.tokenSymbol);
        uint256 fee = IDirectLaunchPortal(portal).SALT_LOCK_FEE();
        if (msg.value != fee) revert WrongPayment(fee, msg.value);
        IDirectLaunchPortal(portal).lockSalt{value: fee}(init.salt, 0);
        saltLocked = true;
    }

    /// @notice Feed JSON read by the Pool Launch Portal at creation. `v` is the only number.
    ///         Only the token name and symbol are escaped. Titles and summaries are constants.
    function description() external view returns (string memory) {
        return string.concat(
            '{"v":1,"name":"',
            _jsonEscape(tokenName),
            '","symbol":"',
            _jsonEscape(tokenSymbol),
            '","quoteToken":"0x0000000000000000000000000000000000000000","targetRaise":"',
            Strings.toString(FIRST_BATCH * PRESALE_PRICE),
            '","poolTokenRatio":"',
            Strings.toString(P.POOL_TOKEN * 1e18 / P.TOTAL_SUPPLY),
            '","titleZh":"MINT.AI","titleEn":"MINT.AI","summaryZh":"',
            "\u9884\u552e 20,000 \u5f20\uff0c\u6bcf\u5f20 0.00245 BNB\uff0c7 \u5929\u6ca1\u5356\u6ee1\u53ef\u5168\u989d\u9000\u6b3e\u3002\u5f00\u76d8\u540e\u6bcf\u5f20 0.0049 BNB\u3002\u6bcf\u7b14\u94f8\u9020\u6b3e 25% \u7ed9\u8fd0\u8425\u3002\u9884\u552e\u5361\u548c\u56e2\u961f\u5361\u5404\u5f97 8,440 \u679a\u3002\u7a0e 2%\uff0c\u6309\u6301\u5361\u4eba 50%\u3001\u5730\u677f 30%\u3001\u8fd0\u8425 20% \u5206\u914d\u3002\u5e02\u573a\u6210\u4ea4\u8d39 1%\u3002",
            '","summaryEn":"',
            "Presale: 20,000 cards at 0.00245 BNB. Unsold after 7 days can be fully refunded. After launch, 0.0049 BNB per card. 25% of each mint payment goes to operations. Each presale card and team card receives 8,440 tokens. The 2% tax splits 50% to holders, 30% to the floor, and 20% to operations. Market fee is 1%.",
            '"}'
        );
    }

    // ---------------------------------------------------------------- mint

    /// @notice Buy `count` paid cards for exactly `priceOf(next) * count`. After launch `minTokens` is the least
    ///         number of tokens that must vest to the caller from this mint; it is ignored during the presale.
    function mint(uint256 count, uint256 minTokens) external payable nonReentrant returns (uint256 lastId) {
        if (count == 0 || count > MAX_MINT_PER_TX) revert BadCount();
        if (IERC721(AGENT_ID_NFT).balanceOf(msg.sender) == 0) revert AgentIdRequired();
        uint256 used = mintsUsed[msg.sender] + count;
        if (used > MAX_MINTS) revert MintCapReached();
        mintsUsed[msg.sender] = used;
        uint256 paid = paidMinted;
        bool live = launched;
        if (!live) {
            if (block.timestamp > presaleDeadline) revert PresaleClosed();
            if (paid + count > FIRST_BATCH) revert PresaleFull();
            if (paid + count == FIRST_BATCH && !saltLocked) revert SaltNotLocked();
        } else if (paid + count > PAID_CAP) {
            revert SoldOut();
        }
        uint256 price = live ? MINT_PRICE : PRESALE_PRICE;
        uint256 total = price * count;
        if (msg.value != total) revert WrongPayment(total, msg.value);
        // Split tax that is already in the vault before these new cards take weight.
        if (live) _syncVault();

        for (uint256 i; i < count; ++i) {
            uint256 index = paid + i + 1;
            lastId = ++lastTokenId;
            _mint(msg.sender, lastId);
            _addWeight(lastId);
            if (index % UNLOCK_EVERY == 0) teamUnlockAt[index / UNLOCK_EVERY] = uint40(block.timestamp);
            emit PaidMint(msg.sender, lastId, index, price);
        }
        paidMinted = paid + count;

        if (!live) {
            presaleEscrow += total;
            booked += total;
            if (presaleCards[msg.sender] == 0) IMintAIFactory(factory).notePresaleBuyer(msg.sender);
            presaleCards[msg.sender] += count;
            if (paidMinted == FIRST_BATCH) {
                presaleFilledAt = block.timestamp;
                _openPool();
            }
        } else {
            if (minTokens == 0) revert ZeroMinTokens();
            uint256 ops = total * OPS_BPS / BPS;
            opsOwed += ops;
            booked += ops;
            IMintAIVault(vault).buyForMint{value: total - ops}(msg.sender, lastId + 1 - count, count, minTokens);
            _pushOps();
        }
    }

    /// @notice Mint `count` unlocked team cards to `to`. Only the team wallet, only after launch, at most 100
    ///         cards per call. Each card vests 8,440 from the second its ordinal was unlocked. Call again for
    ///         another wallet or another batch.
    function mintTeam(address to, uint256 count) external nonReentrant {
        if (msg.sender != teamWallet) revert NotTeam();
        if (!launched) revert NotLaunched();
        if (to == address(0)) revert ZeroAddress();
        if (count == 0 || count > TEAM_MINT_CHUNK) revert BadCount();
        uint256 cursor = teamMinted;
        if (cursor + count > paidMinted / UNLOCK_EVERY) revert TeamNotUnlocked();
        // Split tax that is already in the vault before these team cards take weight.
        _syncVault();
        for (uint256 i; i < count; ++i) {
            uint256 id = ++lastTokenId;
            isTeamCard[id] = true;
            _mint(to, id);
            _addWeight(id);
            emit TeamCardMinted(id, cursor + i);
        }
        teamMinted = cursor + count;
        IMintAIVault(vault).addTeamGrants(to, cursor, count);
    }

    /// @notice Burn presale cards for a full refund once the presale window ended without selling out.
    function refund(uint256[] calldata tokenIds) external nonReentrant returns (uint256 amount) {
        if (launched || paidMinted >= FIRST_BATCH || block.timestamp <= presaleDeadline) revert PresaleNotFailed();
        uint256 n = tokenIds.length;
        if (n == 0 || n > MAX_BATCH) revert BadOrder();
        for (uint256 i; i < n; ++i) {
            uint256 id = tokenIds[i];
            if (_ownerOf(id) != msg.sender) revert NotCardOwner();
            _burn(id);
            amount += PRESALE_PRICE;
            emit Refunded(id, msg.sender, PRESALE_PRICE);
        }
        presaleEscrow -= amount;
        _sendBnb(msg.sender, amount);
    }

    // ---------------------------------------------------------------- launch

    /// @dev Opens the pool in the mint that sells the 20,000th presale card. The vault launcher is the project owner.
    function _openPool() private {
        if (launched) revert AlreadyLaunched();
        if (paidMinted < FIRST_BATCH) revert PresaleNotSoldOut();
        if (!saltLocked) revert SaltNotLocked();
        launching = true;
        (address token_, address pair_) = IDirectLaunchPortal(portal).launchTaxTokenV2{value: P.POOL_QUOTE}(
            _launchParams(), Distribution(DistributionTarget.VAULT, address(0), uint128(P.RESERVE), ""),
            CreatorBuyParams(0, "")
        );
        launching = false;
        if (uint16(uint160(token_)) != 0x7777) revert LaunchFailed();
        address vault_ = IMintAIFactory(factory).vaultOf(token_);
        if (vault_ == address(0) || token_ == address(0) || pair_ == address(0)) revert LaunchFailed();
        launchedToken = token_;
        launchedPool = pair_;
        vault = vault_;
        launched = true;

        uint256 escrow = presaleEscrow;
        uint256 opsShare = escrow - P.POOL_QUOTE;
        presaleEscrow = 0;
        booked -= P.POOL_QUOTE;
        opsOwed += opsShare;
        IMintAIVault(vault_).onLaunched(pair_, router, owner);
        emit Launched(token_, pair_, vault_, opsShare);
        _pushOps();
    }

    // ---------------------------------------------------------------- dividends

    /// @notice Claim the BNB dividend of the given cards.
    function claim(uint256[] calldata tokenIds) external nonReentrant returns (uint256 amount) {
        _syncVault();
        uint256 n = tokenIds.length;
        if (n == 0 || n > MAX_BATCH) revert BadOrder();
        _accrueStream();
        for (uint256 i; i < n; ++i) {
            uint256 id = tokenIds[i];
            if (_ownerOf(id) != msg.sender) revert NotCardOwner();
            amount += _settleDividend(id);
        }
        if (amount == 0) revert NothingToClaim();
        _sendBnb(msg.sender, amount);
        emit DividendClaimed(msg.sender, amount);
    }

    /// @notice Vault hook: card dividend now, ladder proceeds streamed over 7 days, and the ops share.
    ///         An open main stream keeps its rate and end. The first side payment starts its own 7 days.
    ///         A later side payment keeps that end and raises the rate so the old remainder is not spread out again.
    ///         A ladder payment under 0.01 BNB is rejected.
    function onVaultRevenue(uint256 dividendNow, uint256 dividendStream, uint256 ops) external payable {
        if (msg.sender != vault) revert NotVault();
        uint256 total = dividendNow + dividendStream + ops;
        if (msg.value != total) revert WrongPayment(total, msg.value);
        if (dividendStream != 0 && dividendStream < MIN_LADDER_STREAM) revert LadderTooSmall(dividendStream);
        booked += total;
        opsOwed += ops;
        totalDividendIn += dividendNow + dividendStream;
        _accrueStream();
        if (dividendStream != 0) {
            if (streamRemaining == 0) {
                streamRemaining = dividendStream;
                streamRate = dividendStream * ACC / LADDER_STREAM;
                streamEnd = block.timestamp + LADDER_STREAM;
                streamLast = block.timestamp;
            } else if (sideStreamRemaining == 0) {
                sideStreamRemaining = dividendStream;
                sideStreamRate = dividendStream * ACC / LADDER_STREAM;
                sideStreamEnd = block.timestamp + LADDER_STREAM;
                sideStreamLast = block.timestamp;
            } else {
                sideStreamRemaining += dividendStream;
                uint256 span = sideStreamEnd > block.timestamp ? sideStreamEnd - block.timestamp : 1;
                uint256 faster = sideStreamRemaining * ACC / span;
                if (faster > sideStreamRate) sideStreamRate = faster;
                sideStreamLast = block.timestamp;
            }
        }
        _index(dividendNow);
    }

    /// @notice Release streamed dividends and retry any deferred ops payment.
    function poke() external nonReentrant {
        _accrueStream();
        _pushOps();
    }

    // ---------------------------------------------------------------- floor fund

    /// @notice Vault-only: buy listed card `id` at its exact ask with the floor fund sent along. The seller gets
    ///         the full price plus the card's dividend so far, and the card is burned.
    function floorBuy(uint256 id) external payable nonReentrant {
        if (msg.sender != vault) revert NotVault();
        Listing memory l = listings[id];
        if (l.seller == address(0) || l.price != msg.value) revert BadPrice();
        booked += msg.value;
        _accrueStream();
        uint256 dividend = _settleDividend(id);
        _burn(id);
        _payOrCredit(l.seller, msg.value + dividend);
    }

    // ---------------------------------------------------------------- market
    // Bodies live on MintAICardMarket, deployed with the vault factory. Delegatecall keeps the proxy storage.
    // Argument names are omitted here. `_toMarket` forwards the entire calldata, and the market module reads it.

    function list(uint256[] calldata, uint256[] calldata) external {
        _toMarket();
    }

    function unlist(uint256[] calldata) external {
        _toMarket();
    }

    function buy(uint256[] calldata, uint256[] calldata) external payable returns (uint256) {
        _syncVault();
        _toMarket();
    }

    function placeBid(uint256, uint256) external payable returns (uint256) {
        _toMarket();
    }

    function cancelBids(uint256[] calldata) external returns (uint256) {
        _toMarket();
    }

    function sellToBid(uint256, uint256[] calldata) external returns (uint256) {
        _syncVault();
        _toMarket();
    }

    function withdrawProceeds(address) external returns (uint256) {
        _toMarket();
    }

    /// @dev Split BNB already sitting in the vault. No-op before launch. Does not pull the tax processor.
    function _syncVault() private {
        if (vault == address(0)) return;
        IMintAIVault(vault).sync();
    }

    /// @dev Forwards the current call to the market logic deployed by the vault factory.
    function _toMarket() private {
        address logic = IMintAIFactory(factory).marketLogic();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let ok := delegatecall(gas(), logic, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch ok
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    // ---------------------------------------------------------------- views

    /// @notice Price of the `paidIndex`-th paid card (1-based).
    function priceOf(uint256 paidIndex) external pure returns (uint256) {
        return paidIndex <= FIRST_BATCH ? PRESALE_PRICE : MINT_PRICE;
    }

    function teamUnlocked() external view returns (uint256) {
        return paidMinted / UNLOCK_EVERY;
    }

    function presaleFailed() public view returns (bool) {
        return !launched && block.timestamp > presaleDeadline && paidMinted < FIRST_BATCH;
    }

    function pendingDividendOf(uint256 tokenId) external view returns (uint256) {
        if (_ownerOf(tokenId) == address(0)) return 0;
        uint256 acc = accRewardPerShare;
        uint256 weight = totalWeight;
        if (weight != 0) {
            uint256 streamed = _streamDue() + _sideDue();
            acc += (pendingDividend + streamed) * ACC / weight;
        }
        return (acc - rewardDebt[tokenId]) / ACC;
    }

    // ---------------------------------------------------------------- roles

    function setOpsWallet(address next) external onlyOwnerOrGuardian {
        if (next == address(0)) revert ZeroAddress();
        emit RoleUpdated("ops", opsWallet, next);
        opsWallet = next;
    }

    function setTeamWallet(address next) external onlyOwnerOrGuardian {
        if (next == address(0)) revert ZeroAddress();
        emit RoleUpdated("team", teamWallet, next);
        teamWallet = next;
    }

    function transferOwnership(address next) external onlyOwnerOrGuardian {
        if (next == address(0)) revert ZeroAddress();
        emit RoleUpdated("owner", owner, next);
        owner = next;
    }

    /// @notice Guardian may only take BNB nobody is owed (forced sends).
    function emergencyWithdrawNative(address to, uint256 amount) external nonReentrant {
        if (msg.sender != LaunchVaultAddresses.guardian()) revert NotGuardian();
        if (to == address(0)) revert ZeroAddress();
        uint256 bal = address(this).balance;
        uint256 free = bal > booked ? bal - booked : 0;
        if (amount > free) revert OccupiedFunds(free, amount);
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert PayFailed();
    }

    // ---------------------------------------------------------------- internals

    function _launchParams() private view returns (CreateTaxTokenParams memory p) {
        FeeConfig[] memory fees = new FeeConfig[](1);
        fees[0] = FeeConfig(FeeSlotType.VAULT, 10_000, abi.encode(FeeConfigVault(factory, "")));
        p.name = tokenName;
        p.symbol = tokenSymbol;
        p.meta = tokenMeta;
        p.totalSupply = P.TOTAL_SUPPLY;
        p.salt = salt;
        p.quoteToken = address(0);
        p.dexId = 0;
        p.poolQuote = P.POOL_QUOTE;
        p.poolToken = P.POOL_TOKEN;
        p.buyTaxRate = P.TAX_BPS;
        p.sellTaxRate = P.TAX_BPS;
        p.taxDuration = P.TAX_DURATION;
        p.antiFarmerDuration = 0;
        p.feeConfigs = fees;
        p.exemptAddrs = new address[](0);
        (bytes32 extensionID, bytes32 creatorWord) = _creatorExtension();
        p.extensionID = extensionID;
        bytes memory extensionData = new bytes(32);
        assembly {
            mstore(add(extensionData, 32), creatorWord)
        }
        p.extensionData = extensionData;
    }

    /// @notice Lowest non-empty price tick at or above `h`, or MAX_TICK when there is none. Start from floorHint
    ///         for the floor. At most 17 reads: the start word, then the 16 summary words.
    function nextTick(uint256 h) external view returns (uint256) {
        if (h >= MAX_TICK) return MAX_TICK;
        uint256 word = h >> 8;
        uint256 bits = tickBits[word] & (type(uint256).max << (h & 255));
        if (bits != 0) return (word << 8) | _lowBit(bits);
        if (++word >= MAX_TICK >> 8) return MAX_TICK;
        uint256 s = word >> 8;
        bits = tickWordBits[s] & (type(uint256).max << (word & 255));
        while (bits == 0) {
            if (++s >= MAX_TICK >> 16) return MAX_TICK;
            bits = tickWordBits[s];
        }
        word = (s << 8) | _lowBit(bits);
        return (word << 8) | _lowBit(tickBits[word]);
    }

    /// @dev JSON string escape for the two user-supplied feed fields.
    function _jsonEscape(string memory s) private pure returns (string memory) {
        bytes memory raw = bytes(s);
        uint256 extra;
        for (uint256 i; i < raw.length; ++i) {
            bytes1 c = raw[i];
            if (c == '"' || c == "\\" || c == "\n" || c == "\r" || c == "\t") extra += 1;
        }
        if (extra == 0) return s;
        bytes memory out = new bytes(raw.length + extra);
        uint256 j;
        for (uint256 i; i < raw.length; ++i) {
            bytes1 c = raw[i];
            if (c == '"') {
                out[j++] = "\\";
                out[j++] = '"';
            } else if (c == "\\") {
                out[j++] = "\\";
                out[j++] = "\\";
            } else if (c == "\n") {
                out[j++] = "\\";
                out[j++] = "n";
            } else if (c == "\r") {
                out[j++] = "\\";
                out[j++] = "r";
            } else if (c == "\t") {
                out[j++] = "\\";
                out[j++] = "t";
            } else {
                out[j++] = c;
            }
        }
        return string(out);
    }

    /// @dev Flap anti-scam module: reject a flagged token name or symbol.
    function _screen(string calldata name, string calldata symbol) private view {
        IMintAIFactory(factory).rejectScam(name, symbol);
    }

    function _creatorExtension() private view returns (bytes32 extensionID, bytes32 creatorWord) {
        (extensionID, creatorWord) = IMintAIFactory(factory).creatorExtension();
    }
}

