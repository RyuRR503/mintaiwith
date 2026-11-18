// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MintAICards} from "../src/MintAICards.sol";
import {MintAICardMarket} from "../src/MintAICardMarket.sol";
import {MintAIVault} from "../src/MintAIVault.sol";
import {MintAIVaultFactory} from "../src/MintAIVaultFactory.sol";
import {MintAILauncherFactory, MintAISystemDeployer} from "../src/MintAILauncherFactory.sol";
import {MintAIDuel} from "../src/MintAIDuel.sol";
import {MintAICardsLens} from "../src/MintAICardsLens.sol";
import {MintAIParams as P} from "../src/MintAIParams.sol";
import {LaunchVaultAddresses} from "../src/flap/LaunchVaultAddresses.sol";
import {AgentIdStub, MockAntiScam, MockDock, MockPortal, MockRouter, MockTrigger, MockWBNB} from "./MintAIMocks.sol";

contract MintAIBase is Test {
    address internal constant TRIGGER = 0x560E9830926C9e0EB98a59c6b9902383Fc0D9Eb2;
    address internal constant HUB = 0x000042108465206185A077Edc3F3fd2b49060000;
    address internal constant DOCK = 0x000048E888aBf09f690a952E1b386b2D031a0000;
    address internal constant AGENT_ID = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;
    address internal constant ANTI_SCAM = 0x5CfbE713d070e87F67D1bc84312B7eB8Fe4F2B5E;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    MintAIVaultFactory internal factory;
    MintAILauncherFactory internal launcher;
    MintAICards internal cards;
    MintAIVault internal vault;
    MintAIDuel internal duel;
    MintAICardsLens internal lens;
    MockWBNB internal wbnb;
    MockRouter internal router;

    address internal ops;
    address internal team;

    function _setUpLocal() internal {
        vm.chainId(97);
        ops = makeAddr("ops");
        team = makeAddr("team");
        wbnb = new MockWBNB();
        address pancake = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
        MockRouter deployed = new MockRouter(address(wbnb));
        vm.etch(pancake, address(deployed).code);
        router = MockRouter(pancake);
        router.setRate(uint256(124_672_000 ether) * 1e18 / 36.75 ether);
        vm.etch(HUB, address(new MockPortal(address(wbnb))).code);
        vm.etch(DOCK, address(new MockDock()).code);
        vm.etch(AGENT_ID, address(new AgentIdStub()).code);
        vm.etch(TRIGGER, address(new MockTrigger()).code);
        vm.etch(ANTI_SCAM, address(new MockAntiScam()).code);

        MintAICards.InitParams memory init = MintAICards.InitParams({
            owner: address(this),
            opsWallet: ops,
            teamWallet: team,
            router: address(router),
            tokenName: "MINT.AI",
            tokenSymbol: "MINT.AI",
            tokenMeta: "",
            salt: bytes32(uint256(1))
        });
        MintAISystemDeployer system =
            new MintAISystemDeployer(
            address(new MintAIVault()), address(new MintAICards()), address(new MintAICardMarket()), keccak256(abi.encode(init))
        );
        factory = system.vaultFactory();
        launcher = system.launcherFactory();
        duel = system.duel();
        lens = system.lens();
        assertGt(address(lens).code.length, 0, "system deploys the order book lens");
        vm.deal(HUB, 1 ether);
        vm.prank(HUB);
        launcher.newLauncher{value: 0.01 ether}(address(this), abi.encode(init));
        cards = MintAICards(payable(launcher.cards()));
        assertTrue(cards.saltLocked(), "creation locks the salt");
        assertEq(factory.duel(), address(duel), "vault factory deploys the duel");
        assertEq(duel.cards(), address(cards), "duel is bound when the launcher is created");
        assertEq(launcher.factorySpecVersion(), "lf-v1");
        assertEq(factory.factorySpecVersion(), "pl-v1");
    }

    function _id(address who) internal {
        AgentIdStub(AGENT_ID).set(who, 1);
    }

    function _quote(uint256 count) internal view returns (uint256) {
        return cards.priceOf(cards.paidMinted() + 1) * count;
    }

    function _mint(address who, uint256 count) internal returns (uint256 paid) {
        _id(who);
        paid = _quote(count);
        vm.deal(who, who.balance + paid);
        uint256 minOut = cards.launched() ? 1 : 0;
        vm.prank(who);
        cards.mint{value: paid}(count, minOut);
    }

    /// @dev The batch is an external call so via_ir does not inline the mint into every caller.
    function fillPresaleBatch() external {
        require(msg.sender == address(this));
        uint256 count = 20_000 - cards.paidMinted();
        if (count > 10) count = 10;
        _mint(address(uint160(0xA000 + cards.paidMinted() / 10)), count);
    }

    function _sellOutPresale() internal {
        while (cards.paidMinted() < 20_000) this.fillPresaleBatch();
    }

    function _launch() internal {
        if (!cards.launched()) _sellOutPresale();
        assertEq(MockPortal(HUB).lastExtensionID(), keccak256("flap.extension.creator.v1"));
        assertEq(abi.decode(MockPortal(HUB).lastExtensionData(), (address)), address(this));
        vault = MintAIVault(payable(cards.vault()));
        assertEq(address(vault.duel()), address(duel), "vault points at the factory duel");
        assertEq(duel.vault(), address(vault), "duel points at the launched vault");
    }

    function _token() internal view returns (IERC20) {
        return IERC20(cards.launchedToken());
    }

    /// @dev Tokens that vest from a post-open mint of `count` cards at the mock router's current rate.
    function _expectedVest(uint256 count) internal view returns (uint256 vested, uint256 burned) {
        uint256 spend = cards.MINT_PRICE() * count * 7_500 / 10_000;
        uint256 bought = spend * router.rate() / 1 ether;
        bought -= bought * 200 / 10_000;
        burned = bought * 1_000 / 10_000;
        vested = bought - burned;
    }

    function _pageTokens(address who, uint256 rows)
        internal
        view
        returns (uint256 total, uint256 claimed, uint256 claimable, uint256 locked)
    {
        for (uint256 from; from < rows; from += 500) {
            (uint256 pageTotal, uint256 pageClaimed, uint256 pageClaimable, uint256 pageLocked) =
                vault.tokensOf(who, from, 500);
            total += pageTotal;
            claimed += pageClaimed;
            claimable += pageClaimable;
            locked += pageLocked;
        }
    }

    function _assertCardsBook() internal view {
        uint256 parts = cards.presaleEscrow() + cards.dividendLiability() + cards.pendingDividend()
            + cards.streamRemaining() + cards.sideStreamRemaining() + cards.opsOwed() + cards.bidEscrow()
            + cards.proceedsLiability();
        assertEq(cards.booked(), parts, "card book");
        assertGe(address(cards).balance, cards.booked(), "card balance covers book");
    }

    function _assertVaultBook() internal view {
        assertGe(
            address(vault).balance,
            vault.floorFund() + vault.triggerReserve() + vault.duelBudget(),
            "vault BNB covers fund + reserve + duel budget"
        );
        assertGe(_token().balanceOf(address(vault)), vault.boughtOwed(), "vault holds every owed bought token");
        assertLe(vault.bucketReleased(P.BUCKET_GRANT), P.GRANT_BUDGET, "grant bucket");
        assertLe(vault.bucketReleased(P.BUCKET_LADDER), P.LADDER_BUDGET, "ladder bucket");
    }

    function _ids1(uint256 id) internal pure returns (uint256[] memory ids) {
        ids = new uint256[](1);
        ids[0] = id;
    }

    function _range(uint256 from, uint256 to) internal pure returns (uint256[] memory ids) {
        ids = new uint256[](to - from + 1);
        for (uint256 i; i < ids.length; ++i) ids[i] = from + i;
    }

    function _list(uint256 id, uint256 price) internal {
        uint256[] memory prices = new uint256[](1);
        prices[0] = price;
        vm.prank(cards.ownerOf(id));
        cards.list(_ids1(id), prices);
    }

    function _trigger() internal pure returns (MockTrigger) {
        return MockTrigger(TRIGGER);
    }

    /// @dev Fill the trigger reserve to the waterline (and book the first run), so later floor shares all reach
    ///      the floor fund.
    function _primeTrigger() internal {
        uint256 need = vault.TRIGGER_WATERLINE() - vault.triggerReserve() + _trigger().getFee();
        vm.deal(address(this), address(this).balance + need);
        vault.fundTrigger{value: need}();
    }

    /// @dev Tax worth `tax` BNB arrives and is synced; with a primed reserve the floor fund grows by 20%.
    function _fundFloor(uint256 tax) internal {
        if (vault.triggerReserve() < vault.TRIGGER_WATERLINE()) _primeTrigger();
        vm.deal(address(vault), address(vault).balance + tax);
        vault.sync();
    }

    /// @dev Run the booked Flap Trigger request the way the live service does (2,000,000 gas).
    function _fire() internal returns (uint256 used) {
        uint256 id = vault.pendingTriggerId();
        assertGt(id, 0, "a trigger is booked");
        if (block.timestamp < vault.triggerDueAt()) vm.warp(vault.triggerDueAt());
        bool ok;
        (ok, used) = _trigger().fire(id);
        assertTrue(ok, "trigger callback succeeds within 2,000,000 gas");
    }

    function _guardian() internal view returns (address) {
        return LaunchVaultAddresses.guardian();
    }
}
