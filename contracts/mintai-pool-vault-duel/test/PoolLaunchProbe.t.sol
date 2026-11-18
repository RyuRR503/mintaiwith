// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {VaultDataSchema, VaultUISchema, FactoryPolicy} from "flap/IVaultSchemasV1.sol";
import {
    FeeSlotType,
    FeeConfig,
    FeeConfigVault,
    CreateTaxTokenParams,
    DistributionTarget,
    Distribution,
    CreatorBuyParams,
    LaunchTokenState,
    GraduationFloorParams,
    GraduationFloorResultV2,
    IDirectLaunchPortal,
    IStrategy,
    ITokenDock
} from "../src/flap/IDirectPoolLaunch.sol";

address constant HUB = 0x000042108465206185A077Edc3F3fd2b49060000;
address constant TOKEN_IMPL = 0x7777c57ff7dc441c1715b2e36fa581c48B782222;
address constant DOCK = 0x000048E888aBf09f690a952E1b386b2D031a0000;
address constant DEAD = 0x000000000000000000000000000000000000dEaD;

uint256 constant SUPPLY = 777_777_777 ether;
uint256 constant POOL_TOKEN = 124_672_000 ether;
uint256 constant POOL_QUOTE = 39.2 ether;
uint16 constant TAX_BPS = 300;

interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IPair {
    function getReserves() external view returns (uint112, uint112, uint32);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function factory() external view returns (address);
    function sync() external;
}

