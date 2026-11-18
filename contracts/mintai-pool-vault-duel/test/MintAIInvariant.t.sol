// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {MintAIBase} from "./MintAIBase.sol";
import {MintAICards} from "../src/MintAICards.sol";
import {MintAIVault} from "../src/MintAIVault.sol";
import {MintAICardsLens} from "../src/MintAICardsLens.sol";
import {MintAIParams as P} from "../src/MintAIParams.sol";
import {AgentIdStub, MockRouter} from "./MintAIMocks.sol";

contract MintAIHandler is MintAIBase {
    MintAICards public c;
    address public guardianAddr;

    constructor(MintAICards cards_, address guardian_) {
        c = cards_;
        guardianAddr = guardian_;
        cards = cards_;
    }

    function mint(uint256 who, uint256 count) external {
        if (c.paidMinted() > 200 || c.presaleFailed()) return;
        who = bound(who, 1, 20);
        count = bound(count, 1, 10);
        address a = address(uint160(0x1000 + who));
        uint256 used = c.mintsUsed(a);
        if (used >= 10) return;
        if (used + count > 10) count = 10 - used;
        AgentIdStub(AGENT_ID).set(a, 1);
        uint256 total = c.priceOf(c.paidMinted() + 1) * count;
        vm.deal(a, a.balance + total);
        vm.prank(a);
        try c.mint{value: total}(count, 0) {} catch {}
    }

    function refund(uint256 id) external {
        if (!c.presaleFailed() || c.lastTokenId() == 0) return;
        id = bound(id, 1, c.lastTokenId());
        try c.ownerOf(id) returns (address owner) {
            uint256[] memory ids = new uint256[](1);
            ids[0] = id;
            vm.prank(owner);
            try c.refund(ids) {} catch {}
        } catch {}
    }

    function warp(uint256 dt) external {
        vm.warp(block.timestamp + bound(dt, 1, 2 days));
    }

    function donate(uint96 amt) external {
        uint256 value = bound(amt, 1, 1 ether);
        vm.deal(address(c), address(c).balance + value);
    }

    function guardianWithdraw(uint96 amt) external {
        uint256 value = bound(amt, 1, 10 ether);
        vm.prank(guardianAddr);
        try c.emergencyWithdrawNative(guardianAddr, value) {} catch {}
    }

    receive() external payable {}
}

contract MintAIInvariantTest is StdInvariant, MintAIBase {
    MintAIHandler internal h;

    function setUp() public {
        _setUpLocal();
        h = new MintAIHandler(cards, _guardian());
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = MintAIHandler.mint.selector;
        selectors[1] = MintAIHandler.refund.selector;
        selectors[2] = MintAIHandler.warp.selector;
        selectors[3] = MintAIHandler.donate.selector;
        selectors[4] = MintAIHandler.guardianWithdraw.selector;
        targetSelector(FuzzSelector({addr: address(h), selectors: selectors}));
    }

    /// forge-config: default.invariant.runs = 20
    /// forge-config: default.invariant.depth = 25
    function invariant_bookMatchesBalance() public view {
        uint256 parts = cards.presaleEscrow() + cards.dividendLiability() + cards.pendingDividend()
            + cards.streamRemaining() + cards.sideStreamRemaining() + cards.opsOwed() + cards.bidEscrow()
            + cards.proceedsLiability();
        assertEq(cards.booked(), parts);
        assertGe(address(cards).balance, cards.booked());
    }

    /// forge-config: default.invariant.runs = 20
    /// forge-config: default.invariant.depth = 25
    function invariant_weightMatchesLiveCards() public view {
        uint256 live;
        uint256 end = cards.lastTokenId();
        for (uint256 id = 1; id <= end; ++id) {
            try cards.ownerOf(id) returns (address) {
                ++live;
            } catch {}
        }
        assertEq(cards.totalWeight(), live);
        assertLe(cards.mintsUsed(address(uint160(0x1001))), 10);
    }
}

