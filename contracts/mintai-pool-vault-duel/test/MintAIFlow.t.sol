// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2, Vm} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {MintAICards} from "../src/MintAICards.sol";
import {MintAICardMarket} from "../src/MintAICardMarket.sol";
import {MintAICardsBase} from "../src/MintAICardsBase.sol";
import {MintAIVault} from "../src/MintAIVault.sol";
import {MintAIVaultFactory} from "../src/MintAIVaultFactory.sol";
import {MintAILauncherFactory, MintAISystemDeployer} from "../src/MintAILauncherFactory.sol";
import {MintAICardsLens} from "../src/MintAICardsLens.sol";
import {MintAIParams as P} from "../src/MintAIParams.sol";
import {IDirectLaunchPortal, ITokenDock} from "../src/flap/IDirectPoolLaunch.sol";
import {IAntiScam, IV2Pair, IFlapTriggerService} from "../src/MintAIInterfaces.sol";

contract AgentIdStub {
    mapping(address => uint256) public balanceOf;

    function set(address who, uint256 bal) external {
        balanceOf[who] = bal;
    }
}

interface ILaunchPortal {
    struct LauncherRecord {
        address launcherFactory;
    }

    function newLauncher(address launcherFactory, bytes calldata data) external payable returns (address launcher);
    function getLauncher(address launcher) external view returns (LauncherRecord memory);
    function setLauncherFactoryMultiplier(address factory, uint16 multiplierBps, bool enabled) external;
    function setVaultFactoryMultiplier(address factory, uint16 multiplierBps, bool enabled) external;
}

interface IRouterT {
    function WETH() external view returns (address);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256, address[] calldata, address, uint256)
        external
        payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256, uint256, address[] calldata, address, uint256)
        external;
}