interface IRouter {
    function factory() external view returns (address);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract ProbeVault is IStrategy {
    address public immutable token;
    address public immutable creator;
    bool public distributed;
    bool public dockUsed;
    uint256 public pulled;
    uint256 public bnbReceived;
    bytes public dockError;

    constructor(address token_, address creator_) {
        token = token_;
        creator = creator_;
    }

    receive() external payable {
        bnbReceived += msg.value;
    }

    function initializeDistribution(address t, uint256 amount, bytes calldata, bytes32) external override {
        require(msg.sender == HUB, "hub");
        require(t == token, "token");
        require(!distributed, "once");
        distributed = true;
        uint256 before = IERC20(t).balanceOf(address(this));
        IERC20(t).transferFrom(msg.sender, address(this), amount);
        pulled = IERC20(t).balanceOf(address(this)) - before;
        IERC20(t).approve(DOCK, pulled);
        try ITokenDock(DOCK).deposit(t, pulled) {
            dockUsed = true;
        } catch (bytes memory err) {
            dockError = err;
            IERC20(t).approve(DOCK, 0);
        }
        emit FlapDistributionInitialized(t, amount);
    }

    function release(address to, uint256 amount) external {
        require(msg.sender == creator, "creator");
        if (dockUsed) ITokenDock(DOCK).withdraw(token, amount, to);
        else IERC20(token).transfer(to, amount);
    }

    function donate(address pair, address wbnb) external payable {
        IWBNB(wbnb).deposit{value: msg.value}();
        IWBNB(wbnb).transfer(pair, msg.value);
        IPair(pair).sync();
    }

    function description() external pure returns (string memory) {
        return "probe";
    }

    function vaultUISchema() external pure returns (VaultUISchema memory s) {
        s.vaultType = "probe";
    }
}

contract ProbeFactory {
    address public immutable expectedCreator;
    address public lastVault;
    address public lastToken;

    constructor(address creator_) {
        expectedCreator = creator_;
    }

    function newVault(address token, address creator, uint8 launchKind, bytes calldata launchParams)
        external
        returns (address vault)
    {
        require(msg.sender == HUB, "not hub");
        require(launchKind == 0, "kind");
        require(creator == expectedCreator, "creator");
        (CreateTaxTokenParams memory p, Distribution memory d) =
            abi.decode(launchParams, (CreateTaxTokenParams, Distribution));
        require(p.totalSupply == SUPPLY && p.poolToken == POOL_TOKEN && p.poolQuote == POOL_QUOTE, "amounts");
        require(p.quoteToken == address(0) && p.creatorBuyQuote == 0, "quote");
        require(p.buyTaxRate == TAX_BPS && p.sellTaxRate == TAX_BPS, "tax");
        require(d.target == DistributionTarget.VAULT && d.amount == SUPPLY - POOL_TOKEN, "distribution");
        bool vaultSlot;
        bool burnSlot;
        for (uint256 i; i < p.feeConfigs.length; ++i) {
            FeeConfig memory f = p.feeConfigs[i];
            if (f.feeType == FeeSlotType.VAULT) {
                FeeConfigVault memory v = abi.decode(f.configData, (FeeConfigVault));
                vaultSlot = v.vaultFactory == address(this) && f.bps == 8000;
            } else if (f.feeType == FeeSlotType.DEFLATION) {
                burnSlot = f.bps == 2000;
            } else {
                revert("slot");
            }
        }
        require(vaultSlot && burnSlot && p.feeConfigs.length == 2, "slots");
        vault = address(new ProbeVault{salt: bytes32(uint256(uint160(token)))}(token, creator));
        lastVault = vault;
        lastToken = token;
    }

    function isQuoteTokenSupported(address quoteToken) external pure returns (bool) {
        return quoteToken == address(0);
    }

    function factorySpecVersion() external pure returns (string memory) {
        return "pl-v1";
    }

    function vaultDataSchema() external pure returns (VaultDataSchema memory s) {
        s.description = "probe";
    }

    function tokenCreationPolicies() external pure returns (FactoryPolicy[] memory p) {
        p = new FactoryPolicy[](0);
    }

    function upgradeVaultImplementation(address) external pure {
        revert("immutable");
    }
}

/// @dev BSC mainnet fork against the real Direct Launch Portal.
contract PoolLaunchProbeTest is Test {
    bytes4 internal constant VANITY_ERR = bytes4(keccak256("VanityAddressRequirementNotMet(address)"));
    bytes4 internal constant TAX_TOO_LONG = bytes4(keccak256("TaxDurationTooLong()"));
    bytes4 internal constant TAX_TOO_SHORT = bytes4(keccak256("TaxDurationTooShort()"));

    IDirectLaunchPortal internal portal = IDirectLaunchPortal(HUB);
    ProbeFactory internal factory;
    ProbeVault internal vault;
    address internal token;
    address internal pair;
    uint32 internal taxDuration;
    uint256 internal nextSaltIndex;
    address internal alice = makeAddr("alice");
    address internal WBNB;
    address internal ROUTER;

    receive() external payable {}

    function setUp() public {
        vm.createSelectFork(_rpc());
        if (block.chainid == 56) {
            WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
            ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        } else if (block.chainid == 97) {
            WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
            ROUTER = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
        } else {
            revert("bsc 56/97 fork required");
        }
        factory = new ProbeFactory(address(this));
        vm.deal(address(this), 10_000 ether);

        bytes32 salt = _mineSalt();
        uint32[13] memory candidates = [
            uint32(100 * 365 days),
            uint32(50 * 365 days),
            uint32(20 * 365 days),
            uint32(10 * 365 days),
            uint32(5 * 365 days),
            uint32(3 * 365 days),
            uint32(2 * 365 days),
            uint32(365 days),
            uint32(180 days),
            uint32(90 days),
            uint32(30 days),
            uint32(7 days),
            uint32(1 days)
        ];
        for (uint256 i; i < candidates.length; ++i) {
            (bool ok, bytes memory ret) = _launch(salt, candidates[i]);
            if (ok) {
                (token, pair) = abi.decode(ret, (address, address));
                taxDuration = candidates[i];
                break;
            }
            console2.log("taxDuration rejected (days):", candidates[i] / 1 days);
            console2.logBytes(ret);
        }
        require(token != address(0), "no taxDuration accepted");
        vault = ProbeVault(payable(factory.lastVault()));
        console2.log("taxDuration accepted (days):", taxDuration / 1 days);
        address quoteSide = IPair(pair).token0() == token ? IPair(pair).token1() : IPair(pair).token0();
        if (quoteSide != WBNB) console2.log("pool quote side differs from WBNB:", quoteSide);
        WBNB = quoteSide;
        if (IPair(pair).factory() != IRouter(ROUTER).factory()) {
            console2.log("router factory mismatch; pair factory:", IPair(pair).factory());
        }
    }

    function test_01_launchShape() public view {
        (address v, address f) = portal.getLaunchVault(token);
        assertEq(v, address(vault), "provenance vault");
        assertEq(f, address(factory), "provenance factory");
        assertEq(uint16(uint160(token)), 0x7777, "vanity");
        assertEq(IERC20(token).totalSupply(), SUPPLY, "supply");

        LaunchTokenState memory s = portal.getLaunchToken(token);
        console2.log("status", s.status);
        console2.log("pendingRemainder", s.pendingRemainder);
        console2.log("pool", s.pool);
        assertEq(s.pool, pair, "pool");

        (uint112 r0, uint112 r1,) = IPair(pair).getReserves();
        (uint256 rq, uint256 rt) = IPair(pair).token0() == WBNB ? (uint256(r0), uint256(r1)) : (uint256(r1), uint256(r0));
        console2.log("pool BNB", rq);
        console2.log("pool token", rt);
        assertEq(rq, POOL_QUOTE, "pool quote");
        assertEq(rt, POOL_TOKEN, "pool token");

        console2.log("vault pulled", vault.pulled());
        console2.log("dock used", vault.dockUsed());
        if (!vault.dockUsed()) console2.logBytes(vault.dockError());
        assertEq(vault.pulled(), SUPPLY - POOL_TOKEN, "remainder pulled without tax");
        if (vault.dockUsed()) {
            assertEq(ITokenDock(DOCK).balanceOf(token, address(vault)), SUPPLY - POOL_TOKEN, "dock balance");
        }
    }

    function test_02_releaseIsTaxFree() public {
        vault.release(alice, 7_792 ether);
        assertEq(IERC20(token).balanceOf(alice), 7_792 ether, "release taxed");
        vm.prank(alice);
        IERC20(token).transfer(makeAddr("bob"), 1_000 ether);
        assertEq(IERC20(token).balanceOf(makeAddr("bob")), 1_000 ether, "wallet transfer taxed");
    }

    function test_03_donateSync() public {
        (uint256 q0, uint256 t0) = _reserves();
        vault.donate{value: 0.3136 ether}(pair, WBNB);
        (uint256 q1, uint256 t1) = _reserves();
        assertEq(q1, q0 + 0.3136 ether, "quote reserve");
        assertEq(t1, t0, "token reserve");
        console2.log("price x1e18 before", q0 * 1e18 / t0);
        console2.log("price x1e18 after ", q1 * 1e18 / t1);
    }

    function test_04_taxFlow() public {
        address trader = makeAddr("trader");
        vm.deal(trader, 1_000 ether);
        uint256 deadBefore = IERC20(token).balanceOf(DEAD);
        uint256 expectedOut;
        uint256 actualOut;
        uint256 sold;
        for (uint256 i; i < 25; ++i) {
            (uint256 e, uint256 a) = _buy(trader, 2 ether);
            expectedOut += e;
            actualOut += a;
            uint256 bal = IERC20(token).balanceOf(trader);
            sold += bal;
            _sell(trader, bal);
        }
        uint256 buyTaxTokens = expectedOut - actualOut;
        uint256 sellTaxTokens = sold * TAX_BPS / 10_000;
        (uint256 q, uint256 t) = _reserves();
        uint256 taxValue = (buyTaxTokens + sellTaxTokens) * q / t;
        console2.log("buy received / no-tax quote (bps)", actualOut * 10_000 / expectedOut);
        console2.log("approx tax value BNB (1e18)", taxValue);
        console2.log("vault BNB received", vault.bnbReceived());
        console2.log("dead delta tokens", IERC20(token).balanceOf(DEAD) - deadBefore);
        console2.log("token held by token contract", IERC20(token).balanceOf(token));
        (bool ok, bytes memory ret) = token.staticcall(abi.encodeWithSignature("taxProcessor()"));
        if (ok) {
            address proc = abi.decode(ret, (address));
            console2.log("taxProcessor", proc);
            console2.log("token held by processor", IERC20(token).balanceOf(proc));
            console2.log("BNB held by processor", proc.balance);
        }
        if (vault.bnbReceived() > 0) {
            console2.log("vault share of tax value (bps)", vault.bnbReceived() * 10_000 / taxValue);
        }
    }

    function test_05_taxExpires() public {
        address trader = makeAddr("trader");
        vm.deal(trader, 10 ether);
        (uint256 e0, uint256 a0) = _buy(trader, 1 ether);
        console2.log("during tax: received bps", a0 * 10_000 / e0);
        _logState("during");
        vm.warp(block.timestamp + uint256(taxDuration) + 1);
        (uint256 e1, uint256 a1) = _buy(trader, 1 ether);
        console2.log("after expiry: received bps", a1 * 10_000 / e1);
        _logState("after");
    }

    function test_06_exactMaxTaxDuration() public {
        bytes32 salt = _mineSalt();
        uint256 lo = taxDuration;
        uint256 hi = type(uint32).max;
        (bool okMax,) = _tryLaunch(salt, uint32(hi));
        if (okMax) {
            console2.log("uint32 max accepted (days):", hi / 1 days);
            return;
        }
        while (hi - lo > 1) {
            uint256 mid = (lo + hi) / 2;
            (bool ok,) = _tryLaunch(salt, uint32(mid));
            if (ok) lo = mid;
            else hi = mid;
        }
        console2.log("max taxDuration seconds:", lo);
        console2.log("max taxDuration days:", lo / 1 days);
    }

    function test_07_lockSaltFromContract() public {
        bytes32 salt = _mineSalt();
        uint256 fee = portal.SALT_LOCK_FEE();
        portal.lockSalt{value: fee}(salt, 0);
        (bool ok,) = _launch(salt, taxDuration);
        assertTrue(ok, "locked salt launch");
        console2.log("salt lock fee", fee);
    }

    function test_08_shortDurationExpiry() public {
        bytes32 salt = _mineSalt();
        uint32[4] memory durations = [uint32(1 hours), uint32(1 days), uint32(7 days), uint32(30 days)];
        address t;
        uint32 used;
        for (uint256 i; i < durations.length; ++i) {
            (bool ok, bytes memory ret) = _launch(salt, durations[i]);
            if (ok) {
                (t,) = abi.decode(ret, (address, address));
                used = durations[i];
                break;
            }
            console2.log("rejected seconds:", durations[i]);
            console2.logBytes(ret);
        }
        require(t != address(0), "no short duration");
        token = t;
        (, pair) = abi.decode(abi.encode(t, portal.getLaunchToken(t).pool), (address, address));
        console2.log("short taxDuration seconds:", used);
        address trader = makeAddr("trader");
        vm.deal(trader, 10 ether);
        (uint256 e0, uint256 a0) = _buy(trader, 1 ether);
        console2.log("before expiry received bps", a0 * 10_000 / e0);
        _logState("before");
        vm.warp(block.timestamp + used + 1);
        (uint256 e1, uint256 a1) = _buy(trader, 1 ether);
        console2.log("after expiry received bps", a1 * 10_000 / e1);
        _logState("after");
    }

    function test_09_liquidationReachesVault() public {
        (bool ok, bytes memory ret) = token.staticcall(abi.encodeWithSignature("liquidationThreshold()"));
        if (ok) console2.log("liquidationThreshold", abi.decode(ret, (uint256)));
        address trader = makeAddr("trader");
        vm.deal(trader, 100_000 ether);
        uint256 rounds;
        uint256 taxTokens;
        while (vault.bnbReceived() == 0 && rounds < 200) {
            (uint256 e, uint256 a) = _buy(trader, 5 ether);
            uint256 bal = IERC20(token).balanceOf(trader);
            taxTokens += (e - a) + bal * TAX_BPS / 10_000;
            uint256 held = IERC20(token).balanceOf(token);
            (uint256 q0, uint256 t0) = _reserves();
            _sell(trader, bal);
            if (vault.bnbReceived() > 0) {
                console2.log("liquidated on round", rounds);
                console2.log("token-contract tax tokens before sell", held);
                console2.log("their spot value BNB", held * q0 / t0);
            }
            ++rounds;
        }
        console2.log("rounds", rounds);
        console2.log("vault BNB received", vault.bnbReceived());
        console2.log("cumulative tax tokens (approx)", taxTokens);
        console2.log("token-contract tax tokens now", IERC20(token).balanceOf(token));
    }

    function test_10_dumpTaxPlumbing() public {
        string[8] memory views = [
            "taxExpirationTime()",
            "launchTime()",
            "antiFarmerExpirationTime()",
            "poolState()",
            "state()",
            "maxSupply()",
            "launchBlock()",
            "taxRate()"
        ];
        for (uint256 i; i < views.length; ++i) {
            (bool ok, bytes memory ret) = token.staticcall(abi.encodeWithSignature(views[i]));
            if (ok && ret.length >= 32) console2.log(views[i], abi.decode(ret, (uint256)));
        }
        bytes4[4] memory unknown = [bytes4(0x1b684546), 0x2c36560b, 0xe70b4499, 0xfd24bc7c];
        for (uint256 i; i < unknown.length; ++i) {
            (bool ok, bytes memory ret) = token.staticcall(abi.encodeWithSelector(unknown[i]));
            console2.logBytes4(unknown[i]);
            if (ok) console2.logBytes(ret);
        }
        console2.log("block.timestamp", block.timestamp);
        (bool ok2, bytes memory r2) = token.staticcall(abi.encodeWithSignature("taxProcessor()"));
        address proc = abi.decode(r2, (address));
        require(ok2);
        console2.log("processor", proc);
        bytes32 beaconSlot = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;
        address beacon = address(uint160(uint256(vm.load(proc, beaconSlot))));
        (, bytes memory implRet) = beacon.staticcall(abi.encodeWithSignature("implementation()"));
        console2.log("processor beacon", beacon);
        console2.log("processor impl", abi.decode(implRet, (address)));
        (bool ok3, bytes memory r3) = token.staticcall(abi.encodeWithSignature("dividendContract()"));
        if (ok3) console2.log("dividend", abi.decode(r3, (address)));
    }

    function test_11_processAndDispatch() public {
        address proc = abi.decode(_view(token, "taxProcessor()"), (address));
        _logUint(proc, "dispatchThreshold()");
        _logUint(proc, "processCooldown()");
        _logUint(proc, "requiresMEVProtection()");
        _logUint(proc, "commissionBps()");
        console2.log("feeReceiver", abi.decode(_view(proc, "feeReceiver()"), (address)));
        console2.log("converter", abi.decode(_view(proc, "converter()"), (address)));
        console2.log("feeConfig raw:");
        console2.logBytes(_view(proc, "feeConfig()"));
        console2.log("walletConfig raw:");
        console2.logBytes(_view(proc, "getWalletConfig()"));

        address trader = makeAddr("trader");
        vm.deal(trader, 1_000 ether);
        for (uint256 i; i < 10; ++i) {
            _buy(trader, 5 ether);
            _sell(trader, IERC20(token).balanceOf(trader));
        }
        uint256 held = IERC20(token).balanceOf(token);
        (uint256 q, uint256 t) = _reserves();
        console2.log("tax tokens held by token", held);
        console2.log("spot value BNB", held * q / t);

        address keeper = makeAddr("keeper");
        vm.warp(block.timestamp + 1 hours);
        vm.prank(keeper);
        (bool okP, bytes memory rP) = proc.call(abi.encodeWithSignature("processTaxTokens(uint256)", held));
        console2.log("processTaxTokens by stranger ok", okP);
        if (!okP) console2.logBytes(rP);
        console2.log("tax tokens held by token after", IERC20(token).balanceOf(token));
        _logUint(proc, "marketQuoteBalance()");
        _logUint(proc, "feeQuoteBalance()");
        _logUint(proc, "lpQuoteBalance()");
        _logUint(proc, "dividendQuoteBalance()");
        _logUint(proc, "commissionQuoteBalance()");
        _logUint(proc, "deferredTaxTokenBalance()");
        console2.log("processor BNB", proc.balance);

        vm.prank(keeper);
        (bool okD, bytes memory rD) = proc.call(abi.encodeWithSignature("dispatch()"));
        console2.log("dispatch by stranger ok", okD);
        if (!okD) console2.logBytes(rD);
        console2.log("vault BNB received", vault.bnbReceived());
        _logUint(proc, "totalQuoteSentToMarketing()");
        _logUint(proc, "feeQuoteBalance()");
        console2.log("dead balance", IERC20(token).balanceOf(DEAD));
    }

    function test_12_processingKeepsUp() public {
        address proc = abi.decode(_view(token, "taxProcessor()"), (address));
        address trader = makeAddr("trader");
        vm.deal(trader, 1_000 ether);
        uint256 taxTokens;
        uint256 taxValue;
        for (uint256 i; i < 40; ++i) {
            vm.warp(block.timestamp + 15);
            (uint256 e, uint256 a) = _buy(trader, 2 ether);
            uint256 bal = IERC20(token).balanceOf(trader);
            uint256 roundTax = (e - a) + bal * TAX_BPS / 10_000;
            (uint256 q, uint256 t) = _reserves();
            taxTokens += roundTax;
            taxValue += roundTax * q / t;
            _sell(trader, bal);
            if (i % 10 == 9) {
                (bool ok,) = proc.call(abi.encodeWithSignature("dispatch()"));
                ok;
            }
        }
        vm.warp(block.timestamp + 15);
        proc.call(abi.encodeWithSignature("dispatch()"));
        console2.log("tax tokens generated", taxTokens);
        console2.log("tax tokens still unsold in token", IERC20(token).balanceOf(token));
        console2.log("tax value BNB (spot)", taxValue);
        console2.log("vault BNB received", vault.bnbReceived());
        console2.log("vault / tax value (bps)", vault.bnbReceived() * 10_000 / taxValue);
        console2.log("dead balance", IERC20(token).balanceOf(DEAD));
    }

    function _view(address target, string memory sig) internal view returns (bytes memory ret) {
        bool ok;
        (ok, ret) = target.staticcall(abi.encodeWithSignature(sig));
        require(ok, sig);
    }

    function _logUint(address target, string memory sig) internal view {
        (bool ok, bytes memory ret) = target.staticcall(abi.encodeWithSignature(sig));
        if (ok && ret.length >= 32) console2.log(sig, abi.decode(ret, (uint256)));
        else console2.log(sig, "unavailable");
    }

    function _tryLaunch(bytes32 salt, uint32 duration) internal returns (bool ok, bytes memory ret) {
        uint256 snap = vm.snapshotState();
        (ok, ret) = _launch(salt, duration);
        vm.revertToState(snap);
    }

    function _launch(bytes32 salt, uint32 duration) internal returns (bool ok, bytes memory ret) {
        FeeConfig[] memory fees = new FeeConfig[](2);
        fees[0] = FeeConfig(FeeSlotType.VAULT, 8000, abi.encode(FeeConfigVault(address(factory), "")));
        fees[1] = FeeConfig(FeeSlotType.DEFLATION, 2000, "");
        CreateTaxTokenParams memory p = CreateTaxTokenParams({
            name: "MINT.AI",
            symbol: "MINT.AI",
            meta: "",
            totalSupply: SUPPLY,
            salt: salt,
            quoteToken: address(0),
            dexId: 0,
            poolQuote: POOL_QUOTE,
            poolToken: POOL_TOKEN,
            buyTaxRate: TAX_BPS,
            sellTaxRate: TAX_BPS,
            taxDuration: duration,
            antiFarmerDuration: 0,
            feeConfigs: fees,
            antiSniperMode: 0,
            exemptWindow: 0,
            exemptAddrs: new address[](0),
            creatorBuyQuote: 0,
            extensionID: bytes32(0),
            extensionData: "",
            commissionReceiver: address(0)
        });
        Distribution memory d = Distribution(DistributionTarget.VAULT, address(0), uint128(SUPPLY - POOL_TOKEN), "");
        (ok, ret) = HUB.call{value: POOL_QUOTE}(
            abi.encodeCall(IDirectLaunchPortal.launchTaxTokenV2, (p, d, CreatorBuyParams(0, "")))
        );
    }

    function _mineSalt() internal returns (bytes32 salt) {
        if (nextSaltIndex == 0) _checkPrediction();
        for (uint256 i = nextSaltIndex + 1;; ++i) {
            salt = bytes32(i);
            address predicted = Clones.predictDeterministicAddress(TOKEN_IMPL, salt, HUB);
            if (uint16(uint160(predicted)) == 0x7777 && predicted.code.length == 0) {
                nextSaltIndex = i;
                return salt;
            }
        }
    }

    function _checkPrediction() internal {
        nextSaltIndex = 1;
        (bool ok, bytes memory ret) = _launch(bytes32(uint256(1)), 365 days);
        require(!ok, "non-vanity salt launched");
        if (ret.length >= 36 && bytes4(ret) == VANITY_ERR) {
            address reported;
            assembly {
                reported := mload(add(ret, 36))
            }
            address predicted = Clones.predictDeterministicAddress(TOKEN_IMPL, bytes32(uint256(1)), HUB);
            console2.log("portal predicted", reported);
            console2.log("clones predicted", predicted);
            require(reported == predicted, "prediction formula mismatch");
        } else {
            console2.log("non-vanity launch reverted with:");
            console2.logBytes(ret);
        }
    }

    function _buy(address who, uint256 bnb) internal returns (uint256 expected, uint256 actual) {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = token;
        expected = IRouter(ROUTER).getAmountsOut(bnb, path)[1];
        uint256 before = IERC20(token).balanceOf(who);
        vm.prank(who);
        IRouter(ROUTER).swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnb}(0, path, who, block.timestamp);
        actual = IERC20(token).balanceOf(who) - before;
    }

    function _sell(address who, uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = WBNB;
        vm.startPrank(who);
        IERC20(token).approve(ROUTER, amount);
        IRouter(ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, who, block.timestamp);
        vm.stopPrank();
    }

    function _reserves() internal view returns (uint256 q, uint256 t) {
        (uint112 r0, uint112 r1,) = IPair(pair).getReserves();
        (q, t) = IPair(pair).token0() == WBNB ? (uint256(r0), uint256(r1)) : (uint256(r1), uint256(r0));
    }

    function _logState(string memory label) internal view {
        (bool ok, bytes memory ret) = token.staticcall(abi.encodeWithSignature("state()"));
        if (ok && ret.length >= 32) {
            console2.log(label, "state()", abi.decode(ret, (uint8)));
        } else {
            console2.log(label, "state() unavailable");
        }
    }

    function _rpc() internal view returns (string memory) {
        try vm.envString("FORK_RPC_URL") returns (string memory url) {
            if (bytes(url).length > 0) return url;
        } catch {}
        try vm.envString("BSC_RPC_URL") returns (string memory url) {
            if (bytes(url).length > 0) return url;
        } catch {}
        return "https://bsc-dataseed.binance.org";
    }
}
