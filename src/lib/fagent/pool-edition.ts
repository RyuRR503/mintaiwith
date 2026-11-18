import { FAGENT } from "./config";
// Rules from fagent-pool-vault-duel.zip; live addresses discovered from the card.
export const POOL_EDITION = {
  vault: "" as string, // never substitute a factory; discovered through cards.vault()
  cards: FAGENT.cards,
  totalCards: 777_777,
  paidCards: 738_889,
  teamCards: 38_888,
  teamEvery: 19,
  maxPerAddress: 10,
  presaleCards: 20_000,
  presalePrice: 0.00245,
  openPrice: 0.0049,
  opsShareOpen: 0.25,
  mintBurnShare: 0.1,
  cardGrant: 8_440,
  vestDays: 5,
  totalTokens: 777_777_777,
  poolBnb: 36.75,
  poolTokens: 124_672_000,
  presaleOps: 12.25,
  taxRate: 0.02,
  taxSplit: { dividend: 0.5, floor: 0.3, ops: 0.2 },
  floorTrigger: 0.02,
  sweepMinutes: 30,
  presaleWindowDays: 7,
} as const;

export const isPoolDeployed = () => POOL_EDITION.cards.length === 42;

export function mintQuote(count: number, phase: "presale" | "open") {
  const n = Math.max(1, Math.min(POOL_EDITION.maxPerAddress, Math.floor(count)));
  if (phase === "presale") {
    return { count: n, bnb: +(n * POOL_EDITION.presalePrice).toFixed(6), tokens: n * POOL_EDITION.cardGrant, ops: 0, swap: 0 };
  }
  const bnb = n * POOL_EDITION.openPrice;
  return { count: n, bnb: +bnb.toFixed(6), ops: +(bnb * POOL_EDITION.opsShareOpen).toFixed(6), swap: +(bnb * (1 - POOL_EDITION.opsShareOpen)).toFixed(6), tokens: null as number | null };
}

/** Presale grants release 20% at launch and the remainder over five days. */
export function vested(total: number, days: number) {
  const r = Math.max(0, Math.min(1, days / POOL_EDITION.vestDays));
  const upfront = Math.floor(total / 5);
  return upfront + Math.floor((total - upfront) * r);
}

export function taxFlow(volumeBnb: number) {
  const tax = volumeBnb * POOL_EDITION.taxRate;
  const s = POOL_EDITION.taxSplit;
  return { tax, dividend: tax * s.dividend, floor: tax * s.floor, ops: tax * s.ops };
}

/** Token allocation from the pool-edition contract; team share is the remainder after the four fixed buckets. */
export const ALLOCATION = (() => {
  const fixed = [
    { key: "pool", label: "开池流动性", amount: 124_672_000, note: "与 36.75 BNB 一起进池，LP 销毁" },
    { key: "presale", label: "预售卡发放", amount: 168_800_000, note: "20,000 张 × 8,440 枚，开池后 5 天释放" },
    { key: "ladder", label: "阶梯卖单", amount: 58_611_119, note: "币价涨到 1.5 / 2 / 3 倍才卖，BNB 全给持卡人" },
    { key: "burn", label: "开池销毁", amount: 97_479_938, note: "开池时打入黑洞地址" },
  ];
  const team = POOL_EDITION.totalTokens - fixed.reduce((a, b) => a + b.amount, 0);
  return [...fixed, { key: "team", label: "团队卡", amount: team, note: "锁仓中：每铸出 19 张付费卡才解锁 1 张，没人铸造就一直锁着" }];
})();

export function poolStatus(minted: number) {
  const presaleLeft = Math.max(0, POOL_EDITION.presaleCards - minted);
  return {
    phase: presaleLeft > 0 ? "presale" as const : "open" as const,
    presalePct: Math.min(100, (minted / POOL_EDITION.presaleCards) * 100),
    totalPct: (minted / POOL_EDITION.totalCards) * 100,
    presaleLeft,
  };
}
