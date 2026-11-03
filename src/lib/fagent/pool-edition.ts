// Rules of the undeployed Flap Pool Launch edition (fagent-pool-vault package, 2026-11-03).
// Display-only: the live site still reads the deployed vault in config.ts.
export const POOL_EDITION = {
  vault: "" as string, // fill after deployment
  cards: "" as string,
  totalCards: 777_777,
  paidCards: 738_889,
  teamCards: 38_888,
  teamEvery: 19,
  maxPerAddress: 10,
  presaleCards: 20_000,
  presalePrice: 0.00245,
  openPrice: 0.0049,
  opsShareOpen: 0.25,
  mintBurnShare: 0.3,
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

export const isPoolDeployed = () => POOL_EDITION.vault.length === 42;

export function mintQuote(count: number, phase: "presale" | "open") {
  const n = Math.max(1, Math.min(POOL_EDITION.maxPerAddress, Math.floor(count)));
  if (phase === "presale") {
    return { count: n, bnb: +(n * POOL_EDITION.presalePrice).toFixed(6), tokens: n * POOL_EDITION.cardGrant, ops: 0, swap: 0 };
  }
  const bnb = n * POOL_EDITION.openPrice;
  return { count: n, bnb: +bnb.toFixed(6), ops: +(bnb * POOL_EDITION.opsShareOpen).toFixed(6), swap: +(bnb * (1 - POOL_EDITION.opsShareOpen)).toFixed(6), tokens: null as number | null };
}

/** Linear 5-day release: unlocked tokens after `days`. */
export function vested(total: number, days: number) {
  const r = Math.max(0, Math.min(1, days / POOL_EDITION.vestDays));
  return Math.floor(total * r);
}

export function taxFlow(volumeBnb: number) {
  const tax = volumeBnb * POOL_EDITION.taxRate;
  const s = POOL_EDITION.taxSplit;
  return { tax, dividend: tax * s.dividend, floor: tax * s.floor, ops: tax * s.ops };
}
