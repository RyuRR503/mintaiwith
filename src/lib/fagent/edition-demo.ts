/** Local presentation fixtures only. Never used for chain reads or transaction commands. */
export const EDITION_DEMO = {
  paidMinted: 12680,
  burnedCards: 128,
  burnedTokens: 286125939,
  dividends: "24.86",
  floor: "3.72",
  liquidity: "1.46",
  operations: "9.94",
  sellOrders: Array.from({ length: 24 }, (_, i) => ({
    id: 128 + i * 397, tier: i % 4, price: (0.018 + i * 0.004).toFixed(3),
    dividend: (0.0021 + i * 0.0003).toFixed(4),
  })),
  buyOrders: Array.from({ length: 24 }, (_, i) => ({
    id: i + 1, tier: i % 4, price: (0.112 - i * 0.004).toFixed(3), quantity: 1 + i % 5,
  })),
  cards: [
    { id: 128, tier: 0, price: "0.018", dividend: "0.0021", wins: 0 },
    { id: 2067, tier: 1, price: "0.034", dividend: "0.0053", wins: 2 },
    { id: 8421, tier: 2, price: "0.072", dividend: "0.0147", wins: 3 },
    { id: 10986, tier: 3, price: "0.148", dividend: "0.042", wins: 5 },
  ],
  ledger: [
    { time: "15:42", kind: ["持卡分红", "Card dividends"], amount: "+0.84", balance: "24.86" },
    { time: "15:36", kind: ["地板回购 · #000128", "Floor buyback · #000128"], amount: "−0.018", balance: "3.72" },
    { time: "15:30", kind: ["流动性注入", "Liquidity addition"], amount: "−0.50", balance: "1.46" },
    { time: "15:24", kind: ["交易税到账", "Trading tax received"], amount: "+1.20", balance: "7.68" },
  ],
} as const;

/** Display-only order book, best price first, with a separate limit for each side. */
export function previewOrderBook() {
  return {
    sells: [...EDITION_DEMO.sellOrders].sort((a, b) => Number(a.price) - Number(b.price)).slice(0, 20),
    buys: [...EDITION_DEMO.buyOrders].sort((a, b) => Number(b.price) - Number(a.price)).slice(0, 20),
  };
}