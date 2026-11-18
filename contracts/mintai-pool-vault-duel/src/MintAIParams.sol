// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Launch economics shared by the cards, the factory and the vault.
library MintAIParams {
    uint256 internal constant TOTAL_SUPPLY = 777_777_777 ether;
    uint256 internal constant POOL_TOKEN = 124_672_000 ether;
    /// @dev 75% of the 49 BNB presale. The other 25% goes to ops at launch.
    uint256 internal constant POOL_QUOTE = 36.75 ether;
    uint256 internal constant RESERVE = TOTAL_SUPPLY - POOL_TOKEN;

    /// @dev Tokens vested to every presale card and every team card.
    uint256 internal constant CARD_GRANT = 8_440 ether;
    uint256 internal constant PRESALE_CARDS = 20_000;
    uint256 internal constant TEAM_CARDS = 38_888;

    /// @dev Reserve buckets. UNALLOCATED is burned to the dead address inside the launch transaction.
    uint256 internal constant GRANT_BUDGET = (PRESALE_CARDS + TEAM_CARDS) * CARD_GRANT;
    uint256 internal constant LADDER_BUDGET = 58_611_119 ether;
    uint256 internal constant UNALLOCATED = RESERVE - GRANT_BUDGET - LADDER_BUDGET;

    uint16 internal constant TAX_BPS = 200;
    uint32 internal constant TAX_DURATION = type(uint32).max;

    /// @dev Vault revenue split, in bps of what the VAULT slot delivers.
    uint256 internal constant DIVIDEND_BPS = 5_000;
    uint256 internal constant FLOOR_BPS = 3_000;
    uint256 internal constant OPS_BPS = 2_000;

    /// @dev Share of the tokens bought by a post-open mint that is burned; the rest vests to the minter.
    uint256 internal constant MINT_BURN_BPS = 1_000;

    /// @dev Three rungs. 5x and above cannot clear: the presale grant is larger than the pool, so a full
    ///      sell takes the price well below the opening price, and climbing back past 3x already needs the
    ///      pool to hold roughly 68 BNB against the opening token reserve.
    uint256 internal constant LADDER_RUNGS = 3;

    uint8 internal constant BUCKET_GRANT = 0;
    uint8 internal constant BUCKET_LADDER = 1;

    error BadLadderRung();

    /// @dev Tokens in a rung. The first two are equal; the last takes the remainder so the three sum to the budget.
    function ladderRungTokens(uint256 rung) internal pure returns (uint256) {
        if (rung >= LADDER_RUNGS) revert BadLadderRung();
        uint256 base = LADDER_BUDGET / LADDER_RUNGS;
        if (rung + 1 == LADDER_RUNGS) return LADDER_BUDGET - base * (LADDER_RUNGS - 1);
        return base;
    }

    /// @dev 1.5x, 2x, 3x of the opening price, as a fraction.
    function ladderMultiple(uint256 rung) internal pure returns (uint256 num, uint256 den) {
        if (rung == 0) return (3, 2);
        if (rung == 1) return (2, 1);
        if (rung == 2) return (3, 1);
        revert BadLadderRung();
    }

    /// @dev Opening price in BNB wei per 1e18 token wei.
    function openingPrice() internal pure returns (uint256) {
        return POOL_QUOTE * 1e18 / POOL_TOKEN;
    }
}
