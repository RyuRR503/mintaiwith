// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {VaultUISchema, VaultMethodSchema, FieldDescriptor} from "flap/IVaultSchemasV1.sol";
import {DirectLaunchAccess, IDirectLaunchVault} from "./flap/DirectLaunchBases.sol";
import {IStrategy, ITokenDock} from "./flap/IDirectPoolLaunch.sol";
import {MintAIParams as P} from "./MintAIParams.sol";
import {IMintAICards, IMintAIDuel, IMintAIFactory, IFlapTriggerService, IV2Pair, IV2Router, ITaxProcessor} from "./MintAIInterfaces.sol";

/**
 * @title MintAIVault
 * @notice Pool Launch vault of MINT.AI. Created by MintAIVaultFactory inside the launch transaction.
 *
 * Reserve (653,105,777 tokens, held in the Token Dock)
 *   - 497,014,720 card grants: 8,440 per presale card (20,000) and per team card (38,888), vested by MintAICards.
 *   - 58,611,119 price-ladder tokens: 3 rungs sold at 1.5x / 2x / 3x the opening price,
 *     only while the 30-minute TWAP is at or above the rung. All proceeds stream to card holders over 7 days.
 *   - 97,479,938 unallocated. Burned to the dead address in the launch transaction, before the dock deposit.
 *   Only MintAICards can release grant tokens, and only within the grant bucket. Nobody can withdraw the reserve.
 *
 * Trading tax (100% of the tax revenue arrives here as BNB, after Flap's protocol fee)
 *   - 50% to card dividends and 20% to the ops wallet, forwarded to MintAICards.
 *   - 30% to the floor fund, held here. It first tops the trigger reserve up to 0.02 BNB; that reserve only
 *     pays the 30-minute floor sweep and the 0.00001 ask of a 6th-win burn. It does not pay duels and it
 *     does not refill the separate 0.1 BNB duel budget.
 *   - BNB already in the vault is split at the start of a dividend claim, a card purchase and a sale into
 *     a bid, and before a post-open mint creates its new cards. sync() and the floor sweep still split too.
 *     receive() stays empty so a tax payout cannot revert.
 *
 * Floor fund (run by the Flap Trigger every 30 minutes, or by anyone through sweepFloor)
 *   - Walks the card market from the lowest price up, buys every card it may and can afford at its ask,
 *     pays the seller the price plus the card's dividend so far, and the card is burned.
 *   - Presale cards and team cards: at most 0.00245 BNB. Their tokens are never touched.
 *   - Post-open paid cards: at most 0.0049 BNB, before and after sell-out. Unclaimed tokens of that card
 *     are burned even if the card was transferred. Tokens already claimed stay with the minter.
 *
 * Post-open mints
 *   - MintAICards sends 75% of every post-open card payment here. It is swapped for tokens on the pool;
 *     10% of the tokens received go to the dead address and 90% stay here and vest to the minter.
 *
 * Token vesting (linear over 5 days, per receiving address, claimed with claimTokens)
 *   - 8,440 reserve tokens per presale card: one fifth at the launch second, the rest over 5 days.
 *   - 8,440 reserve tokens per team card, on the same one-fifth-then-five-days schedule. A slot unlocked
 *     before launch starts at the launch second. A slot unlocked after launch starts at that unlock second.
 *   - 90% of the tokens bought by a post-open mint, from the mint, as one schedule per card.
 *     If the floor fund buys the card, that card's unclaimed tokens are burned.
 */
