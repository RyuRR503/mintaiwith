import { createPublicClient, fallback, http, formatEther, formatUnits, getAbiItem, type Address } from "viem";
import { bsc } from "viem/chains";
import { FAGENT, liveSupply } from "./config";
import { vaultAbi } from "./vault-abi";
import { estimatedMarketVolume, formatBnb } from "./market";

function client() {
  return createPublicClient({ chain: bsc, transport: fallback([
    http("https://bsc-dataseed.bnbchain.org", { timeout: 10000, retryCount: 0 }),
    http("https://bsc-dataseed1.defibit.io", { timeout: 10000, retryCount: 0 }),
    http("https://bsc-dataseed1.ninicoin.io", { timeout: 10000, retryCount: 0 }),
  ], { rank: false, retryCount: 0 }) });
}
export async function readSnapshot() {
  const c = client();
  const block = await c.getBlock();
  const names = ["TOTAL_CARDS", "userMints", "teamMinted", "totalWeight", "mintPrice", "MAX_MINTS", "batchOpenedAt", "STALL_RELEASE", "undistributedTax", "totalTaxReceived", "totalDividendPaid", "dividendLiability", "bidEscrow", "totalMarketFees", "marketFeeOwed", "opsOwed", "proceedsLiability", "projectToken", "nextBidId"] as const;
  const values = await c.multicall({ contracts: names.map(functionName => ({ address: FAGENT.vault, abi: vaultAbi, functionName })), blockNumber: block.number, allowFailure: false });
  const numberAt = (i: number) => Number(values[i]);
  const weiAt = (i: number) => String(values[i]);
  const token = String(values[17]);
  if (token.toLowerCase() !== FAGENT.token) throw new Error("Vault token mismatch");
  const supply = liveSupply(numberAt(1), numberAt(2), numberAt(0));
  const batchId = BigInt(supply.batch - 1);
  const [inventory, credit, accounted, balance, decimals] = await Promise.all([
    c.readContract({ address: FAGENT.vault, abi: vaultAbi, functionName: "batchInventory", args: [batchId], blockNumber: block.number }),
    c.readContract({ address: FAGENT.vault, abi: vaultAbi, functionName: "batchCredit", args: [batchId], blockNumber: block.number }),
    c.readContract({ address: FAGENT.vault, abi: vaultAbi, functionName: "batchAccounted", args: [batchId], blockNumber: block.number }),
    c.getBalance({ address: FAGENT.vault, blockNumber: block.number }),
    c.readContract({ address: FAGENT.token, abi: [{ type: "function", name: "decimals", inputs: [], outputs: [{ type: "uint8" }], stateMutability: "view" }] as const, functionName: "decimals", blockNumber: block.number }),
  ]);
  return {
    ...supply, total: numberAt(0), paid: numberAt(1), teamMinted: numberAt(2), weight: numberAt(3), burned: supply.minted - numberAt(3), price: formatEther(BigInt(weiAt(4))), maxMints: numberAt(5),
    openedAt: numberAt(6), releaseSeconds: numberAt(7), chainTime: Number(block.timestamp), block: String(block.number),
    undistributed: weiAt(8), taxReceived: weiAt(9), dividendsPaid: weiAt(10), dividendLiability: weiAt(11), bidEscrow: weiAt(12),
    marketFees: weiAt(13), marketFeeOwed: weiAt(14), opsOwed: weiAt(15), proceedsLiability: weiAt(16), nextBidId: weiAt(18), balance: String(balance),
    batchInventory: formatUnits(inventory, decimals), batchCredit: formatUnits(credit, decimals), batchAccounted: accounted, tokenDecimals: decimals,
  };
}
export type Snapshot = Awaited<ReturnType<typeof readSnapshot>>;

