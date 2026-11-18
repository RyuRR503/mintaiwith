// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MintAIBase} from "./MintAIBase.sol";
import {MintAICards} from "../src/MintAICards.sol";
import {MintAICardsBase} from "../src/MintAICardsBase.sol";
import {MintAIVault} from "../src/MintAIVault.sol";
import {MintAIParams as P} from "../src/MintAIParams.sol";

contract MintAIStressTest is MintAIBase {
    function setUp() public {
        _setUpLocal();
    }

    function test_stress_twoThousandBuyersFillThePresale() public {
        uint256 buyers;
        uint256 g = gasleft();
        _sellOutPresale();
        uint256 used = g - gasleft();
        while (true) {
            if (cards.mintsUsed(address(uint160(0xA000 + buyers))) == 0) break;
            ++buyers;
        }
        assertEq(buyers, 2_000, "20,000 cards at 10 each");
        assertEq(cards.paidMinted(), 20_000);
        assertTrue(cards.launched(), "the filling mint opens the pool");
        assertEq(address(cards).balance, 0);
        assertEq(cards.totalWeight(), 20_000);
        emit log_named_uint("gas for 2000 presale mint calls", used);
        assertLt(used, 2_200_000_000, "presale fill stays under 2.2B gas");
        _assertCardsBook();
    }

    function test_stress_claimsBidsMintsAndASweep() public {
        _sellOutPresale();
        _launch();
        vm.deal(address(vault), 2 ether);
        vault.sync();

        uint256 claimed;
        for (uint256 i = 1; i <= 50; ++i) {
            address holder = cards.ownerOf(i);
            uint256 before = holder.balance;
            vm.prank(holder);
            cards.claim(_ids1(i));
            claimed += holder.balance - before;
        }
        assertGt(claimed, 0);
        assertLt(claimed, 1.4 ether, "fifty cards cannot take the whole dividend");

        address trader = makeAddr("trader");
        vm.deal(trader, 5 ether);
        uint256 bought;
        uint256[] memory prices = new uint256[](1);
        prices[0] = 0.01 ether;
        for (uint256 i = 51; i <= 70; ++i) {
            _list(i, 0.01 ether);
            vm.prank(trader);
            bought += cards.buy{value: 0.01 ether}(_ids1(i), prices);
        }
        assertEq(bought, 20);

        uint256 g = gasleft();
        _mint(makeAddr("after"), 10);
        uint256 mintGas = g - gasleft();
        emit log_named_uint("gas for a 10-card post-open mint", mintGas);
        assertLt(mintGas, 3_000_000, "a full 10-card mint stays under 3M gas");

        for (uint256 i; i < 100; ++i) {
            _list(101 + i, 0.002 ether);
        }
        g = gasleft();
        uint256 swept = vault.sweepFloor();
        uint256 sweepGas = g - gasleft();
        emit log_named_uint("gas for sweeping 100 floor cards", sweepGas);
        assertEq(swept, 100, "0.38 BNB fund buys 100 cards at 0.002 = 0.2");
        assertLt(sweepGas, 10_000_000, "about 70k gas per presale card");
        _assertCardsBook();
        _assertVaultBook();
    }

    function test_stress_sweepJumpsAcrossTheWholeTickRangeAndAStaleHint() public {
        _sellOutPresale();
        _launch();
        _fundFloor(120 ether);
        _list(1, 0.00001 ether);
        _list(2, 0.002 ether);
        _list(3, 10.48575 ether);
        uint256 g = gasleft();
        assertEq(vault.sweepFloor(), 2, "the card above 0.0049 is not bought");
        assertLt(g - gasleft(), 700_000, "jumping between far ticks is cheap");
        (address still,) = cards.listings(3);
        assertTrue(still != address(0), "the 10 BNB presale card stays listed");
        _list(4, 0.00002 ether);
        _list(5, 0.00245 ether);
        g = gasleft();
        assertEq(vault.sweepFloor(), 2, "the hint is only a lower bound; the floor is still found");
        assertLt(g - gasleft(), 500_000);
        _assertCardsBook();
        _assertVaultBook();
    }

    function test_stress_manyBidsThenCancel() public {
        _sellOutPresale();
        _launch();
        address a = cards.ownerOf(1);
        vm.deal(a, 30 ether);
        uint256 n = 40;
        uint256[] memory ids = new uint256[](n);
        vm.startPrank(a);
        for (uint256 i; i < n; ++i) {
            ids[i] = cards.placeBid{value: 0.2 ether}(0.2 ether, 1);
        }
        vm.stopPrank();
        assertEq(cards.bidEscrow(), 8 ether);
        uint256 before = a.balance;
        vm.prank(a);
        cards.cancelBids(ids);
        assertEq(a.balance - before, 8 ether);
        assertEq(cards.bidEscrow(), 0);
        assertEq(address(cards).balance, cards.booked());
        _assertCardsBook();
    }

    function test_fuzz_vestingIsLinearAndCapped(uint32 dt) public {
        _sellOutPresale();
        _launch();
        address a = address(uint160(0xA000));
        uint256 t = bound(dt, 0, 30 days);
        vm.warp(block.timestamp + t);
        (uint256 total, uint256 claimed, uint256 claimable, uint256 locked) = vault.tokensOf(a);
        uint256 upfront = total / 5;
        uint256 rest = total - upfront;
        uint256 expected = upfront + (t >= 5 days ? rest : rest * t / 5 days);
        assertEq(claimable, expected);
        assertEq(claimed + claimable + locked, total);
    }

    function test_fuzz_mintVestIsNinetyPercentOfWhatWasBought(uint8 count, uint64 rateSeed) public {
        _sellOutPresale();
        _launch();
        uint256 n = bound(count, 1, 10);
        router.setRate(bound(rateSeed, 1 ether, 1e30));
        address a = makeAddr("fz");
        uint256 deadBefore = _token().balanceOf(DEAD);
        _mint(a, n);
        uint256 burned = _token().balanceOf(DEAD) - deadBefore;
        uint256 vested = vault.boughtOwed();
        assertEq(burned, (burned + vested) * 1_000 / 10_000);
        (uint256 v, uint256 b) = _expectedVest(n);
        assertEq(vested, v);
        assertEq(burned, b);
    }
}

