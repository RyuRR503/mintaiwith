import { formatEther } from "viem";

export function saleCardIds(raw: string, maxSell: number) {
  const ids = [...new Set(raw.split(/[^0-9]+/).filter(Boolean).map(Number))];
  if (!ids.length || ids.length > maxSell || ids.some(id => !Number.isInteger(id) || id < 1 || id > 777777)) return [];
  return ids;
}

export function formatBnb(value: bigint | string, maxDecimals = 4) {
  const ether = typeof value === "bigint" ? formatEther(value) : value.includes(".") ? value : formatEther(BigInt(value));
  if (!ether.includes(".")) return ether;
  return ether.slice(0, ether.indexOf(".") + 1 + maxDecimals).replace(/0+$/, "").replace(/\.$/, "") || "0";
}

export function estimatedMarketVolume(feesWei: string, feeBps: number) {
  if (!Number.isInteger(feeBps) || feeBps <= 0) throw new Error("Invalid market fee");
  return formatEther(BigInt(feesWei) * 10000n / BigInt(feeBps));
}

export function purchaseSelection<T extends { id: number; priceWei: string }>(asks: T[], maxBuy: number) {
  if (!Number.isInteger(maxBuy) || maxBuy < 1) throw new Error("Invalid purchase limit");
  const cards = [...asks].sort((a, b) => BigInt(a.priceWei) < BigInt(b.priceWei) ? -1 : BigInt(a.priceWei) > BigInt(b.priceWei) ? 1 : a.id - b.id).slice(0, maxBuy);
  return { cards, totalWei: cards.reduce((sum, card) => sum + BigInt(card.priceWei), 0n).toString() };
}