/// @dev BSC testnet fork against the live Flap Pool Launch portal, Token Dock and Pancake V2.
contract MintAIFlowTest is Test {
    address internal constant HUB = 0x000042108465206185A077Edc3F3fd2b49060000;
    address internal constant TOKEN_IMPL = 0x7777c57ff7dc441c1715b2e36fa581c48B782222;
    address internal constant DOCK = 0x000048E888aBf09f690a952E1b386b2D031a0000;
    address internal constant GUARDIAN = 0x00004d58290854c5E9880F4b5B1993c6Ad8b0000;
    /// @dev Role the live Portal checks before setLauncherFactoryMultiplier / setVaultFactoryMultiplier.
    ///      Granted only inside the fork.
    bytes32 internal constant FACTORY_ADMIN_ROLE =
        0x4963b4023b6bd340aa187168ec181d3a3f0622501df2db470248e5abc5f8e0d8;
    address internal constant ROUTER = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal constant AGENT_ID = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;

    MintAIVaultFactory internal factory;
    MintAICards internal cards;
    MintAICardsLens internal lens;
    MintAIVault internal vault;
    IERC20 internal token;
    address internal pair;

    address internal ops = makeAddr("ops");
    address internal team = makeAddr("team");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    uint256 internal saltCursor;

    function setUp() public {
        uint256 pinned = vm.envOr("FORK_BLOCK", uint256(0));
        if (pinned != 0) vm.createSelectFork(_rpc(), pinned);
        else vm.createSelectFork(_rpc());
        require(block.chainid == 97, "bsc testnet fork required");
        vm.etch(AGENT_ID, address(new AgentIdStub()).code);
        lens = new MintAICardsLens();
        (factory, cards) = _deploy();
    }

    // ---------------------------------------------------------------- tests

    /// @dev Uses the live testnet anti-scam module. No mock. MINT.AI is clean; BNB and USDT are flagged.
    function test_fork_antiScamWordOnChain() public {
        IAntiScam module = IAntiScam(factory.antiScamModule());
        assertEq(address(module), 0x5CfbE713d070e87F67D1bc84312B7eB8Fe4F2B5E);
        assertGt(address(module).code.length, 0, "live module");
        (bool nameScam, bool symbolScam) = module.isScamWord("MINT.AI", "MINT.AI");
        assertFalse(nameScam);
        assertFalse(symbolScam);
        (nameScam, symbolScam) = module.isScamWord("BNB", "MINT.AI");
        assertTrue(nameScam);
        (nameScam, symbolScam) = module.isScamWord("USDT", "MINT.AI");
        assertTrue(nameScam);
        (nameScam, symbolScam) = module.isScamWord("MINT.AI", "USDT");
        assertFalse(nameScam);
        assertTrue(symbolScam);
        (nameScam, symbolScam) = module.isScamWord("MINT.AI", "BNB");
        assertFalse(nameScam);
        assertTrue(symbolScam);

        vm.prank(address(cards));
        (bytes32 id, bytes32 word) = factory.creatorExtension();
        assertEq(id, keccak256("flap.extension.creator.v1"));
        assertEq(address(uint160(uint256(word))), address(this));

        MintAICards.InitParams memory init = MintAICards.InitParams({
            owner: address(this),
            opsWallet: ops,
            teamWallet: team,
            router: ROUTER,
            tokenName: "BNB",
            tokenSymbol: "MINT.AI",
            tokenMeta: "",
            salt: _mineSalt()
        });
        MintAISystemDeployer deployed =
            new MintAISystemDeployer(
            address(new MintAIVault()), address(new MintAICards()), address(new MintAICardMarket()), keccak256(abi.encode(init))
        );
        MintAILauncherFactory launcher = deployed.launcherFactory();
        vm.store(HUB, keccak256(abi.encode(address(this), FACTORY_ADMIN_ROLE)), bytes32(uint256(1)));
        ILaunchPortal(HUB).setLauncherFactoryMultiplier(address(launcher), 5_000, true);
        ILaunchPortal(HUB).setVaultFactoryMultiplier(address(deployed.vaultFactory()), 5_000, true);
        vm.expectRevert(MintAIVaultFactory.ScamName.selector);
        ILaunchPortal(HUB).newLauncher(address(launcher), abi.encode(init));

        init.tokenName = "MINT.AI";
        init.tokenSymbol = "USDT";
        deployed = new MintAISystemDeployer(
            address(new MintAIVault()), address(new MintAICards()), address(new MintAICardMarket()), keccak256(abi.encode(init))
        );
        launcher = deployed.launcherFactory();
        ILaunchPortal(HUB).setLauncherFactoryMultiplier(address(launcher), 5_000, true);
        ILaunchPortal(HUB).setVaultFactoryMultiplier(address(deployed.vaultFactory()), 5_000, true);
        vm.expectRevert(MintAIVaultFactory.ScamName.selector);
        ILaunchPortal(HUB).newLauncher(address(launcher), abi.encode(init));
    }

    function test_fork_pricesAndBudgets() public view {
        assertEq(cards.priceOf(1), 0.00245 ether);
        assertEq(cards.priceOf(20_001), 0.0049 ether);
        assertEq(P.GRANT_BUDGET + P.LADDER_BUDGET + P.UNALLOCATED, P.RESERVE);
        assertEq(cards.presaleDeadline(), block.timestamp + 7 days, "presale window");
    }

    function test_fork_presaleLaunchAndVesting() public {
        vm.deal(alice, 1 ether);
        _id(alice);
        vm.prank(alice);
        cards.mint{value: 0.0049 ether}(2, 0);
        vm.prank(alice);
        vm.expectRevert(MintAICardsBase.TransferLocked.selector);
        cards.transferFrom(alice, bob, 1);

        uint256 opsBefore = ops.balance;
        _launch();
        assertEq(cards.presaleEscrow(), 0, "escrow spent");
        assertEq(ops.balance - opsBefore, 12.25 ether, "25% of the presale");
        assertEq(address(cards).balance, 0, "escrow emptied");
        (address v, address f) = IDirectLaunchPortal(HUB).getLaunchVault(address(token));
        assertEq(v, address(vault));
        assertEq(f, address(factory));
        assertEq(
            ITokenDock(DOCK).balanceOf(address(token), address(vault)),
            P.GRANT_BUDGET + P.LADDER_BUDGET,
            "grant and ladder docked"
        );
        assertEq(token.balanceOf(DEAD), P.UNALLOCATED, "unallocated burned");
        (uint256 q, uint256 t) = _reserves();
        assertEq(q, P.POOL_QUOTE);
        assertEq(t, P.POOL_TOKEN);

        vm.warp(block.timestamp + 1 days);
        vm.prank(alice);
        vault.claimTokens(0, 0);
        assertEq(
            token.balanceOf(alice),
            2 * 8_440 ether / 5 + (2 * 8_440 ether - 2 * 8_440 ether / 5) / 5,
            "one fifth at launch plus one day of the remainder, no tax"
        );
        vm.warp(block.timestamp + 4 days);
        vm.prank(alice);
        vault.claimTokens(0, 0);
        assertEq(token.balanceOf(alice), 2 * 8_440 ether, "full grant after 5 days");

        vm.prank(team);
        cards.mintTeam(team, 100);
        assertTrue(cards.isTeamCard(cards.lastTokenId()));
        vm.warp(block.timestamp + 5 days);
        vm.prank(team);
        vault.claimTokens(0, 0);
        assertEq(token.balanceOf(team), 100 * 8_440 ether, "team grant");
    }

    function test_fork_floorCancelsAnUntouchedNewCardsTokens() public {
        _sellOutPresale();
        _launch();
        vm.deal(address(vault), 1 ether);
        vault.sync();
        vm.deal(bob, 1 ether);
        _id(bob);
        vm.prank(bob);
        cards.mint{value: 2 * 0.0049 ether}(2, 1);
        uint256 a = cards.lastTokenId() - 1;
        (uint256 maxPrice, uint256 forfeit) = vault.floorLimit(a, bob);
        assertEq(maxPrice, 0.0049 ether);
        uint256[] memory prices = new uint256[](1);
        prices[0] = 0.0049 ether;
        vm.prank(bob);
        cards.list(_ids(a, a), prices);
        uint256 deadBefore = token.balanceOf(DEAD);
        uint256 bobBefore = bob.balance;
        assertEq(vault.sweepFloor(), 1);
        assertGe(bob.balance - bobBefore, 0.0049 ether, "bob gets the full ask");
        assertEq(token.balanceOf(DEAD) - deadBefore, forfeit, "the card's tokens are burned on the real token");
        assertEq(token.balanceOf(address(vault)), vault.boughtOwed(), "the other card's tokens stay");

        address holder = cards.ownerOf(1);
        prices[0] = 0.00246 ether;
        vm.prank(holder);
        cards.list(_ids(1, 1), prices);
        assertEq(vault.sweepFloor(), 0, "a presale card above 0.00245 is skipped");
        prices[0] = 0.00245 ether;
        vm.prank(holder);
        cards.list(_ids(1, 1), prices);
        assertEq(vault.sweepFloor(), 1, "a presale card is bought at its mint price");
        assertEq(vault.totalForfeitBurned(), forfeit, "and keep their grant");

        vm.warp(block.timestamp + 5 days);
        vm.prank(bob);
        uint256 got = vault.claimTokens(0, 0);
        assertEq(token.balanceOf(bob), got);
        assertEq(vault.boughtOwed(), 0);
    }

    function test_fork_postOpenMintBuysBurnsAndVests() public {
        _sellOutPresale();
        _launch();
        (uint256 q0, uint256 t0) = _reserves();
        uint256 opsBefore = ops.balance;
        uint256 deadBefore = token.balanceOf(DEAD);
        vm.deal(bob, 10 ether);
        _id(bob);
        (uint256 total, uint256 estimate) = lens.quoteMint(address(cards), 10);
        assertEq(total, 10 * 0.0049 ether);
        vm.prank(bob);
        cards.mint{value: total}(10, estimate * 98 / 100);

        uint256 vested = vault.boughtOwed();
        uint256 burned = token.balanceOf(DEAD) - deadBefore;
        console2.log("estimate (tokens)", estimate / 1e18);
        console2.log("vested to bob (tokens)", vested / 1e18);
        console2.log("burned (tokens)", burned / 1e18);
        assertEq(ops.balance - opsBefore, total * 25 / 100, "ops 25%");
        assertEq(vault.totalMintBnb(), total * 75 / 100, "75% swapped");
        assertEq(burned, vault.totalMintBought() / 10, "10% of what was bought is burned");
        assertEq(vested + burned, vault.totalMintBought(), "90% vests");
        assertEq(token.balanceOf(address(vault)), vested, "vault holds the vesting tokens");
        assertApproxEqRel(vested, estimate, 0.02e18, "lens estimate within 2%");
        assertEq(token.balanceOf(bob), 0, "nothing liquid at mint");
        (uint256 q1, uint256 t1) = _reserves();
        assertEq(q1 - q0, total * 75 / 100, "the pool gets the BNB");
        assertLt(t1, t0, "the pool loses the bought tokens");

        vm.warp(block.timestamp + 5 days);
        vm.prank(bob);
        vault.claimTokens(0, 0);
        assertEq(token.balanceOf(bob), vested, "vested tokens arrive untaxed");
        assertEq(vault.boughtOwed(), 0);

        vm.deal(alice, 1 ether);
        _id(alice);
        (total, estimate) = lens.quoteMint(address(cards), 1);
        vm.prank(alice);
        vm.expectRevert();
        cards.mint{value: total}(1, estimate * 2);
    }

    function test_fork_taxSplitFloorAndDividend() public {
        _sellOutPresale();
        _launch();
        address trader = makeAddr("trader");
        vm.deal(trader, 500 ether);
        for (uint256 i; i < 30; ++i) {
            vm.warp(block.timestamp + 15);
            _buy(trader, 8 ether);
            _sell(trader, token.balanceOf(trader));
        }
        vm.warp(block.timestamp + 15);
        uint256 opsBefore = ops.balance;
        vault.dispatchAndSync();
        cards.poke();
        uint256 revenue = vault.totalTaxRevenue();
        console2.log("tax revenue to vault", revenue);
        assertGt(revenue, 0, "vault got tax");
        assertEq(vault.unrecognizedTax(), 0);
        uint256 floorShare = revenue * 30 / 100;
        assertEq(vault.totalFloorForwarded(), floorShare, "30% floor share");
        uint256 waterline = floorShare < 0.02 ether ? floorShare : 0.02 ether;
        assertEq(vault.floorFund(), floorShare - waterline, "floor fund is what remains after the 0.02 waterline");
        uint256 reserved = waterline;
        if (vault.pendingTriggerId() != 0) reserved -= IFlapTriggerService(vault.triggerService()).getFee();
        assertEq(vault.triggerReserve(), reserved, "waterline minus the trigger fee just paid");
        assertGt(vault.floorFund(), 0.006 ether, "enough floor fund to buy three cards");
        uint256 requestId = vault.pendingTriggerId();
        assertGt(requestId, 0, "booked on the live Flap Trigger service");
        assertApproxEqAbs(ops.balance - opsBefore, revenue * 20 / 100, 1, "20% ops");
        assertApproxEqAbs(cards.dividendLiability() + cards.pendingDividend(), revenue * 50 / 100, 2, "50% dividend");

        uint256 expected = cards.pendingDividendOf(1);
        address holder = cards.ownerOf(1);
        uint256 before = holder.balance;
        vm.prank(holder);
        cards.claim(_ids(1, 1));
        assertEq(holder.balance - before, expected, "card dividend");

        uint256 price = vault.floorFund() / 3 / 1e13 * 1e13;
        uint256[] memory prices = new uint256[](3);
        for (uint256 i; i < 3; ++i) prices[i] = price > 0.002 ether ? 0.002 ether : price;
        address seller = cards.ownerOf(11);
        vm.prank(seller);
        cards.list(_ids(11, 13), prices);
        before = seller.balance;

        vm.warp(vault.triggerDueAt());
        uint256 g = gasleft();
        vm.prank(vault.triggerService());
        vault.trigger{gas: 2_000_000}(requestId);
        console2.log("trigger callback gas (3 cards)", g - gasleft());
        assertEq(vault.totalFloorBurned(), 3, "the trigger bought the three cards");
        assertGe(seller.balance - before, 3 * prices[0], "seller paid in full");
        assertEq(cards.totalWeight(), 20_000 - 3, "floor cards burned");
        assertGt(vault.pendingTriggerId(), requestId, "and booked the next run on the live service");
    }

    function test_fork_ladderNeedsTwapAndStreams() public {
        _sellOutPresale();
        _launch();
        vm.expectRevert(MintAIVault.TwapNotReady.selector);
        vault.buyLadder(0, 1_000_000 ether);

        address whale = makeAddr("whale");
        vm.deal(whale, 10_000 ether);
        _buy(whale, 12 ether);
        vm.warp(block.timestamp + 31 minutes);
        vault.poke();
        vm.warp(block.timestamp + 31 minutes);
        vault.poke();
        uint256 twap = vault.twapPrice();
        console2.log("twap / opening price x100", twap * 100 / P.openingPrice());
        assertGe(twap, vault.rungPrice(0), "above 1.5x");
        assertLt(twap, vault.rungPrice(1), "below 2x");

        uint256 amount = 1_000_000 ether;
        uint256 cost = (amount * vault.rungPrice(0) + 1e18 - 1) / 1e18;
        vm.deal(bob, cost + 1 ether);
        vm.prank(bob);
        vault.buyLadder{value: cost + 1 ether}(0, amount);
        assertEq(token.balanceOf(bob), amount, "ladder tokens");
        assertEq(bob.balance, 1 ether, "refund excess");
        assertEq(cards.streamRemaining(), cost, "streamed");
        vm.expectRevert(abi.encodeWithSelector(MintAIVault.RungNotReached.selector, twap, vault.rungPrice(1)));
        vault.buyLadder(1, 1 ether);

        vm.warp(block.timestamp + 7 days + 1);
        cards.poke();
        assertEq(cards.streamRemaining(), 0, "stream done");
    }

    function test_fork_marketSettlesDividendToSeller() public {
        _sellOutPresale();
        _launch();
        address trader = makeAddr("trader");
        vm.deal(trader, 200 ether);
        for (uint256 i; i < 10; ++i) {
            vm.warp(block.timestamp + 15);
            _buy(trader, 2 ether);
            _sell(trader, token.balanceOf(trader));
        }
        vm.warp(block.timestamp + 15);
        vault.dispatchAndSync();
        cards.poke();

        address seller = cards.ownerOf(1);
        uint256 earned = cards.pendingDividendOf(1);
        assertGt(earned, 0);
        uint256[] memory prices = new uint256[](1);
        prices[0] = 0.01 ether;
        vm.prank(seller);
        cards.list(_ids(1, 1), prices);
        (MintAICardsLens.ListingView[] memory open,,) = lens.getActiveListings(address(cards), 0, 0);
        assertEq(open.length, 1);
        uint256 sellerBefore = seller.balance;
        uint256 opsBefore = ops.balance;
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        cards.buy{value: 0.01 ether}(_ids(1, 1), prices);
        assertEq(cards.ownerOf(1), bob);
        assertEq(seller.balance - sellerBefore, 0.0099 ether + earned, "seller gets price - 1% + dividend");
        assertEq(ops.balance - opsBefore, 0.0001 ether, "1% to ops");
        assertEq(cards.pendingDividendOf(1), 0, "buyer starts fresh");
    }

    function test_fork_refundWhenPresaleFails() public {
        uint256 openedAt = block.timestamp;
        (, MintAICards c2) = _deploy();
        vm.deal(alice, 1 ether);
        _id(alice);
        vm.prank(alice);
        c2.mint{value: 3 * 0.00245 ether}(3, 0);
        vm.warp(openedAt + 7 days);
        vm.prank(alice);
        vm.expectRevert(MintAICardsBase.PresaleNotFailed.selector);
        c2.refund(_ids(1, 3));
        vm.warp(openedAt + 7 days + 1);
        vm.prank(alice);
        vm.expectRevert(MintAICardsBase.PresaleClosed.selector);
        c2.mint{value: 0.00245 ether}(1, 0);
        uint256 before = alice.balance;
        vm.prank(alice);
        c2.refund(_ids(1, 3));
        assertEq(alice.balance - before, 3 * 0.00245 ether, "full refund");
        assertEq(address(c2).balance, 0);
    }

    function test_fork_agentIdAndLifetimeCap() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectRevert(MintAICardsBase.AgentIdRequired.selector);
        cards.mint{value: 0.00245 ether}(1, 0);
        _id(alice);
        vm.prank(alice);
        cards.mint{value: 10 * 0.00245 ether}(10, 0);
        assertEq(cards.mintsUsed(alice), 10);
        vm.prank(alice);
        vm.expectRevert(MintAICardsBase.MintCapReached.selector);
        cards.mint{value: 0.00245 ether}(1, 0);
    }

    function test_fork_accessControl() public {
        vm.expectRevert();
        factory.newVault(address(1), address(cards), 0, "");
        address impl = address(new MintAIVault());
        vm.expectRevert();
        factory.upgradeVaultImplementation(impl);
        vm.prank(GUARDIAN);
        factory.upgradeVaultImplementation(impl);
        assertEq(UpgradeableBeacon(factory.vaultBeacon()).implementation(), impl);
        vm.expectRevert(MintAICardsBase.NotVault.selector);
        cards.onVaultRevenue{value: 0}(0, 0, 0);
        vm.expectRevert(MintAICardsBase.NotVault.selector);
        cards.floorBuy(1);
        vm.prank(alice);
        vm.expectRevert(MintAICardsBase.NotOwnerOrGuardian.selector);
        cards.setOpsWallet(alice);
    }

    // ---------------------------------------------------------------- helpers

    function _deploy() internal returns (MintAIVaultFactory f, MintAICards c) {
        (address vaultFactory, address launcher, bytes memory initData) = this.bootLauncher();
        f = MintAIVaultFactory(vaultFactory);
        uint256 saltFee = IDirectLaunchPortal(HUB).SALT_LOCK_FEE();
        vm.deal(address(this), address(this).balance + saltFee);
        address created = ILaunchPortal(HUB).newLauncher{value: saltFee}(launcher, initData);
        ILaunchPortal.LauncherRecord memory rec = ILaunchPortal(HUB).getLauncher(created);
        assertEq(rec.launcherFactory, launcher, "portal records the launcher factory");
        c = MintAICards(payable(created));
        assertTrue(c.saltLocked(), "creation locks the salt");
        assertEq(c.portal(), HUB);
        assertEq(c.name(), "MINT.AI");
        assertEq(c.symbol(), "MINT.AI");
        assertEq(c.factory(), vaultFactory);
    }

    function bootLauncher() external returns (address vaultFactory, address launcher, bytes memory initData) {
        require(msg.sender == address(this));
        MintAICards.InitParams memory init = MintAICards.InitParams({
            owner: address(this),
            opsWallet: ops,
            teamWallet: team,
            router: ROUTER,
            tokenName: "MINT.AI",
            tokenSymbol: "MINT.AI",
            tokenMeta: "",
            salt: _mineSalt()
        });
        initData = abi.encode(init);
        MintAISystemDeployer deployed =
            new MintAISystemDeployer(
            address(new MintAIVault()), address(new MintAICards()), address(new MintAICardMarket()), keccak256(initData)
        );
        vaultFactory = address(deployed.vaultFactory());
        MintAILauncherFactory launcherContract = deployed.launcherFactory();
        launcher = address(launcherContract);
        assertEq(launcherContract.factorySpecVersion(), "lf-v1");
        assertEq(MintAIVaultFactory(vaultFactory).factorySpecVersion(), "pl-v1");
        vm.store(HUB, keccak256(abi.encode(address(this), FACTORY_ADMIN_ROLE)), bytes32(uint256(1)));
        ILaunchPortal(HUB).setLauncherFactoryMultiplier(launcher, 5_000, true);
        ILaunchPortal(HUB).setVaultFactoryMultiplier(vaultFactory, MintAIVaultFactory(vaultFactory).FLOOR_MULTIPLIER_BPS(), true);
    }

    function _sellOutPresale() internal {
        if (!cards.launched()) vm.recordLogs();
        for (uint256 b; cards.paidMinted() < 20_000; ++b) {
            uint256 left = 20_000 - cards.paidMinted();
            uint256 n = left < 10 ? left : 10;
            address who = address(uint160(0xB0000 + b));
            _id(who);
            (uint256 total,) = lens.quoteMint(address(cards), n);
            vm.deal(who, total);
            vm.prank(who);
            cards.mint{value: total}(n, 0);
        }
        assertEq(cards.paidMinted(), 20_000);
    }

    function _launch() internal {
        if (!cards.launched()) _sellOutPresale();
        token = IERC20(cards.launchedToken());
        pair = cards.launchedPool();
        vault = MintAIVault(payable(cards.vault()));
        assertEq(uint16(uint160(address(token))), 0x7777, "vanity");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 graduatedTopic = keccak256("FlapTokenGraduated(address)");
        bool graduated;
        for (uint256 i; i < logs.length; ++i) {
            if (logs[i].topics.length > 0 && logs[i].topics[0] == graduatedTopic && logs[i].data.length >= 32) {
                if (abi.decode(logs[i].data, (address)) == address(token)) graduated = true;
            }
        }
        assertTrue(graduated, "graduated at the minimum pool");
        (uint256 q, uint256 tkn) = _reserves();
        assertEq(q, P.POOL_QUOTE, "minimum pool quote 36.75 BNB");
        assertEq(tkn, P.POOL_TOKEN, "124,672,000 tokens in the pool");
    }

    function _mineSalt() internal returns (bytes32 s) {
        for (uint256 i = saltCursor + 1;; ++i) {
            s = keccak256(abi.encode("MINT.AI", i));
            address predicted = Clones.predictDeterministicAddress(TOKEN_IMPL, s, HUB);
            if (uint16(uint160(predicted)) == 0x7777 && predicted.code.length == 0) {
                saltCursor = i;
                return s;
            }
        }
    }

    function _id(address who) internal {
        // The live Agent ID mapping slot is empty for these wallets. A fork SSTORE asks the
        // RPC for that proof, and public BSC nodes answer "missing trie node". mockCall
        // satisfies the same balanceOf check without that read.
        vm.mockCall(AGENT_ID, abi.encodeWithSelector(bytes4(0x70a08231), who), abi.encode(uint256(1)));
    }

    function _ids(uint256 from, uint256 to) internal pure returns (uint256[] memory ids) {
        ids = new uint256[](to - from + 1);
        for (uint256 i; i < ids.length; ++i) ids[i] = from + i;
    }

    function _reserves() internal view returns (uint256 q, uint256 t) {
        (uint112 r0, uint112 r1,) = IV2Pair(pair).getReserves();
        (q, t) = IV2Pair(pair).token0() == address(token) ? (uint256(r1), uint256(r0)) : (uint256(r0), uint256(r1));
    }

    function _buy(address who, uint256 bnb) internal {
        address[] memory path = new address[](2);
        path[0] = IRouterT(ROUTER).WETH();
        path[1] = address(token);
        vm.prank(who);
        IRouterT(ROUTER).swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnb}(0, path, who, block.timestamp);
    }

    function _sell(address who, uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = IRouterT(ROUTER).WETH();
        vm.startPrank(who);
        token.approve(ROUTER, amount);
        IRouterT(ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, who, block.timestamp);
        vm.stopPrank();
    }

    function _rpc() internal view returns (string memory) {
        try vm.envString("FORK_RPC_URL") returns (string memory url) {
            if (bytes(url).length > 0) return url;
        } catch {}
        return "https://bsc-testnet-rpc.publicnode.com";
    }
}
