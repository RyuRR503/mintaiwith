// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MintAICardsBase} from "./MintAICardsBase.sol";

/// @notice Card-market logic. The vault factory deploys one copy. The cards proxy delegatecalls it,
///         so listings, bids and proceeds stay in the cards proxy's storage.
contract MintAICardMarket is MintAICardsBase {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ---------------------------------------------------------------- market

    function list(uint256[] calldata tokenIds, uint256[] calldata prices) external nonReentrant {
        if (!launched) revert NotLaunched();
        uint256 n = tokenIds.length;
        if (n == 0 || n > MAX_BATCH || n != prices.length) revert BadOrder();
        for (uint256 i; i < n; ++i) {
            uint256 id = tokenIds[i];
            uint256 price = prices[i];
            if (_ownerOf(id) != msg.sender) revert NotCardOwner();
            uint256 tick = price / PRICE_TICK;
            if (tick == 0 || tick >= MAX_TICK || price % PRICE_TICK != 0) revert BadPrice();
            if (listings[id].seller != address(0)) _clearListing(id);
            listings[id] = Listing(msg.sender, uint96(price));
            listedBits[id >> 8] |= 1 << (id & 255);
            if (tickCount[tick]++ == 0) {
                uint256 w = tick >> 8;
                if (tickBits[w] == 0) tickWordBits[w >> 8] |= 1 << (w & 255);
                tickBits[w] |= 1 << (tick & 255);
            }
            if (tick < floorHint) floorHint = tick;
            uint256 key = tick << 1 | (id > FIRST_BATCH && !isTeamCard[id] ? 1 : 0);
            uint256 head = tickHead[key];
            nextListed[id] = head;
            if (head != 0) prevListed[head] = id;
            tickHead[key] = id;
            emit Listed(id, msg.sender, price);
        }
    }

    function unlist(uint256[] calldata tokenIds) external nonReentrant {
        uint256 n = tokenIds.length;
        if (n == 0 || n > MAX_BATCH * 4) revert BadOrder();
        for (uint256 i; i < n; ++i) {
            uint256 id = tokenIds[i];
            if (listings[id].seller != msg.sender) revert NotCardOwner();
            _clearListing(id);
            emit Unlisted(id, msg.sender);
        }
    }

    /// @notice Buy listed cards. Gone or repriced-above-max listings are skipped; unspent BNB is refunded.
    function buy(uint256[] calldata tokenIds, uint256[] calldata maxPrices)
        external
        payable
        nonReentrant
        returns (uint256 bought)
    {
        uint256 n = tokenIds.length;
        if (n == 0 || n > MAX_BATCH || n != maxPrices.length) revert BadOrder();
        booked += msg.value;
        _accrueStream();
        uint256 spent;
        for (uint256 i; i < n; ++i) {
            uint256 id = tokenIds[i];
            Listing memory l = listings[id];
            if (l.seller == address(0) || l.seller == msg.sender || l.price > maxPrices[i]) continue;
            if (_ownerOf(id) != l.seller) continue;
            spent += l.price;
            if (spent > msg.value) revert WrongPayment(spent, msg.value);
            _payOrCredit(l.seller, _settleSale(id, l.seller, msg.sender, l.price));
            ++bought;
        }
        if (bought == 0) revert NothingBought();
        if (msg.value > spent) _sendBnb(msg.sender, msg.value - spent);
        _pushOps();
    }

    function placeBid(uint256 price, uint256 quantity) external payable nonReentrant returns (uint256 bidId) {
        if (!launched) revert NotLaunched();
        if (price == 0 || price > type(uint96).max || quantity == 0 || quantity > type(uint32).max) revert BadOrder();
        uint256 total = price * quantity;
        if (msg.value != total) revert WrongPayment(total, msg.value);
        booked += total;
        bidEscrow += total;
        bidId = nextBidId++;
        bids[bidId] = Bid(msg.sender, uint96(price), uint32(quantity));
        openBidBits[bidId >> 8] |= 1 << (bidId & 255);
        emit BidPlaced(bidId, msg.sender, price, quantity);
    }

    function cancelBids(uint256[] calldata bidIds) external nonReentrant returns (uint256 refunded) {
        uint256 n = bidIds.length;
        if (n == 0 || n > MAX_BATCH * 4) revert BadOrder();
        for (uint256 i; i < n; ++i) {
            Bid storage b = bids[bidIds[i]];
            if (b.bidder != msg.sender) revert NotBidder();
            uint256 r = uint256(b.price) * b.remaining;
            if (r > 0) openBidBits[bidIds[i] >> 8] &= ~(1 << (bidIds[i] & 255));
            b.remaining = 0;
            refunded += r;
            emit BidCancelled(bidIds[i], msg.sender, r);
        }
        if (refunded == 0) revert NothingToClaim();
        bidEscrow -= refunded;
        _sendBnb(msg.sender, refunded);
    }

    function sellToBid(uint256 bidId, uint256[] calldata tokenIds) external nonReentrant returns (uint256 received) {
        uint256 n = tokenIds.length;
        if (n == 0 || n > MAX_BATCH) revert BadOrder();
        Bid storage b = bids[bidId];
        address bidder = b.bidder;
        if (bidder == address(0) || bidder == msg.sender) revert BadOrder();
        if (b.remaining < n) revert BidFilled();
        uint256 price = b.price;
        b.remaining -= uint32(n);
        if (b.remaining == 0) openBidBits[bidId >> 8] &= ~(1 << (bidId & 255));
        bidEscrow -= price * n;
        _accrueStream();
        for (uint256 i; i < n; ++i) {
            uint256 id = tokenIds[i];
            if (_ownerOf(id) != msg.sender) revert NotCardOwner();
            received += _settleSale(id, msg.sender, bidder, price);
        }
        _sendBnb(msg.sender, received);
        _pushOps();
    }

    function withdrawProceeds(address to) external nonReentrant returns (uint256 amount) {
        if (to == address(0)) revert ZeroAddress();
        amount = proceedsOwed[msg.sender];
        if (amount == 0) revert NothingToClaim();
        proceedsOwed[msg.sender] = 0;
        proceedsLiability -= amount;
        _sendBnb(to, amount);
        emit ProceedsWithdrawn(msg.sender, to, amount);
    }

}
