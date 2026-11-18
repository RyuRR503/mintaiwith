# Flap Vault Interaction Risk Report

Generated: 2026-11-04 05:25:31 UTC

## Vault Security Rating
**High**

## Status Guide / 状态说明

Please review each finding below and mark its status. / 请审阅以下每条发现并标记状态。

| Status | Meaning / 含义 |
|:---:|---|
| **TP** | True Positive — This is a real issue, we will fix it. / 确认问题，我们会修复。 |
| **FP** | False Positive — This is not a real issue, the analysis is incorrect. / 误报，分析有误。 |
| **By Design** | This is intentional behavior, not a bug. / 这是设计如此，非缺陷。 |
| **Acknowledged** | The issue is real but the impact is acceptable, will not fix. / 问题确实存在，但影响在可接受范围内，不修复。 |

Mark by replacing `[ ]` with `[x]`. If FP, By Design, or Acknowledged, please write a brief reason. / 在对应选项的 `[ ]` 中填入 `x` 标记。如标记 FP、By Design 或 Acknowledged，请简要说明理由。

---

## Risk Findings


### Finding 3: Tiny ladder purchases can repeatedly postpone existing dividend streams
- **Severity:** Medium
- **Confidence:** Medium
- **Detected by:** attacker_review
- **Description:** Every nonzero ladder purchase restarts the seven-day release period for all remaining streamed dividends. A buyer can repeatedly purchase a negligible token amount and reset streamEnd, delaying completion of distributions funded by other buyers. There is no minimum purchase size or separate schedule preventing a tiny new payment from rescheduling a much larger existing stream.
- **Vulnerable Code:**
  - `src/MintAICards.sol:MintAICards.onVaultRevenue`
  - `src/MintAICards.sol:MintAICards._streamDue`
  - `src/MintAICards.sol:MintAICards._accrueStream`
  - `src/MintAIVault.sol:MintAIVault.buyLadder`

> **Status:** `[x]` TP　`[ ]` FP　`[ ]` By Design　`[ ]` Acknowledged
> **Reason (if FP / By Design / Acknowledged):** Fixed in `MintAICards.onVaultRevenue`. Elapsed stream is still released first. If a stream is already running, a new ladder payment is added to the unpaid remainder and the existing end date stays. If nothing is left to stream, or the end date has passed, the new payment starts its own seven days. `StreamAdded` was removed so the cards contract stays within 24,576 bytes (runtime 24,535).

### Finding 5: New cards dilute dividend streams funded before their mint
- **Severity:** Medium
- **Confidence:** Medium
- **Detected by:** attacker_review
- **Description:** The dividend accounting excludes new cards from already indexed rewards but not from previously funded, unreleased streams. _addWeight() accrues only the elapsed portion before adding a new card. Subsequent releases of the old stream use the enlarged totalWeight, giving new paid or team cards part of revenue received before they existed and reducing the original cards' allocation.
- **Vulnerable Code:**
  - `src/MintAICards.sol:MintAICards._addWeight`
  - `src/MintAICards.sol:MintAICards._accrueStream`
  - `src/MintAICards.sol:MintAICards._index`
  - `src/MintAICards.sol:MintAICards.mint`
  - `src/MintAICards.sol:MintAICards.mintTeam`

> **Status:** `[ ]` TP　`[ ]` FP　`[ ]` By Design　`[x]` Acknowledged
> **Reason (if FP / By Design / Acknowledged):** A new card misses dividends already indexed, and it does share later releases of a stream funded before it existed. Every card that exists while BNB is released shares that release. Accepted. Not changed.

### Finding 6: Saved sweep cursors allow expensive cards to bypass newly cheaper listings
- **Severity:** Medium
- **Confidence:** Medium
- **Detected by:** attacker_review
- **Description:** A resumed floor sweep validates only the saved card's existence and price tick. It does not check whether cheaper listings have appeared since the cursor was saved. The sweep can therefore spend the available floor fund on more expensive cards while cheaper eligible cards remain listed, defeating its cheapest-first purchase policy. Cached successor links can also become invalid during native payout callbacks and cause remaining listings at a lower tick to be skipped.
- **Vulnerable Code:**
  - `src/MintAIVault.sol:MintAIVault._sweep`
  - `src/MintAICards.sol:MintAICards.list`
  - `src/MintAICards.sol:MintAICards._clearListing`
  - `src/MintAICards.sol:MintAICards._update`
  - `src/MintAICards.sol:MintAICards._payOrCredit`

