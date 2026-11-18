// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MintAIBase} from "./MintAIBase.sol";

/// @notice Gas of the paths that would also split tax already sitting in the vault.
///         Measures the split (`sync`) separately and adds it, which is higher than doing both
///         in one transaction. Chain 97 so the trigger arm inside `sync` is a real external call.
contract MintAIRecognizeGasTest is MintAIBase {
    function setUp() public {
        _setUpLocal();
    }

    function test_gas_boundRecognize() public {
        _sellOutPresale();
        _launch();
        vm.chainId(97);

        vm.deal(address(vault), address(vault).balance + 10 ether);
        uint256 g = gasleft();
        vault.sync();
        uint256 syncCold = g - gasleft();

        vm.deal(address(vault), address(vault).balance + 10 ether);
        g = gasleft();
        vault.sync();
        uint256 syncWarm = g - gasleft();

        g = gasleft();
        vault.sync();
        uint256 syncEmpty = g - gasleft();

        uint256 mint1 = _mintGas(makeAddr("mint1"), 1);
        uint256 mint10 = _mintGas(makeAddr("mint10"), 10);

        address buyer = makeAddr("buyer");
        vm.deal(buyer, 5 ether);
        _listOwned(_ownerOf(1), 1, 1, 0.00001 ether);
        uint256 buy1 = _buyGas(buyer, 1, 1);

        for (uint256 id = 11; id <= 260; id += 10) {
            _listOwned(_ownerOf(id), id, 10, 0.00001 ether);
        }
        uint256 buy250 = _buyGas(buyer, 11, 250);

        address claimer = _ownerOf(261);
        uint256 claim1 = _claimGas(claimer, 261, 1);

        address whale = makeAddr("whale");
        for (uint256 id = 271; id < 521; ++id) {
            address owner = cards.ownerOf(id);
            vm.prank(owner);
            cards.transferFrom(owner, whale, id);
        }
        vm.deal(address(vault), address(vault).balance + 1 ether);
        vault.sync();
        uint256 claim250 = _claimGas(whale, 271, 250);

        address bidder = makeAddr("bidder");
        vm.deal(bidder, 5 ether);
        vm.prank(bidder);
        uint256 bidOne = cards.placeBid{value: 0.00001 ether}(0.00001 ether, 1);
        uint256 sell1 = _sellGas(_ownerOf(521), bidOne, 521, 1);

        vm.prank(bidder);
        uint256 bidMany = cards.placeBid{value: 0.0025 ether}(0.00001 ether, 250);
        uint256 sell250 = _sellGas(whale, bidMany, 271, 250);

        emit log_named_uint("sync cold (split + arm)", syncCold);
        emit log_named_uint("sync warm (split, already armed)", syncWarm);
        emit log_named_uint("sync empty", syncEmpty);
        emit log_named_uint("mint 1", mint1);
        emit log_named_uint("mint 10", mint10);
        emit log_named_uint("buy 1", buy1);
        emit log_named_uint("buy 250", buy250);
        emit log_named_uint("claim 1", claim1);
        emit log_named_uint("claim 250", claim250);
        emit log_named_uint("sell 1", sell1);
        emit log_named_uint("sell 250", sell250);
        emit log_named_uint("mint 10 + warm split", mint10 + syncWarm);
        emit log_named_uint("claim 250 + warm split", claim250 + syncWarm);
        emit log_named_uint("buy 250 + warm split", buy250 + syncWarm);
        emit log_named_uint("sell 250 + warm split", sell250 + syncWarm);

        assertLt(syncWarm, 500_000, "splitting tax that is already in the vault");
        assertLt(syncCold, 700_000, "first split also arms the floor sweep");
        assertLt(mint10 + syncWarm, 5_000_000, "10-card mint plus a split");
        assertLt(mint1 + syncEmpty, 5_000_000, "1-card mint plus an empty split");
        assertLt(claim1 + syncWarm, 5_000_000, "claim 1 plus a split");
        assertLt(buy1 + syncWarm, 5_000_000, "buy 1 plus a split");
        assertLt(sell1 + syncWarm, 5_000_000, "sell 1 plus a split");
        assertLt(claim250 + syncWarm, 12_000_000, "claim 250 plus a split");
        assertLt(buy250 + syncWarm, 20_000_000, "buy 250 plus a split");
        assertLt(sell250 + syncWarm, 20_000_000, "sell 250 plus a split");

        uint256 nextId = cards.lastTokenId() + 1;
        uint256 oldPending = cards.pendingDividendOf(1);
        uint256 revenue = vault.totalTaxRevenue();
        vm.deal(address(vault), address(vault).balance + 1 ether);
        uint256 mintSplit = _mintGas(makeAddr("splitMint"), 1);
        assertEq(vault.unrecognizedTax(), 0, "mint splits waiting tax");
        assertEq(vault.totalTaxRevenue(), revenue + 1 ether);
        assertEq(cards.pendingDividendOf(nextId), 0, "a new card does not take tax that arrived earlier");
        assertGt(cards.pendingDividendOf(1), oldPending);
        assertLt(mintSplit, 5_000_000, "mint 1 while tax is waiting");

        address claimOwner = _ownerOf(531);
        uint256 owed = cards.pendingDividendOf(531);
        vm.deal(address(vault), address(vault).balance + 1 ether);
        uint256 claimBefore = claimOwner.balance;
        uint256 claimSplit = _claimGas(claimOwner, 531, 1);
        assertEq(vault.unrecognizedTax(), 0, "claim splits waiting tax");
        assertGt(claimOwner.balance - claimBefore, owed, "the claim includes the tax just split");
        assertLt(claimSplit, 5_000_000, "claim 1 while tax is waiting");

        _listOwned(_ownerOf(541), 541, 1, 0.00001 ether);
        vm.deal(address(vault), address(vault).balance + 1 ether);
        uint256 buySplit = _buyGas(buyer, 541, 1);
        assertEq(vault.unrecognizedTax(), 0, "buy splits waiting tax");
        assertLt(buySplit, 5_000_000, "buy 1 while tax is waiting");

        vm.prank(bidder);
        uint256 bidSplit = cards.placeBid{value: 0.00001 ether}(0.00001 ether, 1);
        vm.deal(address(vault), address(vault).balance + 1 ether);
        uint256 sellSplit = _sellGas(_ownerOf(551), bidSplit, 551, 1);
        assertEq(vault.unrecognizedTax(), 0, "sell splits waiting tax");
        assertLt(sellSplit, 5_000_000, "sell 1 while tax is waiting");

        emit log_named_uint("mint 1 while 1 BNB is waiting", mintSplit);
        emit log_named_uint("claim 1 while 1 BNB is waiting", claimSplit);
        emit log_named_uint("buy 1 while 1 BNB is waiting", buySplit);
        emit log_named_uint("sell 1 while 1 BNB is waiting", sellSplit);
    }

    function _ownerOf(uint256 id) private pure returns (address) {
        return address(uint160(0xA000 + (id - 1) / 10));
    }

    function _listOwned(address owner, uint256 fromId, uint256 count, uint256 price) private {
        uint256[] memory ids = new uint256[](count);
        uint256[] memory prices = new uint256[](count);
        for (uint256 i; i < count; ++i) {
            ids[i] = fromId + i;
            prices[i] = price;
        }
        vm.prank(owner);
        cards.list(ids, prices);
    }

    function _mintGas(address who, uint256 count) private returns (uint256 used) {
        _id(who);
        uint256 paid = _quote(count);
        vm.deal(who, paid);
        uint256 g = gasleft();
        vm.prank(who);
        cards.mint{value: paid}(count, 1);
        used = g - gasleft();
    }

    function _buyGas(address buyer, uint256 fromId, uint256 count) private returns (uint256 used) {
        uint256[] memory ids = new uint256[](count);
        uint256[] memory maxPrices = new uint256[](count);
        for (uint256 i; i < count; ++i) {
            ids[i] = fromId + i;
            maxPrices[i] = 0.00001 ether;
        }
        uint256 g = gasleft();
        vm.prank(buyer);
        cards.buy{value: 0.00001 ether * count}(ids, maxPrices);
        used = g - gasleft();
    }

    function _claimGas(address who, uint256 fromId, uint256 count) private returns (uint256 used) {
        uint256[] memory ids = new uint256[](count);
        for (uint256 i; i < count; ++i) ids[i] = fromId + i;
        uint256 g = gasleft();
        vm.prank(who);
        cards.claim(ids);
        used = g - gasleft();
    }

    function _sellGas(address seller, uint256 bidId, uint256 fromId, uint256 count) private returns (uint256 used) {
        uint256[] memory ids = new uint256[](count);
        for (uint256 i; i < count; ++i) ids[i] = fromId + i;
        uint256 g = gasleft();
        vm.prank(seller);
        cards.sellToBid(bidId, ids);
        used = g - gasleft();
    }
}
