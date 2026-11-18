# Flap Vault Interaction Risk Report

Generated: 2026-11-03 03:47:21 UTC

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
### Finding 1: Developer contracts use custom errors instead of require() with literal string messages (SYS-REQ-LITERAL-ERRORS)
- **Severity:** High
- **Confidence:** High
- **Detected by:** rule_review
- **Description:** All four developer-authored contracts (MintAICards, MintAIVault, MintAIVaultFactory/MintAIVaultFactoryDeployer, and the shared MintAIParams library) declare and revert with custom errors instead of using require() with literal string messages. This violates SYS-REQ-LITERAL-ERRORS: every developer revert path must take the form require(condition, "message") so the Flap UI can display human-readable messages. Users interacting through the UI will see opaque 4-byte error selectors rather than readable error messages across essentially every revert path in the system (mint, launch, refund, claim, market, vesting, floor sweep, trigger arming, factory validation, etc.).
- **Vulnerable Code:**
  - `src/MintAICards.sol: error declarations ZeroAddress, NotOwnerOrGuardian, NotGuardian, NotVault, NotLaunched, AlreadyLaunched, PresaleClosed, PresaleNotFailed, PresaleFull, PresaleNotSoldOut, LaunchClosed, SoldOut, AgentIdRequired, MintCapReached, BadCount, WrongPayment, NotCardOwner, NotTeam, TeamNotUnlocked, TransferLocked, NothingToClaim, PayFailed, BadOrder, BadPrice, NotBidder, BidFilled, NothingBought, OccupiedFunds, LaunchFailed, SaltLocked, SaltNotLocked, IdentityLocked, BadRouter, ZeroMinTokens and all corresponding `revert X()` statements`
  - `src/MintAIVault.sol: error declarations NotCards, NotTrigger, UnknownTrigger, WrongToken, AlreadyDistributed, BadDistribution, NotLaunched, AlreadyLaunched, BucketExceeded, BadBucket, BadRung, RungNotReached, TwapNotReady, RungSoldOut, WrongPayment, PayFailed, BadPair, Slippage, NothingToClaim and all corresponding `revert X()` statements`
  - `src/MintAIVaultFactory.sol: error declarations UnsupportedLaunchKind, BadCreator, NotLaunching, AlreadyLaunched, BadLaunch, ZeroAddress and all corresponding `revert X()` statements`
  - `src/MintAIParams.sol: error BadLadderRung and `revert BadLadderRung()``
  - `src/flap/LaunchVaultAddresses.sol: error UnsupportedChain and `revert UnsupportedChain(id)``
  - `src/flap/DirectLaunchBases.sol: DirectLaunchAccess error declarations NotHub, NotGuardian, TokenDockNotConfigured and corresponding reverts`

> **Status:** `[ ]` TP　`[ ]` FP　`[x]` By Design　`[ ]` Acknowledged
> **Reason (if FP / By Design / Acknowledged):** This vault ships with a custom UI, not the generic Flap UI that renders require() strings. The custom UI maps these custom error selectors to its own text. MintAICards is also within a few hundred bytes of the 24KB limit, so converting every revert to a require string would make it undeployable. No fund accounting depends on the error format.

### Finding 2: MintAIVault.vaultUISchema omits the msg.value field for payable buyLadder, so UI-generated calls always revert
- **Severity:** Low
- **Confidence:** Low
- **Detected by:** attacker_review
- **Description:** buyLadder(uint256 rung, uint256 amount) is a payable function that requires msg.value >= cost, where cost = ceil(amount * rungPrice / 1e18) is strictly positive for any amount > 0. The vault's vaultUISchema declares buyLadder as a write method with only two inputs ('rung' and 'amount'), and no FieldDescriptor of fieldType 'msg.value'. Per the Vault UI schema contract, the native value attached to a write transaction is taken exclusively from a 'msg.value' input field; with none declared, a generic UI constructs the call with zero value. The on-chain buyLadder then reverts with WrongPayment(cost, 0). As a result, the ladder-purchase method advertised by the vault's own UI schema cannot be executed through the generated UI.
- **Vulnerable Code:**
  - `src/MintAIVault.sol:vaultUISchema (methods[1] buyLadder)`
  - `src/MintAIVault.sol:buyLadder`