/// @dev Random activity after launch: mints, team mints, listings, sales, bids, floor sweeps, tax, claims.
contract MintAILiveHandler is MintAIBase {
    MintAICards public c;
    MintAIVault public v;
    address public teamAddr;
    uint256 public burned;

    constructor(MintAICards cards_, MintAIVault vault_, address team_, MockRouter router_) {
        c = cards_;
        v = vault_;
        cards = cards_;
        vault = vault_;
        teamAddr = team_;
        router = router_;
        lens = new MintAICardsLens();
    }

    function _actor(uint256 seed) internal pure returns (address) {
        return address(uint160(0xA000 + (seed % 40)));
    }

    function _card(uint256 seed) internal view returns (uint256 id, address owner, bool ok) {
        uint256 end = c.lastTokenId();
        id = bound(seed, 1, end);
        try c.ownerOf(id) returns (address o) {
            return (id, o, true);
        } catch {
            return (id, address(0), false);
        }
    }

    function mint(uint256 who, uint256 count) external {
        address a = address(uint160(0x5000 + bound(who, 0, 200)));
        count = bound(count, 1, 10);
        uint256 used = c.mintsUsed(a);
        if (used >= 10) return;
        if (used + count > 10) count = 10 - used;
        AgentIdStub(AGENT_ID).set(a, 1);
        uint256 total = c.MINT_PRICE() * count;
        vm.deal(a, a.balance + total);
        vm.prank(a);
        c.mint{value: total}(count, 1);
    }

    function teamMint(uint256 count) external {
        uint256 left = c.teamUnlocked() - c.teamMinted();
        if (left == 0) return;
        count = bound(count, 1, left > 100 ? 100 : left);
        vm.prank(teamAddr);
        c.mintTeam(teamAddr, count);
    }

    function moveRate(uint256 seed) external {
        router.setRate(bound(seed, 1e24, 1e26));
    }

    function tax(uint96 amt) external {
        vm.deal(address(v), address(v).balance + bound(amt, 1, 2 ether));
        v.sync();
    }

    function list(uint256 seed, uint256 priceTicks) external {
        (uint256 id, address owner, bool ok) = _card(seed);
        if (!ok) return;
        uint256[] memory prices = new uint256[](1);
        prices[0] = bound(priceTicks, 1, 1_000) * 0.00001 ether;
        vm.prank(owner);
        c.list(_ids1(id), prices);
    }

    function unlist(uint256 seed) external {
        (uint256 id,, bool ok) = _card(seed);
        if (!ok) return;
        (address seller,) = c.listings(id);
        if (seller == address(0)) return;
        vm.prank(seller);
        c.unlist(_ids1(id));
    }

    function buyListing(uint256 seed, uint256 buyerSeed) external {
        (uint256 id,, bool ok) = _card(seed);
        if (!ok) return;
        (address seller, uint96 price) = c.listings(id);
        address b = _actor(buyerSeed);
        if (seller == address(0) || seller == b) return;
        uint256[] memory prices = new uint256[](1);
        prices[0] = price;
        vm.deal(b, b.balance + price);
        vm.prank(b);
        c.buy{value: price}(_ids1(id), prices);
    }

    /// @dev Model: walk every open listing cheapest first; a card is bought when its ask fits the remaining fund
    ///      and is within its floorLimit. Checks the count bought and exactly which tokens burn.
    function sweep() external {
        if (v.sweepKey() != 0) burned += v.sweepFloor();
        (MintAICardsLens.ListingView[] memory open,,) = lens.getActiveListings(address(c), 0, 500);
        uint256 n = open.length;
        for (uint256 i = 1; i < n; ++i) {
            MintAICardsLens.ListingView memory x = open[i];
            uint256 j = i;
            while (j > 0 && open[j - 1].price > x.price) {
                open[j] = open[j - 1];
                --j;
            }
            open[j] = x;
        }
        uint256 fund = v.floorFund();
        uint256 expected;
        uint256[] memory forfeitOf = new uint256[](n);
        for (uint256 i; i < n; ++i) {
            if (open[i].price > fund) break;
            uint256 maxPrice;
            (maxPrice, forfeitOf[i]) = v.floorLimit(open[i].tokenId, open[i].seller);
            if (open[i].price > maxPrice) continue;
            fund -= open[i].price;
            ++expected;
        }
        uint256 before = c.totalWeight();
        uint256 deadBefore = _token().balanceOf(DEAD);
        uint256 bought = v.sweepFloor();
        burned += bought;
        assertEq(bought, expected, "every eligible card that fits is bought, cheapest first");
        assertEq(c.totalWeight(), before - bought);
        uint256 forfeits;
        for (uint256 i; i < n; ++i) {
            try c.ownerOf(open[i].tokenId) returns (address) {}
            catch {
                forfeits += forfeitOf[i];
            }
        }
        assertEq(_token().balanceOf(DEAD) - deadBefore, forfeits, "exactly the still-locked tokens of bought cards burn");
        assertEq(v.sweepKey(), 0, "a full pass resets the cursor");
    }

    /// @dev The Flap Trigger service fires the booked request with its 2,000,000 gas.
    function fireTrigger() external {
        uint256 id = v.pendingTriggerId();
        if (id == 0) return;
        if (block.timestamp < v.triggerDueAt()) vm.warp(v.triggerDueAt());
        uint256 before = v.totalFloorBurned();
        (bool ok,) = _trigger().fire(id);
        assertTrue(ok, "trigger callback never fails");
        burned += v.totalFloorBurned() - before;
    }

    function bidAndFill(uint256 seed, uint256 bidderSeed, uint96 priceSeed) external {
        (uint256 id, address owner, bool ok) = _card(seed);
        if (!ok) return;
        address b = _actor(bidderSeed);
        if (b == owner) return;
        uint256 price = bound(priceSeed, 1, 0.01 ether);
        vm.deal(b, b.balance + price);
        vm.prank(b);
        uint256 bidId = c.placeBid{value: price}(price, 1);
        vm.prank(owner);
        c.sellToBid(bidId, _ids1(id));
    }

    function transfer(uint256 seed, uint256 toSeed) external {
        (uint256 id, address owner, bool ok) = _card(seed);
        if (!ok) return;
        vm.prank(owner);
        c.transferFrom(owner, _actor(toSeed), id);
    }

    function claimDividend(uint256 seed) external {
        (uint256 id, address owner, bool ok) = _card(seed);
        if (!ok || c.pendingDividendOf(id) == 0) return;
        vm.prank(owner);
        c.claim(_ids1(id));
    }

    function claimTokens(uint256 who) external {
        address a = who % 2 == 0 ? address(uint160(0x5000 + bound(who, 0, 200))) : _actor(who);
        if (who % 7 == 0) a = teamAddr;
        (,, uint256 claimable,) = v.tokensOf(a);
        if (claimable == 0) return;
        vm.prank(a);
        v.claimTokens(0, 0);
    }

    function warp(uint256 dt) external {
        vm.warp(block.timestamp + bound(dt, 1, 2 days));
        c.poke();
    }
}

