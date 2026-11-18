import { createPublicClient, fallback, http, formatEther, formatUnits, getAbiItem, parseAbi, type Address } from "viem";
import { bsc } from "viem/chains";
import { FAGENT, deployedAddress, launchPhase } from "./config";
import { cardsAbi } from "./cards-abi";
import { lensAbi } from "./lens-abi";
import { poolVaultAbi } from "./pool-vault-abi";
import { estimatedMarketVolume, formatBnb } from "./market";
const factoryAbi = parseAbi(["function presaleBuyerCount() view returns (uint256)"]);
const agentAbi = parseAbi(["function balanceOf(address) view returns (uint256)"]);
function client() {
  return createPublicClient({ chain: bsc, transport: fallback([
    http("https://bsc-rpc.publicnode.com", { timeout: 12000, retryCount: 0 }),
    http("https://bsc-dataseed.bnbchain.org", { timeout: 10000, retryCount: 0 }),
  ], { rank: false, retryCount: 0 }) });
}
export async function readSnapshot() {
  const c = client(); const block = await c.getBlock();
  const names = ["paidMinted", "teamMinted", "lastTokenId", "presaleEscrow", "presaleDeadline", "presaleFilledAt", "launched", "vault", "launchedToken", "totalWeight", "totalDividendPaid", "dividendLiability", "pendingDividend", "bidEscrow", "totalMarketFees", "opsOwed", "proceedsLiability", "MAX_MINTS", "factory", "saltLocked"] as const;
  const v = await c.multicall({ contracts: names.map(functionName => ({ address: FAGENT.cards, abi: cardsAbi, functionName })), blockNumber: block.number, allowFailure: false });
  if (String(v[18]).toLowerCase() !== FAGENT.factory.toLowerCase()) throw new Error("Card factory mismatch");
  const vault = String(v[7]) as Address; const token = String(v[8]) as Address;
  const [minters, balance] = await Promise.all([
    c.readContract({ address: FAGENT.factory, abi: factoryAbi, functionName: "presaleBuyerCount", blockNumber: block.number }),
    c.getBalance({ address: FAGENT.cards, blockNumber: block.number }),
  ]);
  const hasVault = Boolean(v[6]) && deployedAddress(vault);
  let vaultStats = null;
  if (hasVault) {
    const names = ["totalTaxRevenue", "floorFund", "totalMintBurned", "totalForfeitBurned", "totalFloorBurned", "launchTime", "distributed"] as const;
    const r = await c.multicall({ contracts: names.map(functionName => ({ address: vault, abi: poolVaultAbi, functionName })), blockNumber: block.number, allowFailure: false });
    vaultStats = { taxReceived: String(r[0]), floorFundBnb: formatEther(BigInt(String(r[1]))), burnedTokens: formatUnits(BigInt(String(r[2])) + BigInt(String(r[3])) + (r[6] ? 97479938n * 10n ** 18n : 0n), 18), floorBurnedCards: Number(r[4]), launchTime: Number(r[5]) };
  }
  return { paid: Number(v[0]), teamMinted: Number(v[1]), minted: Number(v[0]) + Number(v[1]), lastTokenId: Number(v[2]), raisedBnb: formatEther(BigInt(String(v[3]))), minters: Number(minters), presaleDeadline: Number(v[4]), filledAt: Number(v[5]), launched: Boolean(v[6]), vault: hasVault ? vault : null, token: deployedAddress(token) ? token : null, weight: Number(v[9]), burned: Number(v[0]) + Number(v[1]) - Number(v[9]), dividendsPaid: String(v[10]), dividendLiability: String(v[11]), undistributed: String(v[12]), bidEscrow: String(v[13]), marketFees: String(v[14]), opsOwed: String(v[15]), proceedsLiability: String(v[16]), maxMints: Number(v[17]), saltLocked: Boolean(v[19]), balance: String(balance), block: String(block.number), chainTime: Number(block.timestamp), phase: launchPhase(Boolean(v[6]), Number(v[0]), Number(v[4]), Number(v[5]), Number(block.timestamp)), vaultStats };
}
export type Snapshot = Awaited<ReturnType<typeof readSnapshot>>;
export async function readMarket(askCursor: string, bidCursor: string) {
  const c = client(); const block = await c.getBlockNumber();
  const [asks, bids, fees, escrow] = await Promise.all([
    c.readContract({ address: FAGENT.orderbook, abi: lensAbi, functionName: "getActiveListings", args: [FAGENT.cards, BigInt(askCursor), 500n], blockNumber: block }),
    c.readContract({ address: FAGENT.orderbook, abi: lensAbi, functionName: "getActiveBids", args: [FAGENT.cards, BigInt(bidCursor), 500n], blockNumber: block }),
    c.readContract({ address: FAGENT.cards, abi: cardsAbi, functionName: "totalMarketFees", blockNumber: block }),
    c.readContract({ address: FAGENT.cards, abi: cardsAbi, functionName: "bidEscrow", blockNumber: block }),
  ]);
  return { block: String(block), volume: formatBnb(estimatedMarketVolume(String(fees), 100)), escrow: formatBnb(escrow), feeBps: 100, maxBuy: 250,
    asks: asks[0].map(o => ({ id: Number(o.tokenId), seller: o.seller, priceWei: String(o.price), price: formatEther(o.price) })),
    bids: bids[0].map(o => ({ id: String(o.bidId), bidder: o.bidder, priceWei: String(o.price), price: formatEther(o.price), remaining: Number(o.remaining), batchPlusOne: 0 })),
    askNext: String(asks[1]), askEnd: String(asks[2]), bidNext: String(bids[1]), bidEnd: String(bids[2]) };
}
export type MarketData = Awaited<ReturnType<typeof readMarket>>;
export async function readWallet(address: Address) {
  const c = client(); const [used, agent, proceeds, balance, maxMints] = await Promise.all([
    c.readContract({ address: FAGENT.cards, abi: cardsAbi, functionName: "mintsUsed", args: [address] }),
    c.readContract({ address: FAGENT.cards, abi: cardsAbi, functionName: "AGENT_ID_NFT" }),
    c.readContract({ address: FAGENT.cards, abi: cardsAbi, functionName: "proceedsOwed", args: [address] }),
    c.getBalance({ address }), c.readContract({ address: FAGENT.cards, abi: cardsAbi, functionName: "MAX_MINTS" }),
  ]);
  const held = await c.readContract({ address: agent, abi: agentAbi, functionName: "balanceOf", args: [address] });
  return { address, used: Number(used), maxMints: Number(maxMints), hasAgentId: held > 0n, proceeds: String(proceeds), balance: formatEther(balance) };
}
export async function readCard(id: number) {
  const c = client(); const [owner, dividend, launched] = await Promise.all([
    c.readContract({ address: FAGENT.cards, abi: cardsAbi, functionName: "ownerOf", args: [BigInt(id)] }),
    c.readContract({ address: FAGENT.cards, abi: cardsAbi, functionName: "pendingDividendOf", args: [BigInt(id)] }),
    c.readContract({ address: FAGENT.cards, abi: cardsAbi, functionName: "launched" }),
  ]);
  return { id, owner, dividend: formatEther(dividend), launched };
}
export async function readHistory(toBlock?: string) {
  const c = client(); const head = toBlock ? BigInt(toBlock) : await c.getBlockNumber(); const from = head > 999n ? head - 999n : 0n;
  const logs = await c.getLogs({ address: FAGENT.cards, event: getAbiItem({ abi: cardsAbi, name: "Sold" }), fromBlock: from, toBlock: head });
  return { fromBlock: String(from), toBlock: String(head), next: from > 0n ? String(from - 1n) : null, trades: logs.reverse().map(log => ({ id: String(log.args.tokenId), price: formatEther(log.args.price ?? 0n), seller: log.args.seller ?? "", buyer: log.args.buyer ?? "", hash: log.transactionHash, block: String(log.blockNumber), logIndex: log.logIndex })) };
}
