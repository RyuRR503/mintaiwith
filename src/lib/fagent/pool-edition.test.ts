import { describe, expect, it } from "./test-expect.ts";
import { POOL_EDITION, mintQuote, vested, taxFlow, isPoolDeployed } from "./pool-edition.ts";

describe("pool edition rules", () => {
  it("presale card costs 0.00245 BNB and grants 8,440 tokens", () => {
    expect(mintQuote(2, "presale")).toMatchObject({ bnb: 0.0049, tokens: 16880 });
  });
  it("open mint is 0.0049, 25% ops / 75% swap", () => {
    expect(mintQuote(1, "open")).toMatchObject({ bnb: 0.0049, ops: 0.001225, swap: 0.003675 });
  });
  it("caps a mint at 10 cards", () => {
    expect(mintQuote(50, "open").count).toBe(10);
  });
  it("releases 1,688 tokens per day over 5 days", () => {
    expect(vested(8440, 1)).toBe(1688);
    expect(vested(8440, 9)).toBe(8440);
  });
  it("splits 2% tax 50/30/20", () => {
    const f = taxFlow(100);
    expect([f.tax, f.dividend, f.floor, f.ops].map(v => +v.toFixed(6))).toEqual([2, 1, 0.6, 0.4]);
  });
  it("supply adds up and is not deployed yet", () => {
    expect(POOL_EDITION.paidCards + POOL_EDITION.teamCards).toBe(POOL_EDITION.totalCards);
    expect(POOL_EDITION.presaleCards * POOL_EDITION.presalePrice).toBeCloseTo(49);
    expect(isPoolDeployed()).toBe(false);
  });
});
