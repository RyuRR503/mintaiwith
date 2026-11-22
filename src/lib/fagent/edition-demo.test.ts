import { describe, expect, it } from "./test-expect.ts";
import { previewOrderBook } from "./edition-demo.ts";

describe("market preview order limits", () => {
  it("shows only the first 20 sell orders", () => {
    const { sells } = previewOrderBook();
    expect(sells).toHaveLength(20);
    expect(sells[0]?.price).toBe("0.018");
    expect(sells[19]?.price).toBe("0.062");
  });
  for (const tier of [0, 1, 2, 3]) {
    it(`shows 20 sell orders exclusively for rarity ${tier}`, () => {
      const { sells } = previewOrderBook(tier);
      expect(sells).toHaveLength(20);
      expect(sells.every(order => order.tier === tier)).toBe(true);
      expect(sells[0]?.price).toBe((0.018 + tier * 0.02).toFixed(3));
    });
  }
  it("keeps all 20 universal bids identical across rarities", () => {
    for (const tier of [0, 1, 2, 3]) {
      expect(previewOrderBook(tier).buys).toEqual(previewOrderBook().buys);
    }
  });
  it("shows only the first 20 buy orders", () => {
    const { buys } = previewOrderBook();
    expect(buys).toHaveLength(20);
    expect(buys[0]?.price).toBe("0.112");
    expect(buys[19]?.price).toBe("0.036");
  });
});