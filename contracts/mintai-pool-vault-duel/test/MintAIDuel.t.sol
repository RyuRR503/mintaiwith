// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MintAIBase} from "./MintAIBase.sol";
import {MintAIVault} from "../src/MintAIVault.sol";
import {MintAIDuel} from "../src/MintAIDuel.sol";

contract MintAIDuelTest is MintAIBase {
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function setUp() public {
        _setUpLocal();
        _sellOutPresale();
        _launch();
    }

    function test_duelComesOutWithTheFactories() public view {
        assertGt(address(duel).code.length, 0, "duel runtime is deployed");
        assertEq(duel.vaultFactory(), address(factory), "duel is tied to this factory");
        assertTrue(address(launcher) != address(factory), "launcher and vault factory are different contracts");
        assertEq(factory.launcherFactory(), address(launcher), "vault factory points at the launcher factory");
        assertEq(factory.duel(), address(duel), "the vault factory keeps the duel");
        assertEq(duel.cards(), address(cards), "cards bound by the launcher factory");
        assertEq(duel.vault(), address(vault), "vault bound at launch");
        assertEq(address(vault.duel()), address(duel), "vault knows the duel");
    }

    function test_budgetPaysTheFeeAndWinnerReceivesBothCards() public {
        _primeTrigger();
        vm.deal(address(this), 1 ether);
        vault.fundDuelBudget{value: 0.1 ether}();
        uint256 floorId = vault.pendingTriggerId();
        uint256 reserveBefore = vault.triggerReserve();
        uint256 budgetBefore = vault.duelBudget();
        uint256 cardA = _gift(alice);
        uint256 cardB = _gift(bob);
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
        uint256 aliceBnb = alice.balance;
        uint256 bobBnb = bob.balance;

        assertEq(_enter(alice, cardA), 0, "the first card only waits");
        assertEq(vault.triggerReserve(), reserveBefore, "waiting does not pay the trigger");
        assertEq(vault.duelBudget(), budgetBefore, "waiting does not spend the budget");
        assertEq(cards.ownerOf(cardA), address(duel));

        uint256 matchId = _enter(bob, cardB);
        assertGt(matchId, 0, "the second card starts the match");
        assertEq(alice.balance, aliceBnb, "the budget returns alice's deposit");
        assertEq(bob.balance, bobBnb, "the budget returns bob's deposit");
        assertEq(vault.duelBudget(), budgetBefore - _trigger().getFee(), "the budget pays the fee");
        assertEq(vault.triggerReserve(), reserveBefore, "the floor reserve is not used");
        assertEq(vault.pendingTriggerId(), floorId, "the floor booking stays");

        (,, uint256 cardAStored, uint256 cardBStored, uint64 lockBlock, uint256 requestId, bool open) = duel.matches(matchId);
        assertEq(cardAStored, cardA);
        assertEq(cardBStored, cardB);
        assertEq(lockBlock, block.number);
        assertTrue(open);
        assertEq(duel.requestMatch(requestId), matchId);
        assertEq(_trigger().executeAfter(requestId), block.timestamp + duel.TRIGGER_DELAY());
        assertEq(duel.TRIGGER_DELAY(), vault.DUEL_TRIGGER_DELAY());

        vm.expectRevert(bytes("not due"));
        _trigger().fire(requestId);
        (, bool ready) = duel.preview(matchId);
        assertFalse(ready, "the winner stays hidden until the callback");

        (bool ok, uint256 used) = _callback(requestId);
        assertTrue(ok, "trigger settles the match");
        assertLt(used, 2_000_000, "settlement fits the callback gas");

        address winner = cards.ownerOf(cardA);
        uint256 ownCard = winner == alice ? cardA : cardB;
        uint256 otherCard = winner == alice ? cardB : cardA;
        assertEq(cards.ownerOf(cardA), winner);
        assertEq(cards.ownerOf(cardB), winner);
        assertEq(duel.cardWins(ownCard), 1, "the win is stored on the card that fought");
        assertEq(duel.cardWins(otherCard), 0);
        _assertBooks();
    }

    function test_lossesDoNotChangeTheWinCount() public {
        _primeTrigger();
        vm.deal(address(this), 1 ether);
        vault.fundDuelBudget{value: 0.1 ether}();
        uint256 card = _gift(alice);
        uint256 fresh = _gift(alice);
        assertEq(duel.cardWins(fresh), 0, "a new card starts at zero");
        uint256 losses;
        uint256 wins;
        while (losses == 0 || wins == 0) {
            uint256 before = duel.cardWins(card);
            address foe = _fresh();
            uint256 foeCard = _gift(foe);
            _enter(alice, card);
            uint256 matchId = _enter(foe, foeCard);
            (,,,,, uint256 requestId,) = duel.matches(matchId);
            (bool ok,) = _callback(requestId);
            assertTrue(ok);
            if (cards.ownerOf(card) == alice) {
                assertEq(duel.cardWins(card), before + 1);
                wins++;
            } else {
                assertEq(duel.cardWins(card), before, "a loss does not add a win");
                losses++;
                card = _gift(alice);
            }
            assertEq(duel.cardWins(fresh), 0, "another card does not inherit the count");
            require(wins + losses < 40, "coin flip did not show both sides");
        }
    }

    function test_sixthWinBurnsTheWonCardAndResetsThatCard() public {
        _primeTrigger();
        vm.deal(address(this), 1 ether);
        vault.fundDuelBudget{value: 0.1 ether}();
        uint256 card = _gift(alice);
        uint256 streak;
        uint256 spins;
        uint256 burnedCard;
        while (burnedCard == 0) {
            require(++spins < 400, "no sixth win");
            address foe = _fresh();
            uint256 foeCard = _gift(foe);
            _enter(alice, card);
            uint256 matchId = _enter(foe, foeCard);
            (,,,,, uint256 requestId,) = duel.matches(matchId);
            (bool ok,) = _callback(requestId);
            assertTrue(ok);
            if (cards.ownerOf(card) != alice) {
                streak = 0;
                card = _gift(alice);
                continue;
            }
            streak++;
            if (streak < 6) {
                assertEq(duel.cardWins(card), streak);
                assertEq(cards.ownerOf(card), alice);
                assertEq(cards.ownerOf(foeCard), alice);
                continue;
            }
            assertEq(duel.cardWins(card), 0, "the sixth win clears the count on her card");
            assertEq(cards.ownerOf(card), alice, "her own card comes back");
            vm.expectRevert();
            cards.ownerOf(foeCard);
            burnedCard = foeCard;
        }

        uint256 next = _gift(alice);
        assertEq(duel.cardWins(next), 0, "a replacement card does not keep the old count");
        _assertBooks();
    }

    function test_windowMissRefundsBothCardsAndCountsNoWin() public {
        _primeTrigger();
        uint256 cardA = _gift(alice);
        uint256 cardB = _gift(bob);
        _enter(alice, cardA);
        uint256 matchId = _enter(bob, cardB);
        (,,,, uint64 lockBlock, uint256 requestId,) = duel.matches(matchId);
        vm.expectRevert(MintAIDuel.TooEarly.selector);
        duel.settle(matchId);
        vm.roll(uint256(lockBlock) + 257);
        vm.expectRevert(MintAIDuel.TooEarly.selector);
        duel.settle(matchId);
        uint256 opened = uint256(duel.openedAt(matchId));
        vm.warp(opened + duel.REFUND_DELAY() - 1);
        vm.expectRevert(MintAIDuel.TooEarly.selector);
        duel.settle(matchId);
        vm.warp(opened + duel.REFUND_DELAY());
        duel.settle(matchId);
        assertEq(cards.ownerOf(cardA), alice);
        assertEq(cards.ownerOf(cardB), bob);
        assertEq(duel.cardWins(cardA), 0);
        assertEq(duel.cardWins(cardB), 0);
        (bool ok,) = _callback(requestId);
        assertTrue(ok, "a callback after the refund does not revert");
        assertEq(cards.ownerOf(cardA), alice);
        assertEq(cards.ownerOf(cardB), bob);
        (uint256 vested,) = _expectedVest(1);
        vm.warp(vm.getBlockTimestamp() + 5 days);
        vm.prank(alice);
        assertEq(vault.claimTokens(0, 0), vested, "alice's vest comes back with her card");
        vm.prank(bob);
        assertEq(vault.claimTokens(0, 0), vested, "bob's vest comes back with his card");
        _assertBooks();
    }

    function test_settleBeforeTheWindowDoesNotDraw() public {
        _primeTrigger();
        uint256 cardA = _gift(alice);
        uint256 cardB = _gift(bob);
        _enter(alice, cardA);
        uint256 matchId = _enter(bob, cardB);
        (,,,, uint64 lockBlock, uint256 requestId,) = duel.matches(matchId);
        vm.roll(uint256(lockBlock) + 1);
        vm.expectRevert(MintAIDuel.TooEarly.selector);
        duel.settle(matchId);
        assertEq(cards.ownerOf(cardA), address(duel));
        (bool ok,) = _callback(requestId);
        assertTrue(ok, "the callback draws, settle does not");
        address winner = cards.ownerOf(cardA);
        assertEq(cards.ownerOf(cardB), winner);
        uint256 ownCard = winner == alice ? cardA : cardB;
        assertEq(duel.cardWins(ownCard), 1);
    }

    function test_emptyReserveDoesNotLockTheSecondCard() public {
        uint256 cardA = _gift(alice);
        uint256 cardB = _gift(bob);
        _enter(alice, cardA);
        vm.startPrank(bob);
        cards.setApprovalForAll(address(duel), true);
        vm.expectRevert(MintAIDuel.ShortPaid.selector);
        duel.enter(1, cardB);
        vm.stopPrank();
        assertEq(cards.ownerOf(cardB), bob, "bob keeps his card");
        assertEq(cards.ownerOf(cardA), address(duel), "alice is still waiting");
        vm.prank(alice);
        duel.cancel();
        assertEq(cards.ownerOf(cardA), alice);
        (address seated,,) = duel.roomOf(1);
        assertEq(seated, address(0));
    }

    function test_cancelAndSelfDuel() public {
        _primeTrigger();
        uint256 first = _gift(alice);
        uint256 second = _gift(alice);
        _enter(alice, first);
        vm.startPrank(alice);
        cards.setApprovalForAll(address(duel), true);
        vm.expectRevert(MintAIDuel.SelfDuel.selector);
        duel.enter(1, second);
        vm.stopPrank();
        assertEq(cards.ownerOf(second), alice);
        vm.prank(makeAddr("stranger"));
        vm.expectRevert(MintAIDuel.NotWaiting.selector);
        duel.cancel();
        vm.prank(alice);
        duel.cancel();
        assertEq(cards.ownerOf(first), alice);
    }

    function test_floorSweepKeepsItsOwnTrigger() public {
        _primeTrigger();
        uint256 floorId = vault.pendingTriggerId();
        assertGt(floorId, 0);
        _fight(alice, bob);
        assertEq(vault.pendingTriggerId(), floorId, "a duel does not replace the floor booking");
        _fire();
        assertGt(vault.pendingTriggerId(), 0, "the floor run books the next one");
        assertTrue(vault.pendingTriggerId() != floorId, "the floor run consumed its own id");
    }

    function test_playersSplitTheFeeWhenTheBudgetIsShort() public {
        _primeTrigger();
        uint256 reserveBefore = vault.triggerReserve();
        uint256 fee = vault.duelFee();
        uint256 cardA = _gift(alice);
        uint256 cardB = _gift(bob);
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
        _enter(alice, cardA);
        assertEq(alice.balance, 1 ether - fee / 2, "alice deposits half");
        _enter(bob, cardB);
        assertEq(bob.balance, 1 ether - (fee - fee / 2), "bob deposits the rest");
        assertEq(alice.balance, 1 ether - fee / 2, "alice is not refunded when the budget is empty");
        assertEq(vault.duelBudget(), 0);
        assertEq(vault.triggerReserve(), reserveBefore, "the floor reserve still does not pay the duel");
    }

    function test_floorTaxDoesNotRefillTheDuelBudget() public {
        _primeTrigger();
        vm.deal(address(this), 1 ether);
        vault.fundDuelBudget{value: 0.0002 ether}();
        _fight(alice, bob);
        assertEq(vault.duelBudget(), 0, "one match spends a budget of one fee");
        uint256 floorBefore = vault.floorFund();
        vm.deal(address(vault), address(vault).balance + 1 ether);
        vault.sync();
        assertEq(vault.duelBudget(), 0, "tax does not refill the duel budget");
        assertGt(vault.floorFund(), floorBefore);
        assertEq(vault.unrecognizedTax(), 0);
    }

    function test_cancelReturnsTheDepositAndTheDividend() public {
        _primeTrigger();
        uint256 cardA = _gift(alice);
        vm.deal(alice, 1 ether);
        uint256 fee = vault.duelFee();
        _enter(alice, cardA);
        vm.deal(address(vault), address(vault).balance + 1 ether);
        vault.sync();
        uint256 before = alice.balance;
        vm.prank(alice);
        duel.cancel();
        assertEq(cards.ownerOf(cardA), alice);
        assertGt(alice.balance - before, fee / 2, "deposit plus the dividend earned while waiting");
    }

    function test_timeoutPaysEachCardItsOwnDividend() public {
        _primeTrigger();
        vm.deal(address(this), 1 ether);
        vault.fundDuelBudget{value: 0.1 ether}();
        uint256 cardA = _gift(alice);
        uint256 cardB = _gift(bob);
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
        _enter(alice, cardA);
        uint256 matchId = _enter(bob, cardB);
        vm.deal(address(vault), address(vault).balance + 1 ether);
        vault.sync();
        uint256 aliceBefore = alice.balance;
        uint256 bobBefore = bob.balance;
        vm.warp(uint256(duel.openedAt(matchId)) + duel.REFUND_DELAY());
        duel.settle(matchId);
        uint256 aliceGain = alice.balance - aliceBefore;
        uint256 bobGain = bob.balance - bobBefore;
        assertGt(aliceGain, 0);
        assertEq(aliceGain, bobGain, "each player gets only that card's dividend");
        assertEq(cards.ownerOf(cardA), alice);
        assertEq(cards.ownerOf(cardB), bob);
    }

    function test_sixthWinForfeitsUnclaimedTokensOfAPostOpenCard() public {
        _primeTrigger();
        vm.deal(address(this), 1 ether);
        vault.fundDuelBudget{value: 0.1 ether}();
        address foe = makeAddr("post");
        _mint(foe, 1);
        uint256 postCard = cards.lastTokenId();
        (uint256 vested,) = _expectedVest(1);
        uint256 forfeitedBefore = vault.totalForfeitBurned();
        uint256 own = _gift(alice);
        uint256 streak;
        uint256 spins;
        uint256 lockAtStake;
        uint256 burnedMark;
        while (streak < 6) {
            require(++spins < 500, "no sixth win");
            address opponent;
            uint256 oppCard;
            if (streak == 5) {
                opponent = foe;
                oppCard = postCard;
                (, lockAtStake) = vault.floorLimit(postCard, foe);
                burnedMark = vault.totalForfeitBurned();
            } else {
                opponent = _fresh();
                oppCard = _gift(opponent);
            }
            _enter(alice, own);
            uint256 matchId = _enter(opponent, oppCard);
            (,,,,, uint256 requestId,) = duel.matches(matchId);
            (bool ok,) = _callback(requestId);
            assertTrue(ok);
            if (cards.ownerOf(own) != alice) {
                streak = 0;
                own = _gift(alice);
                continue;
            }
            streak++;
        }
        assertEq(duel.cardWins(own), 0);
        assertEq(cards.ownerOf(own), alice);
        vm.expectRevert();
        cards.ownerOf(postCard);
        uint256 burned = vault.totalForfeitBurned() - burnedMark;
        assertEq(burned, lockAtStake, "the sixth win burns the lock the card was carrying");
        assertLt(burned, vested, "tokens that unlocked before the fight are not burned");
        (address holder,) = vault.cardVest(postCard);
        assertEq(holder, address(0));
        assertEq(vault.totalForfeitBurned() - forfeitedBefore, burned);
        _assertBooks();
    }

    function test_roomsWaitApartAndAFullListRejectsRoom101() public {
        uint256 fee = vault.duelFee();
        uint256 cardA = _gift(alice);
        uint256 cardB = _gift(bob);
        _enterRoom(alice, cardA, 8);
        _enterRoom(bob, cardB, 3);
        (address seatedA, uint256 waitingA,) = duel.roomOf(8);
        (address seatedB, uint256 waitingB,) = duel.roomOf(3);
        assertEq(seatedA, alice);
        assertEq(waitingA, cardA);
        assertEq(seatedB, bob);
        assertEq(waitingB, cardB);
        assertEq(duel.waitingRoom(alice), 8);
        assertEq(duel.waitingRoom(bob), 3);

        address carol = makeAddr("carol");
        uint256 cardC = _gift(carol);
        vm.deal(carol, 1 ether);
        uint256 matchId = _enterRoom(carol, cardC, 3);
        assertGt(matchId, 0);
        (address left,,) = duel.roomOf(3);
        assertEq(left, address(0), "the fought room is free");
        (address still, uint256 stillCard,) = duel.roomOf(8);
        assertEq(still, alice, "the other room keeps waiting");
        assertEq(stillCard, cardA);

        vm.deal(alice, alice.balance + fee);
        vm.prank(alice);
        vm.expectRevert(MintAIDuel.AlreadyWaiting.selector);
        duel.enter{value: fee / 2}(9, cardA);

        address late = makeAddr("late");
        uint256 cardL = _gift(late);
        vm.deal(late, fee);
        vm.startPrank(late);
        cards.setApprovalForAll(address(duel), true);
        vm.expectRevert(MintAIDuel.BadRoom.selector);
        duel.enter{value: fee / 2}(0, cardL);
        vm.expectRevert(MintAIDuel.BadRoom.selector);
        duel.enter{value: fee / 2}(101, cardL);
        vm.stopPrank();
        _enterRoom(late, cardL, 100);
        (address last,,) = duel.roomOf(100);
        assertEq(last, late);
        assertEq(duel.ROOM_COUNT(), 100);
    }

    function test_strangerCannotCallTheVaultTrigger() public {
        vm.expectRevert(MintAIVault.NotTrigger.selector);
        vm.prank(makeAddr("stranger"));
        vault.trigger(1);
    }

    function _fresh() internal view returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked("foe", cards.lastTokenId(), block.number)))));
    }

    function _gift(address to) internal returns (uint256 id) {
        address src = address(uint160(uint256(keccak256(abi.encodePacked("src", to, cards.lastTokenId(), block.timestamp)))));
        _mint(src, 1);
        id = cards.lastTokenId();
        vm.prank(src);
        cards.transferFrom(src, to, id);
    }

    function _enter(address who, uint256 id) internal returns (uint256 matchId) {
        return _enterRoom(who, id, 1);
    }

    function _enterRoom(address who, uint256 id, uint256 roomId) internal returns (uint256 matchId) {
        uint256 fee = vault.duelFee();
        (address seated,, uint256 deposit) = duel.roomOf(roomId);
        uint256 pay = seated == address(0) ? fee / 2 : fee - deposit;
        if (who.balance < pay) vm.deal(who, pay);
        vm.startPrank(who);
        cards.setApprovalForAll(address(duel), true);
        matchId = duel.enter{value: pay}(roomId, id);
        vm.stopPrank();
    }

    function _fight(address a, address b) internal returns (uint256 matchId, address winner) {
        (matchId, winner,,) = _fightCards(a, b);
    }

    function _fightCards(address a, address b)
        internal
        returns (uint256 matchId, address winner, uint256 cardA, uint256 cardB)
    {
        cardA = _gift(a);
        cardB = _gift(b);
        _enter(a, cardA);
        matchId = _enter(b, cardB);
        (,,,,, uint256 requestId,) = duel.matches(matchId);
        (bool ok,) = _callback(requestId);
        assertTrue(ok, "duel trigger");
        winner = cards.ownerOf(cardA);
        assertEq(cards.ownerOf(cardB), winner);
    }

    function _callback(uint256 requestId) internal returns (bool ok, uint256 used) {
        uint256 due = _trigger().executeAfter(requestId);
        if (block.timestamp < due) vm.warp(due);
        vm.roll(block.number + 1);
        if (blockhash(block.number - 1) == bytes32(0)) {
            vm.setBlockhash(block.number - 1, keccak256(abi.encodePacked("mintai-duel", requestId)));
        }
        (ok, used) = _trigger().fire(requestId);
    }

    function _assertBooks() internal view {
        _assertCardsBook();
        _assertVaultBook();
    }
}
