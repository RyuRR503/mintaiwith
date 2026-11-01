export const FAGENT = {
  chainId: 56,
  token: "0x457badee84b6be7539458eac993983058c7f7777",
  vault: "0xbc2d8b6f4c4e2803c5e842e6e8250b79ee442b78",
  factory: "0x150209007c2c6176796DB254d792f976b6FBF931",
} as const;

export function liveSupply(paid: number, teamMinted: number, total: number, paidPerBatch = 9500) {
  return { minted: paid + teamMinted, remaining: total - paid - teamMinted, batch: Math.min(77, Math.floor(paid / paidPerBatch) + 1), batchPaid: paid === 731500 ? paidPerBatch : paid % paidPerBatch, activatedTeam: Math.floor(paid / 19) };
}
export function redemptionReady(accounted: boolean, openedAt: number, releaseSeconds: number, chainTime: number) {
  return accounted || (openedAt > 0 && chainTime >= openedAt + releaseSeconds);
}
export const explorer = (address: string) => `https://bscscan.com/address/${address}`;