export const FAGENT = {
  chainId: 56,
  cards: "0xc781e11A506F9d8DfCd38B1125A4ccDC199EB36F",
  launcherFactory: "0x2312DE6a1f6281c723F530b7E009F18c3c204BE9",
  factory: "0x798D1a41C4EfEa013b1d293ae1134339b8CA31b6",
  duel: "0x2617efF6dEB81cD398c2C7d774BE1Fc9714e4dec",
  orderbook: "0x85b6CfD82a9B0589dc255cB47a1351181366Dba5",
  upgradeManager: "0xF3213fbDF1D1C993362725a68AcBa883520D7D2C5",
} as const;
export const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
export const deployedAddress = (address: string) => /^0x[0-9a-fA-F]{40}$/.test(address) && address.toLowerCase() !== ZERO_ADDRESS;
export function launchPhase(launched: boolean, paid: number, deadline: number, filledAt: number, time: number) {
  // Deployed contract: the mint that sells the 20,000th card opens the pool in the same
  // transaction, so a sold-out presale can never enter a refund state.
  if (launched) return "open";
  if (paid < 20000) return time > deadline ? "refund" : "presale";
  return "ready";
}

export function liveSupply(paid: number, teamMinted: number, total: number, paidPerBatch = 9500) {
  return { minted: paid + teamMinted, remaining: total - paid - teamMinted, batch: Math.min(77, Math.floor(paid / paidPerBatch) + 1), batchPaid: paid === 731500 ? paidPerBatch : paid % paidPerBatch, activatedTeam: Math.floor(paid / 19) };
}
export function redemptionReady(accounted: boolean, openedAt: number, releaseSeconds: number, chainTime: number) {
  return accounted || (openedAt > 0 && chainTime >= openedAt + releaseSeconds);
}
export const explorer = (address: string) => `https://bscscan.com/address/${address}`;