// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MintAIBase} from "./MintAIBase.sol";
import {MintAICards} from "../src/MintAICards.sol";
import {MintAICardMarket} from "../src/MintAICardMarket.sol";
import {MintAICardsBase} from "../src/MintAICardsBase.sol";
import {MintAIVault} from "../src/MintAIVault.sol";
import {MintAIVaultFactory} from "../src/MintAIVaultFactory.sol";
import {MintAILauncherFactory, MintAISystemDeployer} from "../src/MintAILauncherFactory.sol";
import {MintAIParams as P} from "../src/MintAIParams.sol";
import {MockAntiScam, MockDock, MockPair, MockPortal} from "./MintAIMocks.sol";

contract MintAILedgerTest is MintAIBase {
    function setUp() public {
        _setUpLocal();
    }

    // ---------------------------------------------------------------- parameters

    function test_ledger_pricesAndBudgets() public view {
        assertEq(cards.priceOf(1), 0.00245 ether);
        assertEq(cards.priceOf(20_000), 0.00245 ether);
        assertEq(cards.priceOf(20_001), 0.0049 ether);
        assertEq(cards.priceOf(738_889), 0.0049 ether);
        assertEq(cards.priceOf(1) * 20_000, 49 ether, "presale is 49 BNB");
        assertEq(cards.priceOf(20_000), 0.00245 ether);
        assertEq(cards.PAID_CAP() + 38_888, 777_777, "777,777 cards");
        assertEq(cards.PAID_CAP() / 19, 38_888, "one team card per 19 paid");
        assertEq(P.CARD_GRANT, 8_440 ether);
        assertEq(P.GRANT_BUDGET, 497_014_720 ether, "(20,000 + 38,888) x 8,440");
        assertEq(P.LADDER_BUDGET, 58_611_119 ether);
        assertEq(P.UNALLOCATED, 97_479_938 ether);
        assertEq(P.GRANT_BUDGET + P.LADDER_BUDGET + P.UNALLOCATED, P.RESERVE);
        assertEq(P.POOL_TOKEN + P.RESERVE, 777_777_777 ether);
        assertEq(P.DIVIDEND_BPS + P.FLOOR_BPS + P.OPS_BPS, 10_000);
        uint256 rungSum;
        for (uint256 r; r < 3; ++r) rungSum += P.ladderRungTokens(r);
        assertEq(rungSum, P.LADDER_BUDGET);
        assertEq(cards.presaleDeadline(), block.timestamp + 7 days);
        assertEq(cards.MAX_MINTS(), 10);
        assertEq(cards.AGENT_ID_NFT(), AGENT_ID);
        assertEq(cards.name(), "MINT.AI");
        assertEq(cards.symbol(), "MINT.AI");
        assertEq(cards.portal(), HUB);
        assertEq(factory.FLOOR_MULTIPLIER_BPS(), 5_000);
        assertTrue(address(launcher) != address(factory), "launcher and vault factory are different contracts");
        assertEq(launcher.factorySpecVersion(), "lf-v1");
        assertEq(factory.factorySpecVersion(), "pl-v1");
        assertEq(factory.tokenCreationPolicies()[0].operator, "eq");
        assertEq(factory.tokenCreationPolicies()[5].operator, "eq");
    }

    // ---------------------------------------------------------------- presale

    function test_ledger_presaleLocksExactPayment() public {
        address a = makeAddr("a");
        uint256 paid = _mint(a, 10);
        _mint(makeAddr("b"), 9);
        assertEq(paid, 10 * 0.00245 ether);
        assertEq(cards.paidMinted(), 19);
        assertEq(cards.teamUnlocked(), 1);
        assertEq(cards.presaleEscrow(), 19 * 0.00245 ether);
        assertEq(address(cards).balance, cards.presaleEscrow());
        assertEq(cards.totalWeight(), 19);
        assertEq(cards.presaleCards(a), 10);
        assertEq(ops.balance, 0, "ops gets nothing before launch");
        _assertCardsBook();
    }

    function test_ledger_wrongPaymentReverts() public {
        address a = makeAddr("a");
        _id(a);
        vm.deal(a, 1 ether);
        vm.prank(a);
        vm.expectRevert(abi.encodeWithSelector(MintAICardsBase.WrongPayment.selector, 0.0049 ether, 0.0049 ether + 1));
        cards.mint{value: 0.0049 ether + 1}(2, 0);
        vm.prank(a);
        vm.expectRevert(MintAICardsBase.BadCount.selector);
        cards.mint{value: 0}(0, 0);
        vm.prank(a);
        vm.expectRevert(MintAICardsBase.BadCount.selector);
        cards.mint{value: 11 * 0.00245 ether}(11, 0);
    }

    function test_ledger_presaleCannotOverfill() public {
        uint256 n;
        while (cards.paidMinted() < 19_995) {
            uint256 count = 19_995 - cards.paidMinted();
            if (count > 10) count = 10;
            _mint(address(uint160(0xA100 + n)), count);
            ++n;
        }
        address late = makeAddr("late");
        _id(late);
        vm.deal(late, 1 ether);
        vm.prank(late);
        vm.expectRevert(MintAICardsBase.PresaleFull.selector);
        cards.mint{value: 10 * 0.00245 ether}(10, 0);
    }

    function test_ledger_refundReturnsEveryWeiAndKeepsTheQuota() public {
        address a = makeAddr("a");
        uint256 paid = _mint(a, 10);
        vm.warp(block.timestamp + 7 days + 1);
        uint256 before = a.balance;
        vm.prank(a);
        cards.refund(_range(1, 10));
        assertEq(a.balance - before, paid);
        assertEq(address(cards).balance, 0);
        assertEq(cards.booked(), 0);
        assertEq(cards.totalWeight(), 0);
        assertEq(cards.mintsUsed(a), 10, "burning does not restore the quota");
        vm.prank(a);
        vm.expectRevert(MintAICardsBase.MintCapReached.selector);
        cards.mint{value: 0.00245 ether}(1, 0);
        _assertCardsBook();
    }

    // ---------------------------------------------------------------- launch

    function test_ledger_launchSplitsFortyNineAndDocksTheReserve() public {
        uint256 opsBefore = ops.balance;
        _launch();
        assertEq(ops.balance - opsBefore, 12.25 ether, "25% of the presale to ops");
        assertEq(address(cards).balance, 0);
        assertEq(cards.booked(), 0);
        assertEq(vault.launcher(), address(this), "push rights stay with the owner");
        assertEq(
            MockDock(DOCK).balanceOf(cards.launchedToken(), address(vault)),
            P.GRANT_BUDGET + P.LADDER_BUDGET,
            "grant and ladder docked"
        );
        assertEq(
            _token().balanceOf(address(0x000000000000000000000000000000000000dEaD)),
            P.UNALLOCATED,
            "unallocated burned"
        );
        assertEq(vault.bucketLeft(P.BUCKET_GRANT), P.GRANT_BUDGET);
        assertEq(vault.bucketLeft(P.BUCKET_LADDER), P.LADDER_BUDGET);
        assertEq(vault.launchTime(), block.timestamp);
        (uint112 r0, uint112 r1,) = MockPair(cards.launchedPool()).getReserves();
        uint256 quote = MockPair(cards.launchedPool()).tokenIs0() ? uint256(r1) : uint256(r0);
        assertEq(quote, P.POOL_QUOTE);
        assertTrue(cards.launched());
        _assertCardsBook();
        _assertVaultBook();
    }

    // ---------------------------------------------------------------- vesting

    function test_ledger_presaleGrantVestsLinearlyOverFiveDaysFromLaunch() public {
        _sellOutPresale();
        address a = address(uint160(0xA000));
        assertEq(cards.presaleCards(a), 10);
        _launch();

        (uint256 total, uint256 claimed, uint256 claimable, uint256 locked) = vault.tokensOf(a);
        assertEq(total, 84_400 ether, "10 cards x 8,440");
        assertEq(claimable, 16_880 ether, "one fifth is already out at the launch second");
        assertEq(claimed, 0);
        assertEq(locked, 67_520 ether);
        vm.prank(a);
        vault.claimTokens(0, 0);
        assertEq(_token().balanceOf(a), 16_880 ether);

        vm.warp(block.timestamp + 1 days);
        vm.prank(a);
        vault.claimTokens(0, 0);
        assertEq(_token().balanceOf(a), 30_384 ether, "day 1: 1,688 plus one fifth of the remainder");

        vm.warp(block.timestamp + 1.5 days);
        vm.prank(a);
        vault.claimTokens(0, 0);
        assertEq(_token().balanceOf(a), 50_640 ether, "day 2.5");

        vm.warp(block.timestamp + 10 days);
        vm.prank(a);
        vault.claimTokens(0, 0);
        assertEq(_token().balanceOf(a), 84_400 ether, "all after 5 days");
        (, claimed, claimable, locked) = vault.tokensOf(a);
        assertEq(claimed, 84_400 ether);
        assertEq(claimable + locked, 0);
        vm.prank(a);
        vm.expectRevert(MintAIVault.NothingToClaim.selector);
        vault.claimTokens(0, 0);
        assertEq(vault.bucketReleased(P.BUCKET_GRANT), 84_400 ether);
        _assertVaultBook();
    }

    function test_ledger_buyerClaimsPresaleAndARepeatDoesNotPayTwice() public {
        _sellOutPresale();
        assertEq(factory.presaleBuyerCount(), 2_000, "one entry per buyer, in purchase order");
        address first = address(uint160(0xA000));
        assertEq(factory.presaleBuyer(0), first);
        _launch();
        assertEq(vault.launcher(), address(this));
        assertEq(_token().balanceOf(first), 0, "launch does not send the buyer's tokens");

        vm.prank(first);
        vault.claimTokens(0, 0);
        assertEq(_token().balanceOf(first), 16_880 ether, "10 cards, the launch fifth");
        vm.prank(first);
        vm.expectRevert(MintAIVault.NothingToClaim.selector);
        vault.claimTokens(0, 0);

        vm.warp(block.timestamp + 5 days);
        vm.prank(first);
        vault.claimTokens(0, 0);
        assertEq(_token().balanceOf(first), 84_400 ether, "the buyer claims the rest");
        vm.prank(first);
        vm.expectRevert(MintAIVault.NothingToClaim.selector);
        vault.claimTokens(0, 0);
        _assertVaultBook();
    }

    function test_ledger_tokensStayWithTheAddressWhenTheCardMoves() public {
        _sellOutPresale();
        _launch();
        address a = address(uint160(0xA000));
        address b = makeAddr("b");
        vm.prank(a);
        cards.transferFrom(a, b, 1);
        vm.warp(block.timestamp + 5 days);
        vm.prank(b);
        vm.expectRevert(MintAIVault.NothingToClaim.selector);
        vault.claimTokens(0, 0);
        vm.prank(a);
        vault.claimTokens(0, 0);
        assertEq(_token().balanceOf(a), 84_400 ether, "seller keeps the full grant");
    }

    function test_ledger_postOpenMintBuysBurnsTenAndVestsNinety() public {
        _sellOutPresale();
        _launch();
        address buyer = makeAddr("buyer");
        uint256 opsBefore = ops.balance;
        uint256 deadBefore = _token().balanceOf(DEAD);
        (uint256 expVested, uint256 expBurned) = _expectedVest(1);
        (uint256 quoteTotal, uint256 quoteTokens) = lens.quoteMint(address(cards), 1);
        uint256 paid = _mint(buyer, 1);

        assertEq(paid, 0.0049 ether);
        assertEq(quoteTotal, paid);
        assertApproxEqAbs(quoteTokens, expVested, 1 ether, "lens estimate");
        assertEq(ops.balance - opsBefore, 0.001225 ether, "25% ops");
        assertEq(vault.totalMintBnb(), 0.003675 ether, "75% buys tokens");
        assertEq(_token().balanceOf(DEAD) - deadBefore, expBurned, "10% burned");
        assertEq(vault.boughtOwed(), expVested, "90% vests");
        assertEq(_token().balanceOf(address(vault)), expVested);
        assertEq(_token().balanceOf(buyer), 0, "nothing liquid at mint");
        assertEq(cards.balanceOf(buyer), 1);
        assertEq(cards.totalWeight(), 20_001);
        assertEq(address(vault).balance, 0, "vault keeps no BNB");
        // 0.003675 BNB at the opening price, minus 2% tax, 90% vests = 10,996.07
        assertApproxEqAbs(expVested, 10_996.07 ether, 0.01 ether);

        vm.warp(block.timestamp + 1 days);
        vm.prank(buyer);
        vault.claimTokens(0, 0);
        assertEq(_token().balanceOf(buyer), expVested / 5, "a fifth after one day");
        vm.warp(block.timestamp + 4 days);
        vm.prank(buyer);
        vault.claimTokens(0, 0);
        assertEq(_token().balanceOf(buyer), expVested, "all after five days");
        assertEq(vault.boughtOwed(), 0);
        assertEq(vault.bucketReleased(P.BUCKET_GRANT), 0, "bought tokens never touch the reserve");
        _assertCardsBook();
        _assertVaultBook();
    }

    function test_ledger_mintAmountIsFixedAtMintPrice() public {
        _sellOutPresale();
        _launch();
        address early = makeAddr("early");
        address late = makeAddr("late");
        (uint256 v1,) = _expectedVest(2);
        _mint(early, 2);
        router.setRate(router.rate() / 2);
        (uint256 v2,) = _expectedVest(2);
        _mint(late, 2);
        assertApproxEqAbs(v2 * 2, v1, 2, "price doubled, half the tokens");
        router.setRate(router.rate() * 10);
        vm.warp(block.timestamp + 5 days);
        vm.prank(early);
        vault.claimTokens(0, 0);
        vm.prank(late);
        vault.claimTokens(0, 0);
        assertEq(_token().balanceOf(early), v1, "later price moves change nothing");
        assertEq(_token().balanceOf(late), v2);
    }

    function test_ledger_slippageGuardRevertsTheWholeMint() public {
        _sellOutPresale();
        _launch();
        address buyer = makeAddr("buyer");
        _id(buyer);
        (uint256 v,) = _expectedVest(3);
        vm.deal(buyer, 1 ether);
        vm.prank(buyer);
        vm.expectRevert(abi.encodeWithSelector(MintAIVault.Slippage.selector, v, v + 1));
        cards.mint{value: 3 * 0.0049 ether}(3, v + 1);
        assertEq(cards.mintsUsed(buyer), 0, "quota untouched");
        assertEq(cards.paidMinted(), 20_000);
        vm.prank(buyer);
        cards.mint{value: 3 * 0.0049 ether}(3, v);
        assertEq(vault.boughtOwed(), v);
    }

    function test_ledger_eachMintVestsFromItsOwnTime() public {
        _sellOutPresale();
        _launch();
        address a = makeAddr("a");
        (uint256 v,) = _expectedVest(1);
        _mint(a, 1);
        vm.warp(block.timestamp + 2.5 days);
        _mint(a, 1);
        assertEq(vault.vestCount(a), 2);
        vm.warp(block.timestamp + 2.5 days);
        vm.prank(a);
        vault.claimTokens(0, 0);
        assertEq(_token().balanceOf(a), v + v / 2, "first done, second half way");
        vm.warp(block.timestamp + 2.5 days);
        vm.prank(a);
        vault.claimTokens(1, 1);
        assertEq(_token().balanceOf(a), 2 * v, "paged claim of schedule #1");
    }

    function test_ledger_teamCardsUnlockEveryNineteenAndVestFromTheirMint() public {
        vm.prank(team);
        vm.expectRevert(MintAICardsBase.NotLaunched.selector);
        cards.mintTeam(team, 1);
        _sellOutPresale();
        _launch();
        assertEq(cards.teamUnlocked(), 1_052);
        vm.prank(makeAddr("x"));
        vm.expectRevert(MintAICardsBase.NotTeam.selector);
        cards.mintTeam(team, 1);
        for (uint256 i; i < 10; ++i) {
            vm.prank(team);
            cards.mintTeam(team, 100);
        }
        vm.prank(team);
        cards.mintTeam(team, 52);
        vm.prank(team);
        vm.expectRevert(MintAICardsBase.TeamNotUnlocked.selector);
        cards.mintTeam(team, 1);
        assertEq(cards.balanceOf(team), 1_052);
        assertTrue(cards.isTeamCard(cards.lastTokenId()));

        for (uint256 i; i < 6; ++i) _mint(address(uint160(0xC000 + i)), 1);
        assertEq(cards.teamUnlocked(), 1_052, "20,006 / 19 = 1,052.9");
        _mint(makeAddr("c7"), 1);
        assertEq(cards.teamUnlocked(), 1_053, "the 20,007th paid card unlocks team card 1,053");
        vm.warp(block.timestamp + 1 days);
        vm.prank(team);
        cards.mintTeam(team, 1);

        (uint256 total,, uint256 claimable,) = _pageTokens(team, vault.vestCount(team));
        assertEq(total, 1_053 * 8_440 ether);
        assertEq(
            claimable,
            1_053 * (8_440 ether / 5 + 6_752 ether / 5),
            "one day after launch: one fifth up front, plus one fifth of the rest"
        );
        vm.warp(block.timestamp + 5 days);
        uint256 got;
        for (uint256 from; from < 1_053; from += 500) {
            vm.prank(team);
            got += vault.claimTokens(from, 500);
        }
        assertEq(got, 1_053 * 8_440 ether);
        assertEq(_token().balanceOf(team), 1_053 * 8_440 ether);
        assertEq(cards.totalWeight(), 20_007 + 1_053);
        _assertVaultBook();
    }

    function test_ledger_teamClockStartsAtLaunchNotDuringPresale() public {
        _mint(makeAddr("early"), 10);
        _mint(makeAddr("early2"), 9);
        assertEq(cards.teamUnlockAt(1), block.timestamp);
        vm.warp(block.timestamp + 6 days);
        _sellOutPresale();
        _launch();
        vm.prank(team);
        cards.mintTeam(team, 1);
        (uint256 total,, uint256 claimable, uint256 locked) = vault.tokensOf(team);
        assertEq(total, 8_440 ether);
        assertEq(claimable, 8_440 ether / 5, "six presale days do not count; launch still releases one fifth");
        assertEq(locked, total - claimable);
        vm.warp(block.timestamp + 5 days);
        (, , claimable, locked) = vault.tokensOf(team);
        assertEq(claimable, total);
        assertEq(locked, 0);
    }

    function test_ledger_teamClockStartsAtUnlockAndSplitsAcrossWallets() public {
        _sellOutPresale();
        uint256 unlockedAt = block.timestamp;
        assertEq(cards.teamUnlockAt(1), unlockedAt);
        assertEq(cards.teamUnlockAt(1_052), unlockedAt);
        vm.warp(unlockedAt + 6 days);
        _launch();
        address a = makeAddr("teamA");
        address b = makeAddr("teamB");
        vm.prank(team);
        cards.mintTeam(a, 30);
        vm.prank(team);
        cards.mintTeam(b, 10);
        assertEq(cards.balanceOf(a), 30);
        assertEq(cards.balanceOf(b), 10);
        assertEq(cards.ownerOf(cards.lastTokenId() - 10), a);
        assertEq(cards.ownerOf(cards.lastTokenId()), b);
        (uint256 totalA,, uint256 claimA,) = vault.tokensOf(a);
        (uint256 totalB,, uint256 claimB,) = vault.tokensOf(b);
        (uint256 totalTeam,,,) = vault.tokensOf(team);
        assertEq(totalA, 30 * 8_440 ether);
        assertEq(claimA, 30 * 8_440 ether, "six days after launch, the grant is already fully released");
        assertEq(totalB, 10 * 8_440 ether);
        assertEq(claimB, 10 * 8_440 ether);
        assertEq(totalTeam, 0, "the team wallet keeps nothing it did not receive");
        vm.prank(team);
        vm.expectRevert(MintAICardsBase.ZeroAddress.selector);
        cards.mintTeam(address(0), 1);
    }

    // ---------------------------------------------------------------- tax and dividends

    function test_ledger_taxSplitFiftyFloorThirtyOpsTwenty() public {
        _sellOutPresale();
        _launch();
        uint256 weight = cards.totalWeight();
        assertEq(weight, 20_000);
        vm.deal(address(vault), 1 ether);
        uint256 opsBefore = ops.balance;
        vault.sync();
        assertEq(cards.opsOwed(), 0.2 ether, "ops share waits for the next push");
        cards.poke();
        assertEq(vault.unrecognizedTax(), 0);
        assertEq(vault.totalTaxRevenue(), 1 ether);
        assertEq(vault.totalFloorForwarded(), 0.3 ether, "30% floor share");
        assertEq(vault.floorFund(), 0.28 ether, "the floor share first fills the 0.02 BNB trigger reserve");
        assertEq(vault.triggerReserve(), 0.02 ether - 0.0002 ether, "and the first trigger run is paid from it");
        assertGt(vault.pendingTriggerId(), 0);
        assertEq(address(vault).balance, vault.floorFund() + vault.triggerReserve() + vault.duelBudget());
        assertEq(ops.balance - opsBefore, 0.2 ether, "20% ops");
        assertEq(cards.totalDividendIn(), 0.5 ether, "50% dividend");
        assertApproxEqAbs(cards.pendingDividendOf(1) * weight, 0.5 ether, weight, "equal share");
        uint256 before = address(uint160(0xA000)).balance;
        vm.prank(address(uint160(0xA000)));
        cards.claim(_range(1, 10));
        assertEq(address(uint160(0xA000)).balance - before, 10 * (uint256(0.5 ether) / weight));
        _assertCardsBook();
        _assertVaultBook();
    }

    function test_ledger_newCardsDoNotShareEarlierRevenue() public {
        _sellOutPresale();
        _launch();
        vm.deal(address(vault), 1 ether);
        vault.sync();
        address late = makeAddr("late");
        _mint(late, 1);
        assertEq(cards.pendingDividendOf(20_001), 0);
        vm.deal(address(vault), address(vault).balance + 1 ether);
        vault.sync();
        assertApproxEqAbs(cards.pendingDividendOf(20_001), uint256(0.5 ether) / 20_001, 1);
        _assertCardsBook();
    }

    function test_ledger_teamCardsDoNotShareEarlierRevenue() public {
        _sellOutPresale();
        _launch();
        vm.deal(address(vault), 1 ether);
        vm.prank(team);
        cards.mintTeam(team, 1);
        uint256 teamId = cards.lastTokenId();
        assertEq(cards.pendingDividendOf(teamId), 0, "the team card misses tax that was already waiting");
        assertApproxEqAbs(cards.pendingDividendOf(1), uint256(0.5 ether) / 20_000, 1);
        assertEq(vault.unrecognizedTax(), 0);
        vm.deal(address(vault), address(vault).balance + 1 ether);
        vault.sync();
        assertApproxEqAbs(cards.pendingDividendOf(teamId), uint256(0.5 ether) / 20_001, 1);
        _assertCardsBook();
    }

    function test_ledger_ladderStreamsSevenDays() public {
        _sellOutPresale();
        _launch();
        address buyer = makeAddr("buyer");
        vm.expectRevert(MintAIVault.TwapNotReady.selector);
        vault.buyLadder(0, 1 ether);
        MockPair(cards.launchedPool()).setQuote(P.POOL_QUOTE * 16 / 10);
        vm.warp(block.timestamp + 31 minutes);
        vault.poke();
        vm.warp(block.timestamp + 31 minutes);
        vault.poke();
        uint256 amount = 1_000_000 ether;
        uint256 cost = (amount * vault.rungPrice(0) + 1e18 - 1) / 1e18;
        vm.expectRevert(abi.encodeWithSelector(MintAIVault.RungNotReached.selector, vault.twapPrice(), vault.rungPrice(1)));
        vault.buyLadder(1, amount);
        vm.deal(buyer, cost + 1 ether);
        vm.prank(buyer);
        vault.buyLadder{value: cost + 1 ether}(0, amount);
        assertEq(_token().balanceOf(buyer), amount);
        assertEq(buyer.balance, 1 ether, "excess refunded");
        assertEq(cards.streamRemaining(), cost, "ladder BNB streams, none to ops or floor");
        assertEq(vault.floorFund(), 0);
        assertEq(address(vault).balance, 0);
        assertEq(vault.bucketReleased(P.BUCKET_LADDER), amount);
        vm.warp(block.timestamp + 3.5 days);
        cards.poke();
        assertApproxEqRel(cards.streamRemaining(), cost / 2, 0.001e18, "half streamed");
        vm.warp(block.timestamp + 7 days);
        cards.poke();
        assertEq(cards.streamRemaining(), 0);
        assertApproxEqAbs(cards.pendingDividendOf(1) * cards.totalWeight(), cost, cards.totalWeight() * 2);
        _assertCardsBook();
    }

    function test_ledger_laterLadderBuyKeepsTheOpenStream() public {
        _sellOutPresale();
        _launch();
        MockPair(cards.launchedPool()).setQuote(P.POOL_QUOTE * 16 / 10);
        vm.warp(block.timestamp + 31 minutes);
        vault.poke();
        vm.warp(block.timestamp + 31 minutes);
        vault.poke();
        address buyer = makeAddr("ladderBuyer");
        uint256 amount = 1_000_000 ether;
        uint256 cost = (amount * vault.rungPrice(0) + 1e18 - 1) / 1e18;
        vm.deal(buyer, cost * 2 + 1 ether);
        vm.prank(buyer);
        vault.buyLadder{value: cost}(0, amount);
        uint256 end = cards.streamEnd();
        assertEq(end, block.timestamp + 7 days);

        vm.warp(block.timestamp + 1 days);
        vault.poke();
        vm.warp(block.timestamp + 31 minutes);
        vault.poke();
        vm.warp(block.timestamp + 31 minutes);
        vault.poke();
        (uint256 sideAmount, uint256 sideCost) = _minLadder(0);
        uint256 left = cards.streamRemaining();
        vm.prank(buyer);
        vault.buyLadder{value: sideCost}(0, sideAmount);
        assertEq(cards.streamEnd(), end, "an open stream keeps its original end");
        assertLt(cards.streamRemaining(), left, "the elapsed day was released first");
        assertGt(cards.streamRemaining(), sideCost);
        assertEq(cards.sideStreamRemaining(), sideCost, "the new payment streams on its own");
        assertEq(cards.sideStreamEnd(), block.timestamp + 7 days);

        vm.warp(end);
        cards.poke();
        assertEq(cards.streamRemaining(), 0, "the original end clears the first stream");
        assertGt(cards.sideStreamRemaining(), 0, "the later payment is still streaming");
        vm.warp(cards.sideStreamEnd());
        cards.poke();
        assertEq(cards.sideStreamRemaining(), 0, "the side stream ends on its own seventh day");
        _assertCardsBook();
    }

    function test_ledger_finishedStreamStartsANewSevenDays() public {
        _sellOutPresale();
        _launch();
        MockPair(cards.launchedPool()).setQuote(P.POOL_QUOTE * 16 / 10);
        vm.warp(block.timestamp + 31 minutes);
        vault.poke();
        vm.warp(block.timestamp + 31 minutes);
        vault.poke();
        address buyer = makeAddr("ladderBuyer");
        uint256 amount = 1_000_000 ether;
        uint256 cost = (amount * vault.rungPrice(0) + 1e18 - 1) / 1e18;
        (uint256 nextAmount, uint256 nextCost) = _minLadder(0);
        vm.deal(buyer, cost + nextCost + 1 ether);
        vm.prank(buyer);
        vault.buyLadder{value: cost}(0, amount);
        vm.warp(cards.streamEnd());
        cards.poke();
        assertEq(cards.streamRemaining(), 0);

        vault.poke();
        vm.warp(block.timestamp + 31 minutes);
        vault.poke();
        vm.warp(block.timestamp + 31 minutes);
        vault.poke();
        vm.prank(buyer);
        vault.buyLadder{value: nextCost}(0, nextAmount);
        assertEq(cards.streamEnd(), block.timestamp + 7 days, "a finished stream starts a new seven days");
        assertEq(cards.streamRemaining(), nextCost);
        _assertCardsBook();
    }

    function test_ledger_dustLadderBuyDoesNotOpenOrDelayAStream() public {
        _sellOutPresale();
        _launch();
        _openLadderTwap();
        address buyer = makeAddr("ladderBuyer");
        uint256 amount = 1_000_000 ether;
        uint256 cost = (amount * vault.rungPrice(0) + 1e18 - 1) / 1e18;
        uint256 dust = (1 ether * vault.rungPrice(0) + 1e18 - 1) / 1e18;
        assertLt(dust, 0.01 ether);
        vm.deal(buyer, cost + dust);
        vm.prank(buyer);
        vault.buyLadder{value: cost}(0, amount);
        uint256 end = cards.streamEnd();

        vm.warp(vm.getBlockTimestamp() + 1 days);
        _openLadderTwap();
        vm.expectRevert(abi.encodeWithSelector(MintAICardsBase.LadderTooSmall.selector, dust));
        vm.prank(buyer);
        vault.buyLadder{value: dust}(0, 1 ether);
        assertEq(cards.streamEnd(), end, "a rejected buy does not move the stream");
        assertEq(cards.streamRemaining(), cost);
        assertEq(cards.sideStreamRemaining(), 0);
        _assertCardsBook();
    }

    function test_ledger_sideTopUpKeepsTheSideEnd() public {
        _sellOutPresale();
        _launch();
        _openLadderTwap();
        address buyer = makeAddr("ladderBuyer");
        uint256 amount = 1_000_000 ether;
        uint256 cost = (amount * vault.rungPrice(0) + 1e18 - 1) / 1e18;
        (uint256 sideAmount, uint256 sideCost) = _minLadder(0);
        (uint256 topAmount, uint256 topCost) = _minLadder(0);
        vm.deal(buyer, cost + sideCost + topCost);
        vm.prank(buyer);
        vault.buyLadder{value: cost}(0, amount);
        uint256 mainEnd = cards.streamEnd();

        vm.warp(vm.getBlockTimestamp() + 1 days);
        _openLadderTwap();
        vm.prank(buyer);
        vault.buyLadder{value: sideCost}(0, sideAmount);
        uint256 sideEnd = cards.sideStreamEnd();
        assertEq(sideEnd, vm.getBlockTimestamp() + 7 days);
        assertEq(cards.streamEnd(), mainEnd);

        vm.warp(vm.getBlockTimestamp() + 1 days);
        _openLadderTwap();
        uint256 left = cards.sideStreamRemaining();
        vm.prank(buyer);
        vault.buyLadder{value: topCost}(0, topAmount);
        assertEq(cards.sideStreamEnd(), sideEnd, "the remaining side balance is not spread out for another 7 days");
        assertLt(cards.sideStreamEnd(), vm.getBlockTimestamp() + 7 days);
        assertGt(cards.sideStreamRemaining(), topCost);
        assertLt(cards.sideStreamRemaining(), left + topCost, "time already elapsed was released before the top-up");
        assertEq(cards.streamEnd(), mainEnd, "the main stream end stays put");

        vm.warp(sideEnd);
        cards.poke();
        assertEq(cards.sideStreamRemaining(), 0, "old and new side money both finish on the original side end");
        _assertCardsBook();
    }

    function test_ledger_pendingDividendCountsTheSideStream() public {
        _sellOutPresale();
        _launch();
        _openLadderTwap();
        address buyer = makeAddr("ladderBuyer");
        uint256 amount = 1_000_000 ether;
        uint256 cost = (amount * vault.rungPrice(0) + 1e18 - 1) / 1e18;
        (uint256 sideAmount, uint256 sideCost) = _minLadder(0);
        vm.deal(buyer, cost + sideCost);
        vm.prank(buyer);
        vault.buyLadder{value: cost}(0, amount);
        vm.warp(vm.getBlockTimestamp() + 1 days);
        _openLadderTwap();
        vm.prank(buyer);
        vault.buyLadder{value: sideCost}(0, sideAmount);
        vm.warp(vm.getBlockTimestamp() + 1 days);

        uint256 nowTs = vm.getBlockTimestamp();
        uint256 sideDue = _streamedDue(cards.sideStreamLast(), cards.sideStreamEnd(), cards.sideStreamRemaining(), cards.sideStreamRate(), nowTs);
        uint256 mainDue = _streamedDue(cards.streamLast(), cards.streamEnd(), cards.streamRemaining(), cards.streamRate(), nowTs);
        assertGt(sideDue, 0, "a day of the side stream is waiting");
        assertGt(mainDue, 0, "the main stream is still paying");
        uint256 weight = cards.totalWeight();
        uint256 acc = cards.accRewardPerShare();
        uint256 debt = cards.rewardDebt(1);
        uint256 pending = cards.pendingDividend();
        uint256 mainOnly = (acc + (pending + mainDue) * 1e18 / weight - debt) / 1e18;
        uint256 shown = cards.pendingDividendOf(1);
        assertGt(shown, mainOnly, "the side stream is included before it is claimed");
        address holder = cards.ownerOf(1);
        uint256 before = holder.balance;
        vm.prank(holder);
        cards.claim(_ids1(1));
        assertEq(holder.balance - before, shown, "the view matches what claim pays, including the side stream");
        _assertCardsBook();
    }

    function test_ledger_floorKeepsVestedUnclaimedTokens() public {
        _sellOutPresale();
        _launch();
        _fundFloor(1 ether);
        address bob = makeAddr("bob");
        (uint256 vested,) = _expectedVest(1);
        _mint(bob, 1);
        uint256 id = cards.lastTokenId();

        vm.warp(block.timestamp + 1 days);
        (, uint256 forfeit) = vault.floorLimit(id, bob);
        uint256 vestedNow = vested / 5;
        assertEq(forfeit, vested - vestedNow, "only the locked four days would burn");
        _list(id, 0.0049 ether);
        uint256 deadBefore = _token().balanceOf(DEAD);
        assertEq(vault.sweepFloor(), 1);
        assertEq(_token().balanceOf(DEAD) - deadBefore, vested - vestedNow);
        uint256 got = _claim(bob);
        assertEq(got, vestedNow, "the vested day stays claimable");
        _assertVaultBook();
    }

    function test_ledger_staleTwapDoesNotOpenARung() public {
        _sellOutPresale();
        _launch();
        MockPair(cards.launchedPool()).setQuote(P.POOL_QUOTE * 2);
        vm.warp(block.timestamp + 2 hours);
        address buyer = makeAddr("staleBuyer");
        (uint256 amount, uint256 cost) = _minLadder(0);
        vm.deal(buyer, cost);
        vm.expectRevert(MintAIVault.TwapNotReady.selector);
        vm.prank(buyer);
        vault.buyLadder{value: cost}(0, amount);

        vault.poke();
        (uint32 resetAt,) = vault.obsNew();
        assertEq(resetAt, uint32(block.timestamp), "a stale poke starts the window over");
        vm.expectRevert(MintAIVault.TwapNotReady.selector);
        vm.prank(buyer);
        vault.buyLadder{value: cost}(0, amount);

        vm.warp(block.timestamp + 31 minutes);
        vault.poke();
        vm.prank(buyer);
        vault.buyLadder{value: cost}(0, amount);
        assertEq(_token().balanceOf(buyer), amount);
        _assertCardsBook();
    }

    // ---------------------------------------------------------------- market

    function test_ledger_marketPaysSellerDividendAndOnePercent() public {
        address a = address(uint160(0xA000));
        _sellOutPresale();
        _launch();
        vm.deal(address(vault), 1 ether);
        vault.sync();
        cards.poke();
        uint256 dividend = cards.pendingDividendOf(1);
        assertGt(dividend, 0);
        _list(1, 0.01 ether);
        address b = makeAddr("b");
        vm.deal(b, 0.01 ether);
        uint256 sellerBefore = a.balance;
        uint256 opsBefore = ops.balance;
        uint256[] memory prices = new uint256[](1);
        prices[0] = 0.01 ether;
        vm.prank(b);
        cards.buy{value: 0.01 ether}(_ids1(1), prices);
        assertEq(cards.ownerOf(1), b);
        assertEq(a.balance - sellerBefore, 0.0099 ether + dividend);
        assertEq(ops.balance - opsBefore, 0.0001 ether);
        assertEq(cards.pendingDividendOf(1), 0);
        assertEq(cards.tickCount(1_000), 0, "sold listing leaves the tick book");
        _assertCardsBook();
    }

    function test_ledger_listPricesAreTicksAndTheBookTracksThem() public {
        _sellOutPresale();
        _launch();
        address a = cards.ownerOf(1);
        uint256[] memory prices = new uint256[](1);
        uint256[3] memory bad = [uint256(0), 0.000015 ether, 10.48576 ether];
        for (uint256 i; i < 3; ++i) {
            prices[0] = bad[i];
            vm.prank(a);
            vm.expectRevert(MintAICardsBase.BadPrice.selector);
            cards.list(_ids1(1), prices);
        }
        _list(1, 0.004 ether);
        _list(2, 0.004 ether);
        _list(11, 0.003 ether);
        (uint256 floorPrice, uint256 at) = lens.floor(address(cards));
        assertEq(floorPrice, 0.003 ether);
        assertEq(at, 1);
        _list(11, 0.005 ether);
        (floorPrice, at) = lens.floor(address(cards));
        assertEq(floorPrice, 0.004 ether, "relisting moves the card to its new tick");
        assertEq(at, 2);
        vm.prank(a);
        cards.transferFrom(a, makeAddr("z"), 1);
        (, at) = lens.floor(address(cards));
        assertEq(at, 1, "a transfer clears the listing");
        vm.prank(a);
        cards.unlist(_ids1(2));
        (floorPrice, at) = lens.floor(address(cards));
        assertEq(floorPrice, 0.005 ether);
        assertEq(at, 1);
        vm.prank(cards.ownerOf(11));
        cards.unlist(_ids1(11));
        (floorPrice, at) = lens.floor(address(cards));
        assertEq(floorPrice + at, 0, "empty book");
    }

    // ---------------------------------------------------------------- floor fund

    function test_ledger_floorBuysCheapestFirstAndBurns() public {
        _sellOutPresale();
        _launch();
        _fundFloor(0.02 ether);
        assertEq(vault.floorFund(), 0.006 ether);
        _list(1, 0.0015 ether);
        _list(2, 0.0015 ether);
        _list(11, 0.0018 ether);
        _list(21, 0.002 ether);

        address seller = cards.ownerOf(1);
        uint256 dividend = cards.pendingDividendOf(1);
        uint256 before = seller.balance;
        uint256 bought = vault.sweepFloor();
        assertEq(bought, 3, "0.0015 + 0.0015 + 0.0018 = 0.0048 <= 0.006; 0.002 does not fit");
        assertEq(seller.balance - before, 0.003 ether + 2 * dividend, "full price, no fee, plus dividend");
        assertEq(vault.floorFund(), 0.0012 ether);
        assertEq(vault.totalFloorSpent(), 0.0048 ether);
        assertEq(vault.totalFloorBurned(), 3);
        assertEq(cards.totalWeight(), 20_000 - 3);
        (address stillListed,) = cards.listings(21);
        assertTrue(stillListed != address(0), "0.002 is still listed");
        vm.expectRevert();
        cards.ownerOf(1);
        (uint256 floorPrice,) = lens.floor(address(cards));
        assertEq(floorPrice, 0.002 ether);
        assertEq(vault.sweepKey(), 0, "a finished pass starts from the floor next time");

        uint256 before5 = cards.pendingDividendOf(5);
        _fundFloor(1 ether);
        assertApproxEqAbs(
            cards.pendingDividendOf(5) - before5, uint256(0.5 ether) / 19_997, 1, "the same revenue goes to fewer cards"
        );
        _assertCardsBook();
        _assertVaultBook();
    }

    function test_ledger_floorDropsCursorForACheaperListing() public {
        _sellOutPresale();
        _launch();
        _fundFloor(0.005 ether);
        assertEq(vault.floorFund(), 0.0015 ether);
        _list(1, 0.002 ether);
        _list(2, 0.002 ether);
        uint256 tick = 0.002 ether / 0.00001 ether;
        vm.store(address(vault), bytes32(uint256(35)), bytes32(tick << 1));
        vm.store(address(vault), bytes32(uint256(36)), bytes32(uint256(1)));
        assertEq(vault.sweepKey(), tick << 1, "cursor is parked on the 0.002 tick");
        _list(4, 0.001 ether);

        assertEq(vault.sweepFloor(), 1, "the cheaper card is bought before the saved tick");
        vm.expectRevert();
        cards.ownerOf(4);
        (address still,) = cards.listings(1);
        assertTrue(still != address(0), "0.002 does not fit after the cheaper buy");
        assertEq(vault.sweepKey(), 0);
        _assertCardsBook();
        _assertVaultBook();
    }

    function test_ledger_presaleCardsHaveNoFloorLimitWhileMinting() public {
        _sellOutPresale();
        _launch();
        _fundFloor(1 ether);
        (uint256 maxPrice, uint256 forfeit) = vault.floorLimit(1, cards.ownerOf(1));
        assertEq(maxPrice, 0.00245 ether);
        assertEq(forfeit, 0);
        _list(1, 0.00246 ether);
        assertEq(vault.sweepFloor(), 0, "above the presale price is skipped");
        _list(1, 0.00245 ether);
        assertEq(vault.sweepFloor(), 1, "the presale card is bought at its own mint price");
        assertEq(vault.floorFund(), 0.29755 ether);
        assertEq(vault.totalForfeitBurned(), 0, "presale grants are never cancelled");
        _assertCardsBook();
        _assertVaultBook();
    }

    function test_ledger_teamCardsHaveNoFloorLimitAndKeepTheirGrant() public {
        _sellOutPresale();
        _launch();
        _fundFloor(1 ether);
        vm.prank(team);
        cards.mintTeam(team, 1);
        uint256 id = cards.lastTokenId();
        (uint256 maxPrice,) = vault.floorLimit(id, team);
        assertEq(maxPrice, 0.00245 ether);
        _list(id, 0.01 ether);
        assertEq(vault.sweepFloor(), 0, "a team card above 0.00245 is skipped");
        _list(id, 0.00245 ether);
        assertEq(vault.sweepFloor(), 1);
        (uint256 total,,,) = vault.tokensOf(team);
        assertEq(total, 8_440 ether, "team grants are not cancelled");
        assertEq(vault.totalForfeitBurned(), 0);
    }

    function test_ledger_floorSkipsAboveMintPriceForNewCardsButBuysPresaleThere() public {
        _sellOutPresale();
        _launch();
        _fundFloor(1 ether);
        address bob = makeAddr("bob");
        _mint(bob, 1);
        uint256 id = cards.lastTokenId();
        _list(id, 0.006 ether);
        _list(1, 0.007 ether);
        assertEq(vault.sweepFloor(), 0, "both asks are above their own caps");
        _list(1, 0.00245 ether);
        assertEq(vault.sweepFloor(), 1, "the presale card is bought at 0.00245; the dearer new card stays");
        assertEq(cards.ownerOf(id), bob);
        vm.expectRevert();
        cards.ownerOf(1);
    }

    function test_ledger_floorBuysAnUntouchedNewCardAtMintPriceAndBurnsItsTokens() public {
        _sellOutPresale();
        _launch();
        _fundFloor(1 ether);
        address bob = makeAddr("bob");
        (uint256 vested,) = _expectedVest(2);
        _mint(bob, 2);
        uint256 a = cards.lastTokenId() - 1;
        uint256 b = a + 1;
        (uint256 maxPrice, uint256 forfeit) = vault.floorLimit(a, bob);
        assertEq(forfeit, vested / 2, "one equal schedule per card");
        assertEq(maxPrice, 0.0049 ether);

        _list(a, 0.00491 ether);
        assertEq(vault.sweepFloor(), 0);

        _list(a, 0.0049 ether);
        uint256 deadBefore = _token().balanceOf(DEAD);
        uint256 owedBefore = vault.boughtOwed();
        uint256 bobBefore = bob.balance;
        uint256 dividend = cards.pendingDividendOf(a);
        assertEq(vault.sweepFloor(), 1);
        assertEq(bob.balance - bobBefore, 0.0049 ether + dividend, "seller gets the full ask");
        assertEq(_token().balanceOf(DEAD) - deadBefore, vested / 2, "the card's unclaimed tokens are burned");
        assertEq(owedBefore - vault.boughtOwed(), vested / 2);
        assertEq(vault.totalForfeitBurned(), vested / 2);
        (, forfeit) = vault.floorLimit(a, bob);
        assertEq(forfeit, 0);

        vm.warp(block.timestamp + 5 days);
        uint256 got = _claim(bob);
        assertEq(got, vested - vested / 2, "the other card keeps its tokens");
        assertEq(_token().balanceOf(bob), got);
        (uint256 total, uint256 claimed, uint256 claimable, uint256 locked) = vault.tokensOf(bob);
        assertEq(total, claimed);
        assertEq(claimable + locked, 0);
        assertEq(cards.ownerOf(b), bob);
        _assertCardsBook();
        _assertVaultBook();
    }

    function test_ledger_aClaimedCardIsCappedAt0002AndLosesTheRest() public {
        _sellOutPresale();
        _launch();
        _fundFloor(1 ether);
        address bob = makeAddr("bob");
        (uint256 vested,) = _expectedVest(2);
        _mint(bob, 2);
        uint256 a = cards.lastTokenId() - 1;
        uint256 share = vested / 2;

        vm.warp(block.timestamp + 1 days);
        vm.prank(bob);
        uint256 day1 = vault.claimTokens(0, 1);
        assertEq(day1, share / 5, "first day of card a only");
        (uint256 maxPrice, uint256 forfeit) = vault.floorLimit(a, bob);
        assertEq(forfeit, share - day1);
        assertEq(maxPrice, 0.0049 ether, "claiming does not lower the cap");
        (maxPrice,) = vault.floorLimit(a + 1, bob);
        assertEq(maxPrice, 0.0049 ether, "card b is tracked on its own");

        _list(a, 0.00491 ether);
        assertEq(vault.sweepFloor(), 0);

        _list(a, 0.0049 ether);
        uint256 deadBefore = _token().balanceOf(DEAD);
        assertEq(vault.sweepFloor(), 1);
        assertEq(_token().balanceOf(DEAD) - deadBefore, share - day1, "the remaining four days are burned");
        assertEq(_token().balanceOf(bob), day1, "claimed tokens stay with bob");

        vm.warp(block.timestamp + 5 days);
        uint256 got = _claim(bob);
        assertEq(got, vested - share, "only card b pays out");
        _assertVaultBook();
    }

    function test_ledger_aTransferredCardIsCappedAndKeepsTheMintersTokens() public {
        _sellOutPresale();
        _launch();
        _fundFloor(1 ether);
        address bob = makeAddr("bob");
        address carol = makeAddr("carol");
        (uint256 vested,) = _expectedVest(1);
        _mint(bob, 1);
        uint256 id = cards.lastTokenId();
        vm.prank(bob);
        cards.transferFrom(bob, carol, id);
        (uint256 maxPrice, uint256 forfeit) = vault.floorLimit(id, carol);
        assertEq(forfeit, vested, "the unclaimed tokens still belong to this card");
        assertEq(maxPrice, 0.0049 ether);

        _list(id, 0.00491 ether);
        assertEq(vault.sweepFloor(), 0);
        _list(id, 0.0049 ether);
        assertEq(vault.sweepFloor(), 1);
        assertEq(vault.totalForfeitBurned(), vested, "transferring the card does not keep its unclaimed tokens");

        vm.warp(block.timestamp + 5 days);
        vm.prank(bob);
        vm.expectRevert(MintAIVault.NothingToClaim.selector);
        vault.claimTokens(0, 0);
        _assertVaultBook();
    }

    function test_ledger_lockedTokensFollowTheCardOnTheOriginalClock() public {
        _sellOutPresale();
        _launch();
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        (uint256 vested,) = _expectedVest(1);
        _mint(alice, 1);
        uint256 id = cards.lastTokenId();
        (,, uint40 start,) = vault.vests(alice, 0);
        uint256 owed = vault.boughtOwed();
        vm.warp(uint256(start) + 1 days);
        uint256 released = vested * 1 days / vault.VEST_PERIOD();
        vm.prank(alice);
        cards.transferFrom(alice, bob, id);
        assertEq(vault.boughtOwed(), owed, "moving the card does not change what the vault owes");
        (address holder, uint96 slot) = vault.cardVest(id);
        assertEq(holder, bob);
        assertGt(slot, 0);

        (uint256 aliceTotal,, uint256 aliceClaimable, uint256 aliceLocked) = vault.tokensOf(alice);
        (uint256 bobTotal, uint256 bobClaimed, uint256 bobClaimable, uint256 bobLocked) = vault.tokensOf(bob);
        assertEq(aliceClaimable, released, "the unlocked day stays with alice");
        assertEq(aliceLocked, 0);
        assertEq(aliceTotal, released);
        assertEq(bobTotal - bobClaimed, vested - released, "the locked remainder is bob's");
        assertEq(bobClaimable + bobLocked, vested - released);
        (, uint256 forfeit) = vault.floorLimit(id, bob);
        assertEq(forfeit, bobLocked, "the listing can read the tokens still locked on the card");

        vm.prank(alice);
        assertEq(vault.claimTokens(0, 0), released);
        vm.warp(uint256(start) + vault.VEST_PERIOD());
        vm.prank(bob);
        assertEq(vault.claimTokens(0, 0), vested - released, "bob finishes on alice's original day 5");
        vm.prank(alice);
        vm.expectRevert(MintAIVault.NothingToClaim.selector);
        vault.claimTokens(0, 0);
        _assertVaultBook();
    }

    function test_ledger_floorBurnsOnlyTheCurrentHoldersLockedTokens() public {
        _sellOutPresale();
        _launch();
        _fundFloor(1 ether);
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        (uint256 vested,) = _expectedVest(1);
        _mint(alice, 1);
        uint256 id = cards.lastTokenId();
        (,, uint40 start,) = vault.vests(alice, 0);
        vm.warp(uint256(start) + 1 days);
        uint256 released = vested * 1 days / vault.VEST_PERIOD();
        vm.prank(alice);
        cards.transferFrom(alice, bob, id);
        _list(id, 0.0049 ether);
        assertEq(vault.sweepFloor(), 1);
        assertEq(vault.totalForfeitBurned(), vested - released, "only bob's still-locked tokens burn");
        vm.prank(alice);
        assertEq(vault.claimTokens(0, 0), released, "alice still claims the day she unlocked");
        vm.prank(bob);
        vm.expectRevert(MintAIVault.NothingToClaim.selector);
        vault.claimTokens(0, 0);
        _assertVaultBook();
    }

    function test_ledger_aFullyVestedTransferKeepsTheMintFloorPrice() public {
        _sellOutPresale();
        _launch();
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        (uint256 vested,) = _expectedVest(1);
        _mint(alice, 1);
        uint256 id = cards.lastTokenId();
        (,, uint40 start,) = vault.vests(alice, 0);
        vm.warp(uint256(start) + vault.VEST_PERIOD());
        vm.prank(alice);
        cards.transferFrom(alice, bob, id);
        (uint256 maxPrice, uint256 forfeit) = vault.floorLimit(id, bob);
        assertEq(maxPrice, 0.0049 ether, "a spent post-open card is not priced as presale");
        assertEq(forfeit, 0);
        vm.prank(alice);
        assertEq(vault.claimTokens(0, 0), vested);
        vm.prank(bob);
        vm.expectRevert(MintAIVault.NothingToClaim.selector);
        vault.claimTokens(0, 0);
        _assertVaultBook();
    }

    function test_ledger_aClaimRaceLeavesTheListingUnbought() public {
        _sellOutPresale();
        _launch();
        _fundFloor(1 ether);
        address bob = makeAddr("bob");
        _mint(bob, 1);
        uint256 id = cards.lastTokenId();
        _list(id, 0.0049 ether);
        vm.warp(block.timestamp + 1 hours);
        vm.prank(bob);
        vault.claimTokens(0, 0);
        assertEq(vault.sweepFloor(), 1, "a claimed card is still bought at 0.0049 and the remainder is burned");
        vm.expectRevert();
        cards.ownerOf(id);
    }

    function test_ledger_mintSplitsTokensEvenlyPerCard() public {
        _sellOutPresale();
        _launch();
        address bob = makeAddr("bob");
        (uint256 vested,) = _expectedVest(7);
        _mint(bob, 7);
        uint256 last = cards.lastTokenId();
        uint256 sum;
        for (uint256 id = last - 6; id <= last; ++id) {
            (uint256 maxPrice, uint256 forfeit) = vault.floorLimit(id, bob);
            assertEq(maxPrice, 0.0049 ether);
            assertApproxEqAbs(forfeit, vested / 7, 6);
            sum += forfeit;
        }
        assertEq(sum, vested, "the split loses nothing");
        assertEq(vault.vestCount(bob), 7);
    }

    function _claim(address who) internal returns (uint256 got) {
        vm.prank(who);
        got = vault.claimTokens(0, 0);
    }

    function test_ledger_floorPayToRejectingSellerIsCredited() public {
        _sellOutPresale();
        _launch();
        _fundFloor(1 ether);
        address bad = address(new Rejecter());
        address a = cards.ownerOf(1);
        vm.prank(a);
        cards.transferFrom(a, bad, 1);
        _list(1, 0.002 ether);
        assertEq(vault.sweepFloor(), 1);
        assertEq(cards.proceedsOwed(bad), 0.002 ether);
        _assertCardsBook();
    }

    // ---------------------------------------------------------------- Flap Trigger

    function test_trigger_runsEveryThirtyMinutesFromTheReserve() public {
        _sellOutPresale();
        _launch();
        assertEq(vault.pendingTriggerId(), 0, "nothing booked before the reserve has BNB");
        _fundFloor(1 ether);
        uint256 id = vault.pendingTriggerId();
        assertEq(vault.triggerDueAt(), block.timestamp + 30 minutes, "booked 30 minutes out");
        _list(1, 0.001 ether);
        _list(2, 0.002 ether);
        uint256 reserveBefore = vault.triggerReserve();

        vm.deal(address(vault), address(vault).balance + 0.5 ether);
        uint256 used = _fire();
        assertLt(used, 2_000_000);
        assertEq(vault.totalFloorBurned(), 2, "the trigger synced the new tax and bought both cards");
        assertEq(vault.unrecognizedTax(), 0);
        assertGt(vault.pendingTriggerId(), id, "and booked the next run");
        assertEq(vault.triggerDueAt(), vm.getBlockTimestamp() + 30 minutes);
        assertEq(vault.triggerReserve(), reserveBefore - 0.0002 ether, "next fee paid from the reserve");

        vm.expectRevert(MintAIVault.UnknownTrigger.selector);
        vm.prank(TRIGGER);
        vault.trigger(id);
        uint256 next = vault.pendingTriggerId();
        vm.expectRevert(MintAIVault.NotTrigger.selector);
        vault.trigger(next);
        _assertVaultBook();
        _assertCardsBook();
    }

    function test_trigger_reserveIsToppedUpBeforeTheFundAndNeverSpentOnCards() public {
        _sellOutPresale();
        _launch();
        vm.deal(address(vault), 0.05 ether);
        vault.sync();
        assertEq(vault.floorFund(), 0, "0.015 BNB floor share all goes to the reserve below the line");
        assertEq(vault.triggerReserve(), 0.015 ether - 0.0002 ether);
        _list(1, 0.00001 ether);
        assertEq(vault.sweepFloor(), 0, "the reserve does not buy cards");
        vm.deal(address(vault), address(vault).balance + 0.1 ether);
        vault.sync();
        assertEq(vault.triggerReserve(), 0.02 ether, "filled to the waterline");
        assertEq(vault.floorFund(), 0.0248 ether, "the rest of the share goes to the fund");
        _assertVaultBook();
    }

    function test_trigger_emptyReserveSkipsAndALaterSyncRebooks() public {
        _sellOutPresale();
        _launch();
        vault.sync();
        assertEq(vault.pendingTriggerId(), 0);
        _trigger().setBroken(true);
        vm.deal(address(vault), 1 ether);
        vault.sync();
        assertEq(vault.pendingTriggerId(), 0, "a failing service never blocks the sync");
        assertEq(vault.triggerReserve(), 0.02 ether);
        _trigger().setBroken(false);
        vault.sync();
        assertGt(vault.pendingTriggerId(), 0);
    }

    function test_trigger_aLostRequestIsReplacedAfterAnHour() public {
        _sellOutPresale();
        _launch();
        _fundFloor(1 ether);
        uint256 id = vault.pendingTriggerId();
        vm.warp(vault.triggerDueAt() + 59 minutes);
        vault.sync();
        assertEq(vault.pendingTriggerId(), id, "still waiting");
        vm.warp(block.timestamp + 2 minutes);
        vault.sync();
        assertGt(vault.pendingTriggerId(), id, "replaced");
        vm.prank(TRIGGER);
        vm.expectRevert(MintAIVault.UnknownTrigger.selector);
        vault.trigger(id);
    }

    function test_trigger_aHeavyBookIsSweptOverSeveralRunsUnderTheGasCap() public {
        _sellOutPresale();
        _launch();
        _fundFloor(10 ether);
        for (uint256 id = 1; id <= 120; ++id) {
            _list(id, 0.001 ether + (id % 7) * 0.00001 ether);
        }
        uint256 runs;
        while (vault.totalFloorBurned() < 120) {
            uint256 before = vault.totalFloorBurned();
            uint256 used = _fire();
            emit log_named_uint("trigger run gas", used);
            emit log_named_uint("cards bought in the run", vault.totalFloorBurned() - before);
            assertLt(used, 2_000_000, "each run fits the Trigger gas");
            ++runs;
            assertLt(runs, 30, "progress every run");
        }
        assertGt(runs, 1, "more than one run was needed");
        assertEq(vault.totalFloorSpent(), 120 * 0.001 ether + _tickSum(120));
        _assertCardsBook();
        _assertVaultBook();
    }

    function _tickSum(uint256 n) internal pure returns (uint256 sum) {
        for (uint256 id = 1; id <= n; ++id) {
            sum += (id % 7) * 0.00001 ether;
        }
    }

    /// @dev Post-open cards listed above 0.0049 sit above a presale card the fund may buy. They are not bought.
    function test_trigger_skippedListingsCannotStallTheFund() public {
        _sellOutPresale();
        _launch();
        _fundFloor(10 ether);
        uint256 first = cards.lastTokenId() + 1;
        for (uint256 i; i < 40; ++i) {
            _mint(address(uint160(0xC000 + i)), 10);
        }
        uint256 last = cards.lastTokenId();
        vm.warp(block.timestamp + 1 hours);
        for (uint256 i; i < 40; ++i) {
            vm.prank(address(uint160(0xC000 + i)));
            vault.claimTokens(0, 0);
        }
        for (uint256 id = first; id <= last; ++id) {
            _list(id, 0.00491 ether);
        }
        _list(1, 0.00245 ether);
        uint256 runs;
        while (cards.balanceOf(address(uint160(0xA000))) == 10) {
            uint256 used = _fire();
            assertLt(used, 2_000_000);
            ++runs;
            assertLt(runs, 20, "the skipped listings are walked past");
        }
        assertEq(vault.totalFloorBurned(), 1);
        assertEq(cards.balanceOf(address(uint160(0xC000))), 10, "none of the 400 claimed cards were bought");
    }

    /// @dev One over-cap presale card on each price from 0.00246 through 0.00488. The floor must still reach
    ///      the buyable post-open card at 0.0049 within a few trigger runs.
    function test_trigger_overCapPresalePricesDoNotBlockABuyableCard() public {
        _sellOutPresale();
        _launch();
        _fundFloor(10 ether);
        for (uint256 i; i < 243; ++i) {
            _list(i + 1, 0.00246 ether + i * 0.00001 ether);
        }
        address late = makeAddr("lateFloor");
        _mint(late, 1);
        _list(cards.lastTokenId(), 0.0049 ether);
        uint256 runs;
        while (vault.totalFloorBurned() == 0) {
            _fire();
            ++runs;
            assertLt(runs, 8, "over-cap presale prices must not stall the floor");
        }
        assertEq(vault.totalFloorBurned(), 1);
        assertEq(cards.balanceOf(late), 0, "the post-open card was bought");
        assertEq(cards.balanceOf(cards.ownerOf(1)), 10, "the over-cap presale card was not bought");
    }

    function test_ledger_lastPresaleMintLaunchesAndRefundCloses() public {
        uint256 n;
        while (cards.paidMinted() < 19_990) {
            uint256 count = 19_990 - cards.paidMinted();
            if (count > 10) count = 10;
            _mint(address(uint160(0xA200 + n)), count);
            ++n;
        }
        address last = makeAddr("lastbatch");
        _id(last);
        vm.deal(last, 1 ether);
        vm.prank(last);
        cards.mint{value: 10 * 0.00245 ether}(10, 0);
        assertTrue(cards.launched());
        vault = MintAIVault(payable(cards.vault()));
        assertEq(vault.launcher(), cards.owner());
        uint256[] memory ids = _ids1(1);
        address holder = cards.ownerOf(1);
        vm.prank(holder);
        vm.expectRevert(MintAICardsBase.PresaleNotFailed.selector);
        cards.refund(ids);
    }

    function test_ledger_antiScamModuleFollowsChain() public {
        assertEq(factory.antiScamModule(), ANTI_SCAM);
        vm.chainId(56);
        assertEq(factory.antiScamModule(), factory.ANTI_SCAM_MAINNET());
        vm.chainId(1);
        vm.expectRevert(MintAIVaultFactory.UnsupportedChain.selector);
        factory.antiScamModule();
    }

    function test_ledger_scamNameCannotCreateOrLaunch() public {
        MockAntiScam(ANTI_SCAM).setFlagged(true);
        vm.prank(address(cards));
        vm.expectRevert(MintAIVaultFactory.ScamName.selector);
        factory.creatorExtension();

        MintAICards.InitParams memory init = MintAICards.InitParams({
            owner: address(this),
            opsWallet: ops,
            teamWallet: team,
            router: address(router),
            tokenName: "BNB",
            tokenSymbol: "MINT.AI",
            tokenMeta: "",
            salt: bytes32(uint256(2))
        });
        MintAILauncherFactory fresh =
            new MintAISystemDeployer(
            address(new MintAIVault()), address(new MintAICards()), address(new MintAICardMarket()), keccak256(abi.encode(init))
        ).launcherFactory();
        vm.prank(HUB);
        vm.expectRevert(MintAIVaultFactory.ScamName.selector);
        fresh.newLauncher(address(this), abi.encode(init));
    }

    function test_ledger_creationLocksTheSaltAndPostOpenMintNeedsAMinimum() public {
        assertTrue(cards.saltLocked());
        assertEq(cards.tokenName(), "MINT.AI");
        assertEq(cards.tokenSymbol(), "MINT.AI");
        _launch();
        vault = MintAIVault(payable(cards.vault()));
        address bob = makeAddr("bob");
        _id(bob);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        vm.expectRevert(MintAICardsBase.ZeroMinTokens.selector);
        cards.mint{value: 0.0049 ether}(1, 0);
        vm.prank(bob);
        cards.mint{value: 0.0049 ether}(1, 1);
        assertEq(cards.ownerOf(cards.lastTokenId()), bob);
    }

    function _openLadderTwap() internal {
        MockPair(cards.launchedPool()).setQuote(P.POOL_QUOTE * 16 / 10);
        vault.poke();
        vm.warp(vm.getBlockTimestamp() + 31 minutes);
        vault.poke();
        vm.warp(vm.getBlockTimestamp() + 31 minutes);
        vault.poke();
    }

    /// @dev Mirrors the card stream release. Tests read time through `vm.getBlockTimestamp` because via_ir
    ///      can reuse one `block.timestamp` for a whole test and warp backwards.
    function _streamedDue(uint256 last, uint256 end, uint256 remaining, uint256 rate, uint256 nowTs)
        internal
        pure
        returns (uint256 due)
    {
        if (remaining == 0 || nowTs <= last) return 0;
        if (nowTs >= end) return remaining;
        due = (nowTs - last) * rate / 1e18;
        if (due > remaining) due = remaining;
    }

    function _minLadder(uint256 rung) internal view returns (uint256 amount, uint256 cost) {
        uint256 price = vault.rungPrice(rung);
        amount = (uint256(0.01 ether) * 1e18 + price - 1) / price;
        cost = (amount * price + 1e18 - 1) / 1e18;
    }
}

contract Rejecter {
    receive() external payable {
        revert("no");
    }
}
