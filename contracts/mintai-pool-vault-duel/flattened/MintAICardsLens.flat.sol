// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// src/MintAIInterfaces.sol

interface IMintAICards {
    function tokenName() external view returns (string memory);
    function tokenSymbol() external view returns (string memory);
    function launching() external view returns (bool);
    function presaleCards(address who) external view returns (uint256);
    function paidMinted() external view returns (uint256);
    function teamUnlockAt(uint256 ordinal) external view returns (uint40);
    function listings(uint256 tokenId) external view returns (address seller, uint96 price);
    function floorHint() external view returns (uint256);
    function nextTick(uint256 from) external view returns (uint256);
    function tickHead(uint256 key) external view returns (uint256);
    function nextListed(uint256 tokenId) external view returns (uint256);
    function onVaultRevenue(uint256 dividendNow, uint256 dividendStream, uint256 ops) external payable;
    function floorBuy(uint256 tokenId) external payable;
}

interface IMintAIVault {
    function buyForMint(address minter, uint256 firstId, uint256 count, uint256 minTokens)
        external
        payable
        returns (uint256 vested);
    function addTeamGrants(address to, uint256 cursor, uint256 count) external;
    function onLaunched(address pair, address router, address launcher_) external;
    function sync() external;
    function bucketLeft(uint8 bucket) external view returns (uint256);
}

interface IMintAIFactory {
    function vaultOf(address token) external view returns (address);
    function launcherFactory() external view returns (address);
    function creatorExtension() external view returns (bytes32 extensionID, bytes32 creatorWord);
    function rejectScam(string calldata name, string calldata symbol) external view;
    function antiScamModule() external view returns (address);
    function marketLogic() external view returns (address);
    function notePresaleBuyer(address buyer) external;
    function presaleBuyerCount() external view returns (uint256);
    function presaleBuyer(uint256 index) external view returns (address);
}

interface IMintAILauncherFactory {
    function launchCreator() external view returns (address);
}

/// @notice Flap's per-chain anti-scam module. The two results are the name and the symbol, in that order.
interface IAntiScam {
    function isScamWord(string calldata name, string calldata symbol)
        external
        view
        returns (bool nameScam, bool symbolScam);
}

interface IMintAIDuel {
    function onTrigger(uint256 requestId) external returns (bool);
    function bindCards(address cards_) external;
    function bindVault(address vault_) external;
    function TRIGGER_DELAY() external view returns (uint256);
}

interface IMintAIUpgrades {
    function upgrade(address beacon, address newImplementation) external;
}

/// @dev Flap Trigger Service. BSC 0xcf4EE25035CF883895110f367F5BA8172416a7F9, BSC testnet
///      0x560E9830926C9e0EB98a59c6b9902383Fc0D9Eb2. Calls back `trigger(requestId)` with at most 2,000,000 gas.
interface IFlapTriggerService {
    function getFee() external view returns (uint256);
    function requestTrigger(uint64 executeAfter) external payable returns (uint256 requestId);
}

interface IV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function sync() external;
}

interface IV2Router {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
}

interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint256 amount) external returns (bool);
}

interface ITaxProcessor {
    function dispatch() external;
}

// src/MintAICardsLens.sol

interface IMintAICardsMarket {
    function lastTokenId() external view returns (uint256);
    function nextBidId() external view returns (uint256);
    function listedBits(uint256 word) external view returns (uint256);
    function openBidBits(uint256 word) external view returns (uint256);
    function listings(uint256 tokenId) external view returns (address seller, uint96 price);
    function bids(uint256 bidId) external view returns (address bidder, uint96 price, uint32 remaining);
    function paidMinted() external view returns (uint256);
    function launched() external view returns (bool);
    function launchedToken() external view returns (address);
    function router() external view returns (address);
    function priceOf(uint256 paidIndex) external pure returns (uint256);
    function OPS_BPS() external view returns (uint256);
    function floorHint() external view returns (uint256);
    function tickBits(uint256 word) external view returns (uint256);
    function tickWordBits(uint256 index) external view returns (uint256);
    function tickCount(uint256 tick) external view returns (uint256);
}

