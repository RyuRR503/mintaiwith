import { describe, expect, it } from "./test-expect.ts";
import { previewOrderBook } from "./edition-demo.ts";

describe("market preview order limits", () => {
  it("shows only the first 20 sell orders", () => {
    const { sells } = previewOrderBook();
    expect(sells).toHaveLength(20);
    expect(sells[0]?.price).toBe("0.018");
    expect(sells[19]?.price).toBe("0.094");
  });
  it("shows only the first 20 buy orders", () => {
    const { buys } = previewOrderBook();
    expect(buys).toHaveLength(20);
    expect(buys[0]?.price).toBe("0.112");
    expect(buys[19]?.price).toBe("0.036");
  });
});