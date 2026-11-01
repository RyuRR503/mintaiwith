/** Values transcribed from the uploaded AgentCardVault.sol. */
export const CARD_RULES = {
  supply: 770_000,
  batches: 77,
  cardsPerBatch: 10_000,
  paidPerBatch: 9_500,
  teamPerBatch: 500,
  lifetimeMints: 7,
  mintPriceBnb: 0.002,
  buybackBps: 8_000,
  opsBps: 2_000,
  marketFeeBps: 100,
} as const;

export function mintRemaining(used: number) {
  return Math.max(0, CARD_RULES.lifetimeMints - used);
}

/** Preview-only seed: 12,000 paid cards, with one team card activated per 19 paid. */
export function previewSupply(additionalPaid = 0) {
  const paid = 12_000 + additionalPaid;
  const team = Math.floor(paid / 19);
  const minted = paid + team;
  return { minted, remaining: CARD_RULES.supply - minted, batch: Math.floor(paid / CARD_RULES.paidPerBatch) + 1, batchPaid: paid % CARD_RULES.paidPerBatch };
}

export function mintSplit() {
  return {
    buyback: CARD_RULES.mintPriceBnb * CARD_RULES.buybackBps / 10_000,
    ops: CARD_RULES.mintPriceBnb * CARD_RULES.opsBps / 10_000,
  };
}

export function batchForCard(tokenId: number) {
  return Math.floor(tokenId / CARD_RULES.cardsPerBatch) + 1;
}

export function canRedeem(batchPaid: number) {
  return batchPaid === CARD_RULES.paidPerBatch;
}

export type PreviewCard = { id: number; price: number; dividend: number; closed: boolean };
export const PREVIEW_LISTINGS: PreviewCard[] = [
  { id: 627, price: 0.0031, dividend: 0.00012, closed: true },
  { id: 1884, price: 0.0028, dividend: 0.00008, closed: true },
  { id: 10536, price: 0.0024, dividend: 0, closed: false },
  { id: 11079, price: 0.0036, dividend: 0, closed: false },
];