/// @notice Read-only paging over the MintAICards order book. Holds no state and no funds.
contract MintAICardsLens {
    struct ListingView {
        uint256 tokenId;
        address seller;
        uint96 price;
    }

    struct BidView {
        uint256 bidId;
        address bidder;
        uint96 price;
        uint32 remaining;
    }

    uint256 private constant MAX_PAGE = 500;
    uint256 private constant MAX_SCAN_WORDS = 3_100;
    uint256 private constant CARD_GRANT = 8_440 ether;
    uint256 private constant PRICE_TICK = 0.00001 ether;
    uint256 private constant MAX_TICK_WORDS = (1 << 20) >> 8;

    /// @notice Exact payment for the next `count` paid cards and the tokens that would vest to the buyer.
    ///         Before launch the grant is exact. After launch it is an estimate at the current pool price:
    ///         router quote, minus the 2% buy tax, minus the 10% burn. Pass a slippage-reduced value as
    ///         `minTokens` to mint.
    function quoteMint(address cards, uint256 count) external view returns (uint256 total, uint256 tokens) {
        IMintAICardsMarket c = IMintAICardsMarket(cards);
        total = c.priceOf(c.paidMinted() + 1) * count;
        if (!c.launched()) return (total, CARD_GRANT * count);
        IV2Router r = IV2Router(c.router());
        address[] memory path = new address[](2);
        path[0] = r.WETH();
        path[1] = c.launchedToken();
        uint256 spend = total - total * c.OPS_BPS() / 10_000;
        uint256 out = r.getAmountsOut(spend, path)[1];
        tokens = out * 98 / 100 * 9 / 10;
    }

    /// @notice Lowest ask price and how many cards are listed at it. (0, 0) when nothing is listed.
    function floor(address cards) external view returns (uint256 price, uint256 listed) {
        IMintAICardsMarket c = IMintAICardsMarket(cards);
        uint256 h = c.floorHint();
        uint256 word = h >> 8;
        if (word >= MAX_TICK_WORDS) return (0, 0);
        uint256 bits = c.tickBits(word) & (type(uint256).max << (h & 255));
        if (bits == 0) {
            if (++word >= MAX_TICK_WORDS) return (0, 0);
            uint256 s = word >> 8;
            uint256 summary = c.tickWordBits(s) & (type(uint256).max << (word & 255));
            while (summary == 0) {
                if (++s >= MAX_TICK_WORDS >> 8) return (0, 0);
                summary = c.tickWordBits(s);
            }
            word = s << 8;
            while (summary & 1 == 0) {
                summary >>= 1;
                ++word;
            }
            bits = c.tickBits(word);
        }
        uint256 tick = word << 8;
        while (bits & 1 == 0) {
            bits >>= 1;
            ++tick;
        }
        return (tick * PRICE_TICK, c.tickCount(tick));
    }

    /// @notice Open sell orders in token-id order. Start at cursor 0 and pass `next` back until next == end.
    function getActiveListings(address cards, uint256 cursor, uint256 limit)
        external
        view
        returns (ListingView[] memory orders, uint256 next, uint256 end)
    {
        IMintAICardsMarket c = IMintAICardsMarket(cards);
        end = c.lastTokenId() + 1;
        uint256[] memory ids;
        (ids, next) = _scan(c, true, cursor, end, limit);
        orders = new ListingView[](ids.length);
        for (uint256 i; i < ids.length; ++i) {
            (address seller, uint96 price) = c.listings(ids[i]);
            orders[i] = ListingView(ids[i], seller, price);
        }
    }

    /// @notice Open buy orders in bid-id order. Start at cursor 0 and pass `next` back until next == end.
    function getActiveBids(address cards, uint256 cursor, uint256 limit)
        external
        view
        returns (BidView[] memory orders, uint256 next, uint256 end)
    {
        IMintAICardsMarket c = IMintAICardsMarket(cards);
        end = c.nextBidId();
        uint256[] memory ids;
        (ids, next) = _scan(c, false, cursor, end, limit);
        orders = new BidView[](ids.length);
        for (uint256 i; i < ids.length; ++i) {
            (address bidder, uint96 price, uint32 remaining) = c.bids(ids[i]);
            orders[i] = BidView(ids[i], bidder, price, remaining);
        }
    }

    function _scan(IMintAICardsMarket c, bool listingsBook, uint256 cursor, uint256 end, uint256 limit)
        private
        view
        returns (uint256[] memory ids, uint256 next)
    {
        if (limit == 0 || limit > MAX_PAGE) limit = MAX_PAGE;
        ids = new uint256[](limit);
        uint256 n;
        uint256 scanned;
        while (cursor < end && n < limit && scanned < MAX_SCAN_WORDS) {
            uint256 word = cursor >> 8;
            uint256 bits = (listingsBook ? c.listedBits(word) : c.openBidBits(word)) >> (cursor & 255);
            while (bits != 0 && n < limit) {
                if (bits & 1 == 1) ids[n++] = cursor;
                bits >>= 1;
                cursor += 1;
            }
            if (bits == 0) cursor = (word + 1) << 8;
            scanned += 1;
        }
        next = cursor < end ? cursor : end;
        assembly {
            mstore(ids, n)
        }
    }
}