/// @dev Sells every card. Slow (about 72,000 mint calls); run with --match-contract MintAISellOutTest.
contract MintAISellOutTest is MintAIBase {
    function setUp() public {
        _setUpLocal();
    }

    function fillOpenBatch() external {
        require(msg.sender == address(this));
        uint256 count = 738_889 - cards.paidMinted();
        if (count > 10) count = 10;
        _mint(address(uint160(0x1_0000_0000 + (cards.paidMinted() - 20_000) / 10)), count);
    }

    function test_sellOut_all777777CardsAndExactGrantBudget() public {
        _sellOutPresale();
        _launch();
        while (cards.paidMinted() < 738_889) this.fillOpenBatch();
        assertEq(cards.paidMinted(), 738_889);
        assertEq(cards.teamUnlocked(), 38_888);

        address late = makeAddr("late");
        _id(late);
        vm.deal(late, 1 ether);
        vm.prank(late);
        vm.expectRevert(MintAICardsBase.SoldOut.selector);
        cards.mint{value: 0.0049 ether}(1, 0);

        while (cards.teamMinted() < 38_888) {
            uint256 left = 38_888 - cards.teamMinted();
            vm.prank(team);
            cards.mintTeam(team, left > 100 ? 100 : left);
        }
        vm.prank(team);
        vm.expectRevert(MintAICardsBase.TeamNotUnlocked.selector);
        cards.mintTeam(team, 1);
        assertEq(cards.lastTokenId(), 777_777);
        assertEq(cards.totalWeight(), 777_777);
        emit log_named_uint("post-open mint BNB swapped", vault.totalMintBnb());
        emit log_named_uint("post-open tokens burned", vault.totalMintBurned() / 1e18);
        assertEq(vault.totalMintBnb(), 718_889 * 0.003675 ether);

        vm.warp(block.timestamp + 5 days);
        uint256 teamRows = vault.vestCount(team);
        for (uint256 from; from < teamRows; from += 500) {
            vm.prank(team);
            vault.claimTokens(from, 500);
        }
        for (uint256 i; i < 2_000; ++i) {
            vm.prank(address(uint160(0xA000 + i)));
            vault.claimTokens(0, 0);
        }
        assertEq(vault.bucketLeft(P.BUCKET_GRANT), 0, "grant bucket used to the last token");
        assertEq(_token().balanceOf(team), 38_888 * 8_440 ether);

        _fundFloor(1 ether);
        uint256 id = 30_000;
        (uint256 maxPrice,) = vault.floorLimit(id, cards.ownerOf(id));
        assertEq(maxPrice, 0.0049 ether, "sell-out does not remove the 0.0049 cap");
        _list(id, 0.01 ether);
        assertEq(vault.sweepFloor(), 0, "above 0.0049 is still skipped after sell-out");
        _list(id, 0.0049 ether);
        assertEq(vault.sweepFloor(), 1, "a post-open card is still bought at 0.0049 after sell-out");
        assertEq(cards.totalWeight(), 777_776);
        _assertCardsBook();
        _assertVaultBook();
    }
}