contract MintAILiveInvariantTest is StdInvariant, MintAIBase {
    MintAILiveHandler internal h;

    function setUp() public {
        _setUpLocal();
        _sellOutPresale();
        _launch();
        h = new MintAILiveHandler(cards, vault, team, router);
        bytes4[] memory s = new bytes4[](15);
        s[0] = MintAILiveHandler.mint.selector;
        s[1] = MintAILiveHandler.teamMint.selector;
        s[2] = MintAILiveHandler.moveRate.selector;
        s[3] = MintAILiveHandler.tax.selector;
        s[4] = MintAILiveHandler.list.selector;
        s[5] = MintAILiveHandler.unlist.selector;
        s[6] = MintAILiveHandler.buyListing.selector;
        s[7] = MintAILiveHandler.sweep.selector;
        s[8] = MintAILiveHandler.bidAndFill.selector;
        s[9] = MintAILiveHandler.transfer.selector;
        s[10] = MintAILiveHandler.claimDividend.selector;
        s[11] = MintAILiveHandler.claimTokens.selector;
        s[12] = MintAILiveHandler.warp.selector;
        s[13] = MintAILiveHandler.warp.selector;
        s[14] = MintAILiveHandler.fireTrigger.selector;
        targetSelector(FuzzSelector({addr: address(h), selectors: s}));
        targetContract(address(h));
    }

    /// forge-config: default.invariant.runs = 30
    /// forge-config: default.invariant.depth = 60
    /// forge-config: default.invariant.fail-on-revert = true
    function invariant_live_booksBalance() public view {
        uint256 parts = cards.presaleEscrow() + cards.dividendLiability() + cards.pendingDividend()
            + cards.streamRemaining() + cards.sideStreamRemaining() + cards.opsOwed() + cards.bidEscrow()
            + cards.proceedsLiability();
        assertEq(cards.booked(), parts, "card book");
        assertGe(address(cards).balance, cards.booked(), "card BNB covers the book");
        assertEq(
            address(vault).balance,
            vault.floorFund() + vault.triggerReserve() + vault.duelBudget(),
            "vault holds only fund + reserve + duel budget"
        );
        assertLe(vault.triggerReserve(), vault.TRIGGER_WATERLINE(), "reserve never grows past the line from tax");
        assertGe(_token().balanceOf(address(vault)), vault.boughtOwed(), "vault holds owed tokens");
        assertLe(vault.bucketReleased(0), P.GRANT_BUDGET);
    }

    /// forge-config: default.invariant.runs = 30
    /// forge-config: default.invariant.depth = 60
    /// forge-config: default.invariant.fail-on-revert = true
    function invariant_live_weightAndTickBook() public view {
        assertEq(vault.totalFloorBurned(), h.burned(), "floor burns match what the sweeps returned");
        assertEq(cards.totalWeight(), cards.lastTokenId() - h.burned(), "weight = minted - burned");
        (MintAICardsLens.ListingView[] memory open,,) = lens.getActiveListings(address(cards), 0, 500);
        uint256 lowest = type(uint256).max;
        for (uint256 i; i < open.length; ++i) {
            assertEq(cards.ownerOf(open[i].tokenId), open[i].seller, "listing seller owns the card");
            uint256 tick = open[i].price / 0.00001 ether;
            assertGe(tick, cards.floorHint(), "hint is a lower bound");
            if (open[i].price < lowest) lowest = open[i].price;
        }
        uint256 counted;
        for (uint256 t = 1; t <= 1_000; ++t) counted += cards.tickCount(t);
        assertEq(counted, open.length, "tick counts = listings");
        (uint256 floorPrice,) = lens.floor(address(cards));
        assertEq(floorPrice, open.length == 0 ? 0 : lowest, "lens floor = lowest listing");
    }

    /// forge-config: default.invariant.runs = 30
    /// forge-config: default.invariant.depth = 60
    /// forge-config: default.invariant.fail-on-revert = true
    function invariant_live_boughtOwedEqualsUnclaimedSchedules() public view {
        uint256 owed;
        for (uint256 i; i <= 200; ++i) {
            owed += _unclaimedBought(address(uint160(0x5000 + i)));
        }
        for (uint256 i; i < 40; ++i) {
            owed += _unclaimedBought(address(uint160(0xA000 + i)));
        }
        assertEq(vault.boughtOwed(), owed, "owed bought tokens = unclaimed post-open schedules");
    }

    function _unclaimedBought(address a) private view returns (uint256 owed) {
        uint256 n = vault.vestCount(a);
        for (uint256 j; j < n; ++j) {
            (uint104 total, uint104 claimed,, bool reserve) = vault.vests(a, j);
            if (!reserve) owed += total - claimed;
        }
    }
}