export async function readMarket(askCursor: string, bidCursor: string) {
  const c = client();
  const block = await c.getBlockNumber();
  const [asks, bids, bidEnd, fees, escrow, feeBps, maxBuy] = await Promise.all([
    c.readContract({ address: FAGENT.vault, abi: vaultAbi, functionName: "getActiveListings", args: [BigInt(askCursor), 500n], blockNumber: block }),
    c.readContract({ address: FAGENT.vault, abi: vaultAbi, functionName: "getActiveBids", args: [BigInt(bidCursor), 500n], blockNumber: block }),
    c.readContract({ address: FAGENT.vault, abi: vaultAbi, functionName: "nextBidId", blockNumber: block }),
    c.readContract({ address: FAGENT.vault, abi: vaultAbi, functionName: "totalMarketFees", blockNumber: block }),
    c.readContract({ address: FAGENT.vault, abi: vaultAbi, functionName: "bidEscrow", blockNumber: block }),
    c.readContract({ address: FAGENT.vault, abi: vaultAbi, functionName: "MARKET_FEE_BPS", blockNumber: block }),
    c.readContract({ address: FAGENT.vault, abi: vaultAbi, functionName: "MAX_BUY", blockNumber: block }),
  ]);
  return {
    block: String(block),
    volume: formatBnb(estimatedMarketVolume(String(fees), Number(feeBps))), escrow: formatBnb(escrow), feeBps: Number(feeBps), maxBuy: Number(maxBuy),
    asks: asks[0].map((id, i) => ({ id: Number(id), seller: asks[1][i]?.seller ?? "", priceWei: String(asks[1][i]?.price ?? 0n), price: formatEther(asks[1][i]?.price ?? 0n) })),
    bids: bids[0].map((id, i) => ({ id: String(id), bidder: bids[1][i]?.bidder ?? "", priceWei: String(bids[1][i]?.price ?? 0n), price: formatEther(bids[1][i]?.price ?? 0n), remaining: Number(bids[1][i]?.remaining ?? 0), batchPlusOne: Number(bids[1][i]?.batchPlusOne ?? 0) })),
    askNext: String(asks[2]), bidNext: String(bids[2]), bidEnd: String(bidEnd),
  };
}
export type MarketData = Awaited<ReturnType<typeof readMarket>>;

export async function readWallet(address: Address) {
  const c = client();
  const [used, hasAgentId, proceeds, balance] = await Promise.all([
    c.readContract({ address: FAGENT.vault, abi: vaultAbi, functionName: "mintsUsed", args: [address] }),
    c.readContract({ address: FAGENT.vault, abi: vaultAbi, functionName: "hasAgentId", args: [address] }),
    c.readContract({ address: FAGENT.vault, abi: vaultAbi, functionName: "proceedsOwed", args: [address] }),
    c.getBalance({ address }),
  ]);
  return { address, used: Number(used), hasAgentId, proceeds: String(proceeds), balance: formatEther(balance) };
}
export async function readCard(id: number) {
  const c = client();
  const batch = BigInt(Math.floor(id / 10000));
  const [owner, active, dividend, tokens, accounted, decimals, block, opened, release] = await Promise.all([
    c.readContract({ address: FAGENT.vault, abi: vaultAbi, functionName: "ownerOf", args: [BigInt(id)] }),
    c.readContract({ address: FAGENT.vault, abi: vaultAbi, functionName: "isActive", args: [BigInt(id)] }),
    c.readContract({ address: FAGENT.vault, abi: vaultAbi, functionName: "pendingDividend", args: [BigInt(id)] }),
    c.readContract({ address: FAGENT.vault, abi: vaultAbi, functionName: "repurchaseOf", args: [BigInt(id)] }),
    c.readContract({ address: FAGENT.vault, abi: vaultAbi, functionName: "batchAccounted", args: [batch] }),
    c.readContract({ address: FAGENT.token, abi: [{ type: "function", name: "decimals", inputs: [], outputs: [{ type: "uint8" }], stateMutability: "view" }] as const, functionName: "decimals" }),
    c.getBlock(),
    c.readContract({ address: FAGENT.vault, abi: vaultAbi, functionName: "batchOpenedAt" }),
    c.readContract({ address: FAGENT.vault, abi: vaultAbi, functionName: "STALL_RELEASE" }),
  ]);
  return { id, owner, active, dividend: formatEther(dividend), tokens: formatUnits(tokens, decimals), accounted, chainTime: Number(block.timestamp), openedAt: Number(opened), releaseSeconds: Number(release) };
}
export async function readHistory(toBlock?: string) {
  const c = createPublicClient({ chain: bsc, transport: http("https://bsc-rpc.publicnode.com", { timeout: 15000, retryCount: 1 }) });
  const head = toBlock ? BigInt(toBlock) : await c.getBlockNumber();
  const from = head > 999n ? head - 999n : 0n;
  const logs = await c.getLogs({ address: FAGENT.vault, event: getAbiItem({ abi: vaultAbi, name: "Sold" }), fromBlock: from, toBlock: head });
  return { fromBlock: String(from), toBlock: String(head), next: from > 0n ? String(from - 1n) : null,
    trades: logs.reverse().map(log => ({ id: String(log.args.tokenId), price: formatEther(log.args.price ?? 0n), seller: log.args.seller ?? "", buyer: log.args.buyer ?? "", hash: log.transactionHash, block: String(log.blockNumber), logIndex: log.logIndex })) };
}