contract MintAIVault is Initializable, ReentrancyGuardUpgradeable, DirectLaunchAccess, IDirectLaunchVault, IStrategy {
    using SafeERC20 for IERC20;

    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant BPS = 10_000;
    uint256 public constant TWAP_PERIOD = 30 minutes;
    /// @dev A gap longer than an hour is not a 30-minute price. Both observations restart, and the rung stays closed until a new full window exists.
    uint256 public constant TWAP_STALE = 60 minutes;
    uint256 public constant LADDER_STREAM = 7 days;
    uint256 public constant VEST_PERIOD = 5 days;
    uint256 public constant TRIGGER_WATERLINE = 0.02 ether;
    /// @dev Separate from the floor-sweep reserve. Floor tax never refills it. Players pay the trigger
    ///      fee themselves once this is used up.
    uint256 public constant DUEL_BUDGET_CAP = 0.1 ether;
    /// @dev Earliest duel callback. The callback reads the previous block. Kept equal to MintAIDuel.TRIGGER_DELAY.
    uint256 public constant DUEL_TRIGGER_DELAY = 60;
    uint256 public constant TRIGGER_INTERVAL = 30 minutes;
    /// @dev A request still unanswered this long after it was due may be replaced.
    uint256 internal constant TRIGGER_STALE = 1 hours;
    /// @dev The sweep stops and keeps its place when less gas than this is left (Trigger gives 2,000,000).
    uint256 internal constant SWEEP_GAS_FLOOR = 400_000;
    /// @dev One claim or tokensOf page. A wallet with every team card must call again with a later `from`.
    uint256 internal constant TOKEN_PAGE = 500;
    uint256 internal constant MINT_PRICE = 0.0049 ether;
    uint256 internal constant PRESALE_PRICE = 0.00245 ether;
    uint256 internal constant PRICE_TICK = 0.00001 ether;
    uint256 internal constant MAX_TICK = 1 << 20;

    struct Observation {
        uint32 timestamp;
        uint224 cumulative;
    }

    /// @dev reserve: paid from the grant bucket in the Token Dock; otherwise from bought tokens held here.
    struct Vest {
        uint104 total;
        uint104 claimed;
        uint40 start;
        bool reserve;
    }

    struct CardVest {
        address minter;
        uint96 slot;
    }

    address public token;
    address public cards;
    address public factory;
    address public pair;
    address public router;
    address public wbnb;
    bool public tokenIsToken0;
    bool public distributed;

    uint256[2] public bucketReleased;
    uint256[3] public ladderSold;

    uint256 public totalTaxRevenue;
    uint256 public totalDividendForwarded;
    uint256 public totalFloorForwarded;
    uint256 public totalOpsForwarded;
    uint256 public totalMintBnb;
    uint256 public totalMintBought;
    uint256 public totalMintBurned;
    uint256 public totalLadderRevenue;

    Observation public obsOld;
    Observation public obsNew;

    uint256 public launchTime;
    /// @dev Bought tokens held here that are still owed to minters.
    uint256 public boughtOwed;
    mapping(address => Vest[]) public vests;
    mapping(address => uint256) public presaleClaimed;
    /// @dev Post-open card id => minter and its vest index + 1. One vest per card.
    mapping(uint256 => CardVest) public cardVest;
    uint256 public totalForfeitBurned;

    /// @dev BNB held here on purpose; everything above floorFund + triggerReserve is unrecognized tax.
    uint256 public floorFund;
    uint256 public triggerReserve;
    /// @dev BNB set aside for duel trigger fees. Not part of the floor fund and not refilled by tax.
    uint256 public duelBudget;
    /// @dev Cards owner at the moment the pool opened. Recorded for the launch receipt. It does not pay buyers.
    address public launcher;
    uint256 public pendingTriggerId;
    uint256 public triggerDueAt;
    uint256 public totalFloorSpent;
    uint256 public totalFloorBurned;
    /// @dev Where the last sweep stopped: list key (`tick << 1 | post`) and the next id in it. 0 = from the floor.
    uint256 public sweepKey;
    uint256 public sweepId;
    /// @dev Duel contract deployed with the factories. Set once in initialize.
    address public duel;
    /// @dev Ticks below this were already skipped as not buyable. A cheaper buyable listing still goes first.
    uint256 public sweepMark;
    /// @dev Minimum card ask. A 6th-win burn lists the card at this price and floorBuy burns it.
    uint256 internal constant DUEL_BURN_PRICE = 0.00001 ether;

    event Distributed(uint256 amount);
    event Released(uint8 indexed bucket, address indexed to, uint256 amount);
    event TaxRecognized(uint256 amount, uint256 dividend, uint256 ops, uint256 floor);
    event MintBuy(address indexed minter, uint256 bnbIn, uint256 tokensBought, uint256 tokensBurned);
    event VestAdded(address indexed to, uint256 index, uint256 amount, uint256 start, bool reserve);
    event TokensClaimed(address indexed to, uint256 fromReserve, uint256 fromBought);
    event LadderFilled(uint256 indexed rung, address indexed buyer, uint256 tokens, uint256 cost);
    event Forfeited(uint256 indexed tokenId, address indexed minter, uint256 amount);
    event FloorBought(uint256 indexed tokenId, uint256 price);
    event TriggerFunded(uint256 amount, uint256 reserve);
    event TriggerArmed(uint256 indexed requestId, uint256 executeAfter, uint256 fee);
    event TriggerSkipped(string reason);
    event DuelBudgetFunded(uint256 amount, uint256 budget);

    error NotCards();
    error NotTrigger();
    error UnknownTrigger();
    error WrongToken();
    error AlreadyDistributed();
    error BadDistribution(uint256 received);
    error NotLaunched();
    error AlreadyLaunched();
    error BucketExceeded(uint8 bucket, uint256 left, uint256 requested);
    error BadBucket();
    error BadRung();
    error RungNotReached(uint256 twapPrice, uint256 rungPrice);
    error TwapNotReady();
    error RungSoldOut(uint256 left);
    error WrongPayment(uint256 expected, uint256 sent);
    error PayFailed();
    error BadPair();
    error Slippage(uint256 received, uint256 minimum);
    error NothingToClaim();
    error NotDuel();
    error TriggerUnpaid();
    error BadPrice();
    error NotLauncher();

    modifier onlyCards() {
        if (msg.sender != cards) revert NotCards();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Called by the factory in the same call that deploys the proxy. `token_` has no code yet.
    function initialize(address token_, address cards_, address duel_) external initializer {
        __ReentrancyGuard_init();
        if (duel_ == address(0)) revert NotDuel();
        token = token_;
        cards = cards_;
        factory = msg.sender;
        duel = duel_;
    }

    function version() external pure returns (string memory) {
        return "MINT.AI";
    }

    /// @dev Tax payouts land here. Empty on purpose: a payout must not revert, and Flap's wake
    ///      call must not make an external call. Splitting is done by the actions that already
    ///      run on a user's gas, and by sync() / the floor sweep.
    receive() external payable {}

    // ---------------------------------------------------------------- launch hooks

    function initializeDistribution(address token_, uint256 amount, bytes calldata, bytes32)
        external
        override
        onlyHub
    {
        if (token_ != token) revert WrongToken();
        if (distributed) revert AlreadyDistributed();
        distributed = true;
        IERC20 t = IERC20(token_);
        uint256 before = t.balanceOf(address(this));
        t.safeTransferFrom(msg.sender, address(this), amount);
        uint256 got = t.balanceOf(address(this)) - before;
        if (got != P.RESERVE) revert BadDistribution(got);
        // Burn the unallocated remainder in this same transaction. The dock only holds grant and ladder tokens.
        t.safeTransfer(DEAD, P.UNALLOCATED);
        uint256 keep = P.GRANT_BUDGET + P.LADDER_BUDGET;
        if (t.balanceOf(address(this)) != before + keep) revert BadDistribution(t.balanceOf(address(this)));
        address dock = _getTokenDockRouter();
        t.forceApprove(dock, keep);
        ITokenDock(dock).deposit(token_, keep);
        emit FlapDistributionInitialized(token_, amount);
        emit Distributed(got);
    }

    /// @notice Called by MintAICards right after the launch transaction returns the pool.
    function onLaunched(address pair_, address router_, address launcher_) external onlyCards {
        if (pair != address(0)) revert AlreadyLaunched();
        address t0 = IV2Pair(pair_).token0();
        address t1 = IV2Pair(pair_).token1();
        address weth = IV2Router(router_).WETH();
        if (!((t0 == token && t1 == weth) || (t1 == token && t0 == weth))) revert BadPair();
        pair = pair_;
        router = router_;
        wbnb = weth;
        tokenIsToken0 = t0 == token;
        launchTime = block.timestamp;
        if (launcher_ == address(0)) revert NotLauncher();
        launcher = launcher_;
        uint224 cum = uint224(_cumulative());
        obsOld = Observation(uint32(block.timestamp), cum);
        obsNew = obsOld;
    }

    // ---------------------------------------------------------------- cards hooks

    /// @notice `count` grants of 8,440 to `to`. Each uses the presale schedule from launch, or from its own
    ///         unlock second when that unlock is later than launch.
    function addTeamGrants(address to, uint256 cursor, uint256 count) external onlyCards {
        for (uint256 i; i < count; ++i) {
            uint40 unlocked = IMintAICards(cards).teamUnlockAt(cursor + 1 + i);
            if (unlocked == 0) revert NotLaunched();
            uint40 start = unlocked < launchTime ? uint40(launchTime) : unlocked;
            _addVest(to, P.CARD_GRANT, true, start);
        }
    }

    /// @notice Swap the mint payment for tokens on the pool. 10% of the tokens go to dead; 90% stay here and
    ///         vest to `minter` over 5 days, one equal schedule per card `firstId .. firstId + count - 1`.
    ///         Reverts if fewer than `minTokens` would vest in total.
    function buyForMint(address minter, uint256 firstId, uint256 count, uint256 minTokens)
        external
        payable
        onlyCards
        nonReentrant
        returns (uint256 vested)
    {
        if (pair == address(0)) revert NotLaunched();
        IERC20 t = IERC20(token);
        uint256 before = t.balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = wbnb;
        path[1] = token;
        IV2Router(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0, path, address(this), block.timestamp
        );
        uint256 bought = t.balanceOf(address(this)) - before;
        uint256 burned = bought * P.MINT_BURN_BPS / BPS;
        if (burned != 0) t.safeTransfer(DEAD, burned);
        vested = bought - burned;
        if (vested < minTokens) revert Slippage(vested, minTokens);
        boughtOwed += vested;
        uint256 share = vested / count;
        for (uint256 i; i < count; ++i) {
            uint256 amount = i + 1 == count ? vested - share * i : share;
            cardVest[firstId + i] = CardVest(minter, uint96(vests[minter].length + 1));
            _addVest(minter, amount, false, uint40(block.timestamp));
        }
        totalMintBnb += msg.value;
        totalMintBought += bought;
        totalMintBurned += burned;
        emit MintBuy(minter, msg.value, bought, burned);
        // The mint payment has been swapped away. Any tax BNB that landed during the swap is split here.
        // Tax that was already waiting was split before these new cards were minted.
        _recognize();
        _poke();
        _arm();
    }

    /// @notice For card `id`: the highest ask the floor fund pays, and the still-locked tokens a floor sale burns.
    ///         Tokens already unlocked stay claimable by the address that held the card then. The address argument is unused.
    function floorLimit(uint256 id, address) external view returns (uint256 maxPrice, uint256 forfeit) {
        CardVest memory link = cardVest[id];
        if (link.slot == 0) return (PRESALE_PRICE, 0);
        maxPrice = MINT_PRICE;
        Vest memory v = vests[link.minter][link.slot - 1];
        uint256 released = _scheduleReleased(v);
        if (released < v.claimed) released = v.claimed;
        forfeit = v.total - released;
    }

    // ---------------------------------------------------------------- token vesting

    /// @notice Claim what has vested: the presale grant plus schedules `from` .. `from + count - 1`.
    ///         `count` 0 means the next 500 schedules, not the rest of a long array.
    function claimTokens(uint256 from, uint256 count) external nonReentrant returns (uint256 amount) {
        if (pair == address(0)) revert NotLaunched();
        uint256 fromReserve;
        uint256 fromBought;
        uint256 presale = IMintAICards(cards).presaleCards(msg.sender) * P.CARD_GRANT;
        if (presale != 0) {
            uint256 due = _presaleReleased(presale) - presaleClaimed[msg.sender];
            presaleClaimed[msg.sender] += due;
            fromReserve = due;
        }
        Vest[] storage vs = vests[msg.sender];
        uint256 end = vs.length;
        if (from > end) from = end;
        uint256 n = count == 0 || count > TOKEN_PAGE ? TOKEN_PAGE : count;
        if (end - from > n) end = from + n;
        for (uint256 i = from; i < end; ++i) {
            Vest storage v = vs[i];
            uint256 due = _scheduleReleased(v) - v.claimed;
            if (due == 0) continue;
            v.claimed += uint104(due);
            if (v.reserve) fromReserve += due;
            else fromBought += due;
        }
        amount = fromReserve + fromBought;
        if (amount == 0) revert NothingToClaim();
        if (fromReserve != 0) _release(P.BUCKET_GRANT, msg.sender, fromReserve);
        if (fromBought != 0) {
            boughtOwed -= fromBought;
            IERC20(token).safeTransfer(msg.sender, fromBought);
        }
        emit TokensClaimed(msg.sender, fromReserve, fromBought);
    }

    function vestCount(address who) external view returns (uint256) {
        return vests[who].length;
    }

    /// @notice First page of `who`. A wallet past 500 schedules must use `tokensOf(who, from, count)`.
    function tokensOf(address who)
        external
        view
        returns (uint256 total, uint256 claimed, uint256 claimable, uint256 locked)
    {
        return _tokensOf(who, 0, 0);
    }

    /// @notice One page of `who`'s schedules, starting at `from`. `count` 0 means 500.
    ///         The presale grant is included only when `from` is 0, so later pages do not count it again.
    function tokensOf(address who, uint256 from, uint256 count)
        external
        view
        returns (uint256 total, uint256 claimed, uint256 claimable, uint256 locked)
    {
        return _tokensOf(who, from, count);
    }

    function _tokensOf(address who, uint256 from, uint256 count)
        private
        view
        returns (uint256 total, uint256 claimed, uint256 claimable, uint256 locked)
    {
        uint256 done;
        if (from == 0) {
            total = IMintAICards(cards).presaleCards(who) * P.CARD_GRANT;
            claimed = presaleClaimed[who];
            done = _presaleReleased(total);
        }
        Vest[] storage vs = vests[who];
        uint256 end = vs.length;
        if (from > end) from = end;
        uint256 n = count == 0 || count > TOKEN_PAGE ? TOKEN_PAGE : count;
        if (end - from > n) end = from + n;
        for (uint256 i = from; i < end; ++i) {
            Vest memory v = vs[i];
            total += v.total;
            claimed += v.claimed;
            done += _scheduleReleased(v);
        }
        claimable = done - claimed;
        locked = total - done;
    }

    // ---------------------------------------------------------------- public keepers

    /// @notice Forward tax that arrived since the last sync: dividend, floor fund and ops shares.
    function sync() external nonReentrant {
        _recognize();
        _poke();
        _arm();
    }

    /// @notice Flap Trigger callback. The booked floor id sweeps the market. Any other id that belongs to a
    ///         duel settles that match. The duel calls back into this vault, so those paths are not guarded again.
    function trigger(uint256 requestId) external nonReentrant {
        if (msg.sender != _triggerService()) revert NotTrigger();
        if (requestId != 0 && requestId == pendingTriggerId) {
            pendingTriggerId = 0;
            _recognize();
            _sweep();
            _poke();
            _arm();
            return;
        }
        if (!IMintAIDuel(duel).onTrigger(requestId)) revert UnknownTrigger();
    }

    /// @notice Book a duel callback 60 seconds out. The 0.1 BNB budget pays the fee when it covers it.
    ///         Otherwise the duel forwards the fee paid by the two players. The floor reserve is not used.
    function armDuel() external payable nonReentrant returns (uint256 requestId) {
        if (msg.sender != duel) revert NotDuel();
        address svc = _triggerService();
        if (svc == address(0)) revert NotTrigger();
        uint256 fee = IFlapTriggerService(svc).getFee();
        if (fee == 0) revert TriggerUnpaid();
        if (duelBudget >= fee) {
            if (msg.value != 0) revert WrongPayment(0, msg.value);
            duelBudget -= fee;
        } else if (msg.value != fee) {
            revert WrongPayment(fee, msg.value);
        }
        uint64 when = uint64(block.timestamp + IMintAIDuel(duel).TRIGGER_DELAY());
        requestId = IFlapTriggerService(svc).requestTrigger{value: fee}(when);
        if (requestId == 0) revert TriggerUnpaid();
        emit TriggerArmed(requestId, when, fee);
    }

    /// @notice Current Flap Trigger fee. Zero when this chain has no trigger service.
    function duelFee() external view returns (uint256) {
        address svc = _triggerService();
        if (svc == address(0)) return 0;
        return IFlapTriggerService(svc).getFee();
    }

    /// @notice Add BNB to the duel budget, up to 0.1 BNB. Anything above the cap is returned.
    ///         Tax recognition never calls this.
    function fundDuelBudget() external payable nonReentrant {
        uint256 room = DUEL_BUDGET_CAP > duelBudget ? DUEL_BUDGET_CAP - duelBudget : 0;
        uint256 take = msg.value > room ? room : msg.value;
        duelBudget += take;
        uint256 back = msg.value - take;
        if (back != 0) {
            (bool ok,) = msg.sender.call{value: back}("");
            if (!ok) revert PayFailed();
        }
        emit DuelBudgetFunded(take, duelBudget);
    }

    /// @notice Burn a card the duel listed at the minimum ask. `floorBuy` pays that ask back to the duel,
    ///         which returns it through {repayDuelTick} in the same transaction.
    function burnDuelCard(uint256 id) external {
        if (msg.sender != duel) revert NotDuel();
        if (IERC721(cards).ownerOf(id) != duel) revert NotDuel();
        (address seller, uint96 price) = IMintAICards(cards).listings(id);
        if (seller != duel || price != DUEL_BURN_PRICE) revert BadPrice();
        if (triggerReserve < DUEL_BURN_PRICE) revert TriggerUnpaid();
        CardVest memory link = cardVest[id];
        triggerReserve -= DUEL_BURN_PRICE;
        IMintAICards(cards).floorBuy{value: DUEL_BURN_PRICE}(id);
        if (link.slot != 0) _forfeit(id, link.minter, link.slot);
    }

    /// @notice Duel-only return of the burn ask into the trigger reserve.
    function repayDuelTick() external payable {
        if (msg.sender != duel) revert NotDuel();
        if (msg.value != DUEL_BURN_PRICE) revert WrongPayment(DUEL_BURN_PRICE, msg.value);
        triggerReserve += msg.value;
    }

    /// @notice Same work as the trigger, paid by the caller. Stops when gas runs low and keeps its place.
    function sweepFloor() external nonReentrant returns (uint256 bought) {
        _recognize();
        bought = _sweep();
        _poke();
        _arm();
    }

    /// @notice Add BNB to the trigger reserve. It only pays Flap Trigger fees.
    function fundTrigger() external payable nonReentrant {
        triggerReserve += msg.value;
        emit TriggerFunded(msg.value, triggerReserve);
        _arm();
    }

    /// @notice Ask the tax processor to pay out, then sync. A failed dispatch does not block the sync.
    function dispatchAndSync() external nonReentrant {
        if (pair != address(0)) {
            (bool ok, bytes memory ret) = token.staticcall(abi.encodeWithSignature("taxProcessor()"));
            if (ok && ret.length >= 32) {
                address proc = abi.decode(ret, (address));
                try ITaxProcessor(proc).dispatch() {} catch {}
            }
        }
        _recognize();
        _poke();
        _arm();
    }

    /// @notice Refresh the TWAP observation. Anyone may call; it is also refreshed by sync / mints / ladder.
    function poke() external {
        _poke();
    }

    /// @notice Buy `amount` ladder tokens of `rung` at the rung price. The rung opens only while the
    ///         30-minute TWAP is at or above it. Proceeds stream to card holders over 7 days.
    function buyLadder(uint256 rung, uint256 amount) external payable nonReentrant returns (uint256 cost) {
        if (pair == address(0)) revert NotLaunched();
        if (rung >= P.LADDER_RUNGS || amount == 0) revert BadRung();
        uint256 left = P.ladderRungTokens(rung) - ladderSold[rung];
        if (amount > left) revert RungSoldOut(left);
        uint256 price = rungPrice(rung);
        _poke();
        uint256 twap = twapPrice();
        if (twap < price) revert RungNotReached(twap, price);
        cost = (amount * price + 1e18 - 1) / 1e18;
        if (msg.value < cost) revert WrongPayment(cost, msg.value);
        ladderSold[rung] += amount;
        totalLadderRevenue += cost;
        _release(P.BUCKET_LADDER, msg.sender, amount);
        IMintAICards(cards).onVaultRevenue{value: cost}(0, cost, 0);
        if (msg.value > cost) {
            (bool ok,) = msg.sender.call{value: msg.value - cost}("");
            if (!ok) revert PayFailed();
        }
        emit LadderFilled(rung, msg.sender, amount, cost);
        _poke();
    }

    // ---------------------------------------------------------------- views

    function bucketLeft(uint8 bucket) public view returns (uint256) {
        return _budget(bucket) - bucketReleased[bucket];
    }

    function rungPrice(uint256 rung) public pure returns (uint256) {
        (uint256 num, uint256 den) = P.ladderMultiple(rung);
        return P.POOL_QUOTE * 1e18 * num / (P.POOL_TOKEN * den);
    }

    /// @notice BNB wei per 1e18 token wei, averaged since the older observation (at least 30 minutes).
    function twapPrice() public view returns (uint256) {
        Observation memory o = obsOld;
        uint256 elapsed = block.timestamp - o.timestamp;
        if (elapsed < TWAP_PERIOD) {
            o = obsNew;
            elapsed = block.timestamp - o.timestamp;
        }
        if (o.timestamp == 0 || elapsed < TWAP_PERIOD || elapsed > TWAP_STALE) revert TwapNotReady();
        uint256 avg;
        unchecked {
            avg = (_cumulative() - o.cumulative) / elapsed;
        }
        return (avg * 1e18) >> 112;
    }

    function spotPrice() public view returns (uint256) {
        (uint256 q, uint256 t) = _reserves();
        return q * 1e18 / t;
    }

    /// @notice BNB waiting for sync(): the balance above the floor fund, the trigger reserve and the duel budget.
    function unrecognizedTax() public view returns (uint256) {
        uint256 held = floorFund + triggerReserve + duelBudget;
        uint256 bal = address(this).balance;
        return bal > held ? bal - held : 0;
    }

    function triggerService() external view returns (address) {
        return _triggerService();
    }

    function description() public pure override returns (string memory) {
        return "Presale: 20,000 cards at 0.00245 BNB. Unsold after 7 days can be fully refunded. After launch, "
            "0.0049 BNB per card. 25% of each mint payment goes to operations. Each presale card and team card "
            "receives 8,440 tokens. The 2% tax splits 50% to holders, 30% to the floor, and 20% to operations. "
            "Market fee is 1%.";
    }

    function vaultUISchema() public pure override returns (VaultUISchema memory schema) {
        schema.vaultType = "MINT.AI";
        schema.description = "";
        schema.methods = new VaultMethodSchema[](10);
        schema.methods[0].name = "dispatchAndSync";
        schema.methods[0].isWriteMethod = true;
        schema.methods[1].name = "buyLadder";
        schema.methods[1].inputs = new FieldDescriptor[](3);
        schema.methods[1].inputs[0] = FieldDescriptor("rung", "uint256", "", 0);
        schema.methods[1].inputs[1] = FieldDescriptor("amount", "uint256", "", 18);
        schema.methods[1].inputs[2] = FieldDescriptor("value", "msg.value", "", 18);
        schema.methods[1].isWriteMethod = true;
        schema.methods[2].name = "twapPrice";
        schema.methods[2].outputs = new FieldDescriptor[](1);
        schema.methods[2].outputs[0] = FieldDescriptor("price", "uint256", "", 18);
        schema.methods[3].name = "claimTokens";
        schema.methods[3].inputs = new FieldDescriptor[](2);
        schema.methods[3].inputs[0] = FieldDescriptor("from", "uint256", "", 0);
        schema.methods[3].inputs[1] = FieldDescriptor("count", "uint256", "", 0);
        schema.methods[3].isWriteMethod = true;
        _fillPagedMethods(schema.methods);
    }

    function _fillPagedMethods(VaultMethodSchema[] memory methods) private pure {
        methods[4].name = "tokensOf";
        methods[4].inputs = new FieldDescriptor[](3);
        methods[4].inputs[0] = FieldDescriptor("who", "address", "", 0);
        methods[4].inputs[1] = FieldDescriptor("from", "uint256", "", 0);
        methods[4].inputs[2] = FieldDescriptor("count", "uint256", "", 0);
        methods[5].name = "floorLimit";
        methods[5].inputs = new FieldDescriptor[](1);
        methods[5].inputs[0] = FieldDescriptor("id", "uint256", "", 0);
        methods[6].name = "sweepFloor";
        methods[6].isWriteMethod = true;
        methods[7].name = "sync";
        methods[7].isWriteMethod = true;
        methods[8].name = "fundDuelBudget";
        methods[8].isWriteMethod = true;
        methods[9].name = "fundTrigger";
        methods[9].isWriteMethod = true;
    }

    // ---------------------------------------------------------------- internals

    function _recognize() private {
        uint256 fresh = unrecognizedTax();
        if (fresh == 0 || pair == address(0)) return;
        uint256 toFloor = fresh * P.FLOOR_BPS / BPS;
        uint256 toOps = fresh * P.OPS_BPS / BPS;
        uint256 toDividend = fresh - toFloor - toOps;
        totalTaxRevenue += fresh;
        totalDividendForwarded += toDividend;
        totalFloorForwarded += toFloor;
        totalOpsForwarded += toOps;
        uint256 reserve = triggerReserve;
        uint256 toFund = toFloor;
        if (reserve < TRIGGER_WATERLINE) {
            uint256 top = TRIGGER_WATERLINE - reserve;
            if (top > toFund) top = toFund;
            triggerReserve = reserve + top;
            toFund -= top;
            emit TriggerFunded(top, reserve + top);
        }
        floorFund += toFund;
        IMintAICards(cards).onVaultRevenue{value: toDividend + toOps}(toDividend, 0, toOps);
        emit TaxRecognized(fresh, toDividend, toOps, toFloor);
    }

    /// @dev Spend the floor fund from the cheapest listing up. Per price tick, presale and team cards first, then
    ///      post-open cards. A price above that card's cap is skipped, and {sweepMark} remembers that skip so the
    ///      next call does not walk those prices again. The cheapest buyable tick still goes before the saved card.
    ///      A seller callback that unlinks the saved successor restarts the same tick from its head. Ends when the
    ///      next price is above the fund or above 0.0049, or keeps its place when gas runs low.
    function _sweep() private returns (uint256 bought) {
        if (pair == address(0)) return 0;
        IMintAICards c = IMintAICards(cards);
        uint256 fund = floorFund;
        uint256 key = sweepKey;
        uint256 id = sweepId;
        if (id != 0) {
            (address s, uint96 p) = c.listings(id);
            if (s == address(0) || p / PRICE_TICK != key >> 1) key = 0;
        }
        uint256 hint = c.floorHint();
        uint256 leftTick = sweepMark;
        if (leftTick < hint) leftTick = hint;
        uint256 first = c.nextTick(hint);
        if (first < leftTick && first < MAX_TICK) {
            uint256 firstPrice = first * PRICE_TICK;
            uint256 firstPre = c.tickHead(first << 1);
            uint256 firstPost = c.tickHead((first << 1) | 1);
            bool firstPreOk = firstPre != 0 && firstPrice <= PRESALE_PRICE;
            bool firstPostOk = firstPost != 0 && firstPrice <= MINT_PRICE;
            if (firstPreOk || firstPostOk) {
                key = 0;
                leftTick = first;
            }
        }
        if (key == 0) {
            key = c.nextTick(leftTick) << 1;
            id = key >> 1 < MAX_TICK ? c.tickHead(key) : 0;
        }
        uint256 spent;
        bool finished;
        while (true) {
            uint256 cheapest = c.nextTick(leftTick);
            if (cheapest < (key >> 1)) {
                uint256 cheapPrice = cheapest * PRICE_TICK;
                uint256 pre = cheapest < MAX_TICK ? c.tickHead(cheapest << 1) : 0;
                uint256 postHead = cheapest < MAX_TICK ? c.tickHead((cheapest << 1) | 1) : 0;
                bool preOk = pre != 0 && cheapPrice <= PRESALE_PRICE;
                bool postOk = postHead != 0 && cheapPrice <= MINT_PRICE;
                if (preOk || postOk) {
                    key = cheapest << 1;
                    id = preOk ? pre : postHead;
                    if (!preOk) key |= 1;
                } else if (cheapest >= MAX_TICK) {
                    (key, id) = (0, 0);
                    finished = true;
                    break;
                } else {
                    leftTick = cheapest + 1;
                    if (gasleft() < SWEEP_GAS_FLOOR) break;
                    continue;
                }
            }
            uint256 tick = key >> 1;
            uint256 price = tick * PRICE_TICK;
            if (tick >= MAX_TICK || price > fund || price > MINT_PRICE) {
                (key, id) = (0, 0);
                finished = true;
                break;
            }
            if (gasleft() < SWEEP_GAS_FLOOR) break;
            bool post = key & 1 == 1;
            if (id == 0 || (!post && price > PRESALE_PRICE)) {
                if (post) leftTick = tick + 1;
                key = post ? c.nextTick(tick + 1) << 1 : key | 1;
                id = key >> 1 < MAX_TICK ? c.tickHead(key) : 0;
                continue;
            }
            uint256 next = c.nextListed(id);
            CardVest memory link;
            if (post) link = cardVest[id];
            bool filled;
            try c.floorBuy{value: price}(id) {
                filled = true;
                fund -= price;
                spent += price;
                ++bought;
                emit FloorBought(id, price);
                if (link.slot != 0) _forfeit(id, link.minter, link.slot);
            } catch {}
            if (filled && next != 0) {
                (address seller,) = c.listings(next);
                id = seller == address(0) ? (key >> 1 < MAX_TICK ? c.tickHead(key) : 0) : next;
            } else {
                id = next;
            }
        }
        (sweepKey, sweepId) = (key, id);
        sweepMark = finished ? hint : leftTick;
        if (spent != 0) {
            floorFund = fund;
            totalFloorSpent += spent;
            totalFloorBurned += bought;
        }
    }

    /// @dev Burn the still-locked bought tokens of card `id`. Tokens already vested stay with `minter`.
    ///      A vest parked on the duel has nobody to claim it, so the whole remainder burns with the card.
    function _forfeit(uint256 id, address minter, uint256 slot) private {
        Vest storage v = vests[minter][slot - 1];
        uint256 locked;
        if (minter == duel) {
            locked = uint256(v.total) - v.claimed;
            v.claimed = v.total;
            v.start = type(uint40).max;
        } else {
            uint256 released = _scheduleReleased(v);
            if (released < v.claimed) released = v.claimed;
            locked = v.total - released;
            v.total = uint104(released);
            v.start = type(uint40).max;
        }
        delete cardVest[id];
        if (locked != 0) {
            boughtOwed -= locked;
            totalForfeitBurned += locked;
            IERC20(token).safeTransfer(DEAD, locked);
            emit Forfeited(id, minter, locked);
        }
    }

    /// @dev A plain transfer. Already-unlocked tokens stay with the current holder. The locked remainder
    ///      follows the card and finishes at the original end. Presale and team grants have no card link.
    ///      The duel cannot claim, so a card leaving it takes the whole remaining schedule.
    function moveCardVest(address to, uint256 id) external onlyCards {
        if (to == address(0)) return;
        CardVest memory link = cardVest[id];
        if (link.slot == 0 || to == link.minter) return;
        Vest storage old = vests[link.minter][link.slot - 1];
        if (link.minter == duel) {
            cardVest[id] = CardVest(to, uint96(vests[to].length + 1));
            vests[to].push(old);
            old.total = 0;
            old.claimed = 0;
            old.start = type(uint40).max;
            return;
        }
        uint256 released = _scheduleReleased(old);
        if (released < old.claimed) released = old.claimed;
        uint256 locked = uint256(old.total) - released;
        uint40 start0 = old.start;
        old.total = uint104(released);
        old.start = type(uint40).max;
        if (locked == 0) return;
        uint256 elapsed = block.timestamp > start0 ? block.timestamp - uint256(start0) : 0;
        uint256 credit = locked * elapsed / (VEST_PERIOD - elapsed);
        cardVest[id] = CardVest(to, uint96(vests[to].length + 1));
        vests[to].push(Vest(uint104(locked + credit), uint104(credit), start0, false));
    }

    /// @dev Book the next Flap Trigger run, paid from the trigger reserve. A request is replaced only once it is
    ///      TRIGGER_STALE past due. Never reverts.
    function _arm() private {
        if (pair == address(0)) return;
        if (pendingTriggerId != 0 && block.timestamp < triggerDueAt + TRIGGER_STALE) return;
        address svc = _triggerService();
        if (svc == address(0)) return;
        uint256 fee;
        try IFlapTriggerService(svc).getFee() returns (uint256 f) {
            fee = f;
        } catch {
            emit TriggerSkipped("fee");
            return;
        }
        if (fee > triggerReserve) {
            emit TriggerSkipped("reserve");
            return;
        }
        uint256 when = block.timestamp + TRIGGER_INTERVAL;
        try IFlapTriggerService(svc).requestTrigger{value: fee}(uint64(when)) returns (uint256 requestId) {
            // The fee has already left. Count it even when the service returns no request id.
            triggerReserve -= fee;
            if (requestId == 0) {
                emit TriggerSkipped("id");
                return;
            }
            pendingTriggerId = requestId;
            triggerDueAt = when;
            emit TriggerArmed(requestId, when, fee);
        } catch {
            emit TriggerSkipped("request");
        }
    }

    function _triggerService() private view returns (address) {
        if (block.chainid == 56) return 0xcf4EE25035CF883895110f367F5BA8172416a7F9;
        if (block.chainid == 97) return 0x560E9830926C9e0EB98a59c6b9902383Fc0D9Eb2;
        return address(0);
    }

    function _addVest(address to, uint256 amount, bool reserve, uint40 start) private {
        Vest[] storage vs = vests[to];
        emit VestAdded(to, vs.length, amount, start, reserve);
        vs.push(Vest(uint104(amount), 0, start, reserve));
    }

    /// @dev Presale grants only. One fifth is released at the launch second. The other four fifths
    ///      vest linearly over 5 days from that same second.
    function _presaleReleased(uint256 total) private view returns (uint256) {
        if (total == 0 || pair == address(0)) return 0;
        return _grantReleased(total, launchTime);
    }

    /// @dev Team grants use the presale shape. Bought-token schedules stay a straight five-day line.
    ///      `start == type(uint40).max` means the locked part was forfeited and what remains is already released.
    function _scheduleReleased(Vest memory v) private view returns (uint256) {
        if (v.start == type(uint40).max) return v.total;
        if (v.reserve) return _grantReleased(v.total, v.start);
        return _vested(v.total, v.start);
    }

    /// @dev One fifth at `start`, the other four fifths linear over 5 days from that same second.
    function _grantReleased(uint256 total, uint256 start) private view returns (uint256) {
        if (total == 0 || block.timestamp < start) return 0;
        uint256 upfront = total / 5;
        return upfront + _vested(total - upfront, start);
    }

    function _vested(uint256 total, uint256 start) private view returns (uint256) {
        if (block.timestamp <= start) return 0;
        uint256 dt = block.timestamp - start;
        return dt >= VEST_PERIOD ? total : total * dt / VEST_PERIOD;
    }

    function _release(uint8 bucket, address to, uint256 amount) private {
        if (amount == 0) return;
        uint256 left = bucketLeft(bucket);
        if (amount > left) revert BucketExceeded(bucket, left, amount);
        bucketReleased[bucket] += amount;
        ITokenDock(_getTokenDockRouter()).withdraw(token, amount, to);
        emit Released(bucket, to, amount);
    }

    function _budget(uint8 bucket) private pure returns (uint256) {
        if (bucket == P.BUCKET_GRANT) return P.GRANT_BUDGET;
        if (bucket == P.BUCKET_LADDER) return P.LADDER_BUDGET;
        revert BadBucket();
    }

    function _poke() private {
        if (pair == address(0)) return;
        uint256 age = block.timestamp - obsNew.timestamp;
        if (age < TWAP_PERIOD) return;
        uint224 cum = uint224(_cumulative());
        if (age > TWAP_STALE) {
            obsOld = Observation(uint32(block.timestamp), cum);
            obsNew = obsOld;
            return;
        }
        obsOld = obsNew;
        obsNew = Observation(uint32(block.timestamp), cum);
    }

    /// @dev Pool's quote-per-token cumulative price (UQ112x112 * seconds), extrapolated to now.
    function _cumulative() private view returns (uint256 cum) {
        (uint112 r0, uint112 r1, uint32 last) = IV2Pair(pair).getReserves();
        cum = tokenIsToken0 ? IV2Pair(pair).price0CumulativeLast() : IV2Pair(pair).price1CumulativeLast();
        uint32 nowTs = uint32(block.timestamp);
        if (last != nowTs && r0 != 0 && r1 != 0) {
            unchecked {
                uint32 dt = nowTs - last;
                cum += tokenIsToken0 ? ((uint256(r1) << 112) / r0) * dt : ((uint256(r0) << 112) / r1) * dt;
            }
        }
    }

    function _reserves() private view returns (uint256 quote, uint256 tok) {
        (uint112 r0, uint112 r1,) = IV2Pair(pair).getReserves();
        (quote, tok) = tokenIsToken0 ? (uint256(r1), uint256(r0)) : (uint256(r0), uint256(r1));
    }
}
