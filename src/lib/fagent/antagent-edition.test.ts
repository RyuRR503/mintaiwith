import { describe, it, expect } from "./test-expect.ts";
import { ANTAGENT_EDITION as e, antagentPrice, antagentQuote, ageDiscount } from "./antagent-edition.ts";
describe("ANTAGENT 2026-11-22 source rules", () => {
  it("uses ANTB, not the retired BNB quote", () => {
    expect(e.quote).toBe("ANTB");
    expect(e.quoteAddress).toBe("0x38Dd26788Cf2d901E3aBf04efE3007d459d0Fc53");
  });
  it("does not treat the new edition as deployed", () => { expect(e.deploymentConfirmed).toBe(false); });
  it("opens at 8429 cards with 120 ANTB and 63300000 tokens", () => { expect([e.presaleCards, e.poolQuote, e.poolTokens]).toEqual([8429, 120, 63300000]); });
  it("limits mints to 10 per tx, 10 before and 20 total after launch", () => { expect([e.maxPerTx, e.maxBefore, e.maxAfter]).toEqual([10, 10, 20]); });
  it("preserves all four rarity inventories and weights", () => {
    expect(e.tiers.map(t => [t.count, t.weight])).toEqual([[453767, 2], [246612, 5], [58428, 14], [18970, 40]]);
    expect(e.tiers.reduce((n, t) => n + t.count, 0)).toBe(777777);
  });
  it("prices the 1000-card boundaries exactly and caps at 0.16 ANTB", () => {
    expect([antagentPrice(1), antagentPrice(1000), antagentPrice(1001), antagentPrice(180001), antagentPrice(758032)]).toEqual([16000000000000000n, 16000000000000000n, 16800000000000000n, 160000000000000000n, 160000000000000000n]);
  });
  it("sums each card across rungs instead of using one batch price", () => { expect(antagentQuote(1000, 2)).toBe(32800000000000000n); });
  it("matches exact historical-proof block thresholds", () => { expect([ageDiscount(1919999), ageDiscount(1920000), ageDiscount(3840000), ageDiscount(5760000)]).toEqual([10000, 9000, 8500, 8000]); });
  it("applies the selected discount to each card", () => { expect(antagentQuote(1000, 2, 8500)).toBe(27880000000000000n); });
  it("accounts for changed card and token supply", () => {
    expect(e.paidCards + e.teamCards).toBe(777777);
    expect(e.poolTokens + (e.presaleCards + e.teamCards) * e.cardGrant + e.ladderTokens + e.burnedAtLaunch).toBe(777777777);
    expect(e.burnedAtLaunch).toBe(446930459);
  });
  it("uses 2 percent tax and the 50/15/15/20 vault allocation", () => { expect([e.taxBps, e.dividendBps, e.floorBps, e.poolBps, e.opsBps]).toEqual([200, 5000, 1500, 1500, 2000]); });
});