> **Status:** `[x]` TP　`[ ]` FP　`[ ]` By Design　`[ ]` Acknowledged
> **Reason (if FP / By Design / Acknowledged):** Fixed. `vaultUISchema` buyLadder now includes `FieldDescriptor("value", "msg.value", "BNB payment. Must cover the rung cost. Excess is refunded.", 18)`. The function arguments are unchanged. Excess BNB is still refunded.

### Finding 3: floorHint lower-bound hint is dead code: it is initialized to 0 and the update condition can never fire, so it never tracks the lowest listed tick
- **Severity:** Low
- **Confidence:** Low
- **Detected by:** attacker_review
- **Description:** MintAICards.floorHint is declared without an initializer (value 0) and is only ever written in list() via `if (tick < floorHint) floorHint = tick;`. Because every valid listing tick is >= 1 (list() reverts BadPrice when `tick == 0`), the condition `tick < 0` is never true, so floorHint remains 0 for the contract's entire lifetime. The intended behavior is that floorHint tracks a lower bound on the lowest listed price tick so that the floor-fund sweep (MintAIVault._sweep → nextTick(floorHint)) and MintAICardsLens.floor()/getActiveListings can begin scanning near the actual floor. The actual behavior is that both consumers always start their scan from tick 0. Correctness is preserved (nextTick/the lens summary-bitmap walk still locate the true lowest tick and are bounded to ~17 reads), so there is no fund loss or DoS, but the designed optimization provably never engages — the write site is effectively dead code.
- **Vulnerable Code:**
  - `src/MintAICards.sol: state var floorHint`
  - `src/MintAICards.sol: list() -> `if (tick < floorHint) floorHint = tick;``

> **Status:** `[ ]` TP　`[ ]` FP　`[ ]` By Design　`[x]` Acknowledged
> **Reason (if FP / By Design / Acknowledged):** The observation is correct: floorHint stays 0. nextTick and the lens still find the real lowest tick from tick 0, within the existing read bound. There is no fund loss and no DoS. Left unchanged because MintAICards is close to the 24KB limit and this hint does not affect settlement.

### Finding 4: MintAIVault._arm pays the Trigger fee but does not debit triggerReserve when the service returns requestId == 0
- **Severity:** Low
- **Confidence:** Low
- **Detected by:** attacker_review
- **Description:** In _arm, the call IFlapTriggerService(svc).requestTrigger{value: fee}(when) transfers `fee` BNB to the Trigger Service as part of the call. When the call returns successfully but with requestId == 0, the function emits TriggerSkipped("id") and returns WITHOUT executing `triggerReserve -= fee`. The BNB has already left the contract, but the storage accumulator triggerReserve is not reduced. This desynchronizes triggerReserve from the actual BNB held, so floorFund + triggerReserve becomes larger than the real reserved balance. Because unrecognizedTax() = balance - floorFund - triggerReserve (clamped to 0), the phantom `fee` amount is permanently excluded from future tax recognition (and, if it pushes the held total above the balance, suppresses recognition entirely until enough new tax accrues), effectively stranding revenue that should have been split to dividends/floor/ops.
- **Vulnerable Code:**
  - `src/MintAIVault.sol:MintAIVault._arm (requestId == 0 branch)`

> **Status:** `[x]` TP　`[ ]` FP　`[ ]` By Design　`[ ]` Acknowledged
> **Reason (if FP / By Design / Acknowledged):** Fixed. A successful `requestTrigger` now debits `triggerReserve` before the `requestId == 0` return, so the fee that already left is counted. No request id is stored in that case, so a later call can arm again. A reverting call still takes the catch path: the fee is reverted with the call and `triggerReserve` is not debited. A non-zero id still records `pendingTriggerId` and `triggerDueAt` as before.