> **Status:** `[x]` TP　`[ ]` FP　`[ ]` By Design　`[ ]` Acknowledged
> **Reason (if FP / By Design / Acknowledged):** Fixed in `MintAIVault._sweep` only. `MintAICards` was not modified. Before each buy, a cheaper tick than the saved cursor drops the cursor and the sweep starts at that tick's head. After a successful buy, if the cached next card was unlisted, the same tick is read again from its head. A tick already left behind in the same pass is not selected again, so an over-cap listing cannot spin the sweep.

### Finding 7: Unbounded TWAP observation age permits stale ladder eligibility
- **Severity:** Medium
- **Confidence:** Medium
- **Detected by:** attacker_review
- **Description:** Ladder eligibility is described as depending on a 30-minute TWAP, but twapPrice() can average over an arbitrarily old observation. Pool trading does not refresh the Vault's observations, there is no maximum observation age, and buyLadder checks the price before refreshing observations. Old high-price history can therefore keep a rung open after the recent market has fallen below it, while old low-price history can block a rung after a sustained recent rise.
- **Vulnerable Code:**
  - `src/MintAIVault.sol:MintAIVault.twapPrice`
  - `src/MintAIVault.sol:MintAIVault._poke`
  - `src/MintAIVault.sol:MintAIVault.buyLadder`
  - `src/MintAIVault.sol:MintAIVault.onLaunched`

> **Status:** `[x]` TP　`[ ]` FP　`[ ]` By Design　`[ ]` Acknowledged
> **Reason (if FP / By Design / Acknowledged):** Fixed. `buyLadder` refreshes observations before the price check. If the newest observation is more than 60 minutes old, both observations restart at the current cumulative and `twapPrice` stays `TwapNotReady` until a new full 30-minute window exists. A gap of 30 to 60 minutes still rolls the window. `twapPrice` also rejects a window longer than 60 minutes.

### Finding 8: Factory policy operators are incompatible with the declared schema
- **Severity:** Medium
- **Confidence:** Medium
- **Detected by:** attacker_review
- **Description:** tokenCreationPolicies() returns "==" for every policy operator, while the supplied FactoryPolicy specification defines equality as "eq" and requires unknown operators to be ignored. A conforming schema consumer therefore ignores all six declared creation constraints instead of performing the intended machine-readable validation.
- **Vulnerable Code:**
  - `src/MintAIVaultFactory.sol:MintAIVaultFactory.tokenCreationPolicies`

> **Status:** `[x]` TP　`[ ]` FP　`[ ]` By Design　`[ ]` Acknowledged
> **Reason (if FP / By Design / Acknowledged):** Fixed. All six `tokenCreationPolicies` operators are now `"eq"`. The on-chain `newVault` checks are unchanged.

### Finding 9: 20% ops share of vault tax revenue exceeds the factory commission formula for a 2% tax (SYS-REQ-COMMISSION)
- **Severity:** Informational
- **Confidence:** Low
- **Detected by:** rule_review
- **Description:** SYS-REQ-COMMISSION is violated. MintAIVault._recognize sends a flat 20% (OPS_BPS = 2,000) of all recognized tax revenue to MintAICards as `ops`. MintAICards._pushOps then pays that amount to the owner-configurable opsWallet. For a factory-deployed vault with a 2% (200 bps) tax, the permitted developer commission is msg.value * 6 / 200, which is 3% of revenue. The hardcoded 20% is a non-standard developer fee well above that cap.
- **Vulnerable Code:**
  - `MintAIVault._recognize: toOps = fresh * P.OPS_BPS / BPS (OPS_BPS = 2000)`
  - `MintAIParams.OPS_BPS = 2_000`
  - `MintAICards.onVaultRevenue: opsOwed += ops`
  - `MintAICards._pushOps: payment to opsWallet`

> **Status:** `[ ]` TP　`[ ]` FP　`[x]` By Design　`[ ]` Acknowledged
> **Reason (if FP / By Design / Acknowledged):** Recognized tax is split 50% to card dividends, 30% to the floor fund, and 20% to ops (`OPS_BPS = 2000`). `description()` states this split. Ops does receive 20%. The 3% formula (`msg.value * 6 / 200`) is not the rule for this vault. Not changed.

