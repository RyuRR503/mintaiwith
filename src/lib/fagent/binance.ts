import { useEffect, useState } from "react";
import type { Language } from "./i18n";
import { commandHeader, getAgentCommands, mintCommand, cardCommand } from "./commands";
export type CommandStyle = "general" | "binance";
const KEY = "fagent-command-style";
export function useCommandStyle() {
  const [style, setStyle] = useState<CommandStyle>("general");
  useEffect(() => { if (localStorage.getItem(KEY) === "binance") setStyle("binance"); }, []);
  return [style, (s: CommandStyle) => { setStyle(s); localStorage.setItem(KEY, s); }] as const;
}
export const SIGNATURES = {
  mint: "function mint(uint256 count, uint256 minTokens) payable",
  buy: "function buy(uint256[] tokenIds, uint256[] maxPrices) payable",
  placeBid: "function placeBid(uint256 price, uint256 quantity) payable",
  cancelBids: "function cancelBids(uint256[] bidIds)",
  list: "function list(uint256[] tokenIds, uint256[] prices)",
  sellToBid: "function sellToBid(uint256 bidId, uint256[] tokenIds)",
  unlist: "function unlist(uint256[] tokenIds)",
  claim: "function claim(uint256[] tokenIds)",
  refund: "function refund(uint256[] tokenIds)",
  withdrawProceeds: "function withdrawProceeds(address to)",
} as const;
export function binanceCommand(sig: string, params: [string,string][], value: string, lang: Language, note="") {
  return [commandHeader(lang), lang === "en" ? "Use the explicit signature below; do not look up the proxy ABI." : "使用以下明确签名，不要查询代理 ABI。", sig, ...params.map(([k,v]) => `${k}: ${v}`), `value: ${value}`, note].join("\n");
}
export const binanceMint = (count: number, lang: Language = "zh") => mintCommand(count, lang);
export const binanceCard = (kind: "claim" | "redeem" | "list" | "unlist", id: number | string, p="0.003", lang: Language="zh") => cardCommand(kind, id, p, lang);
export function getBinanceCommands(lang: Language = "zh") {
  return getAgentCommands(lang).map((c,i) => i === 0 ? c.text : `${c.text}\n${lang === "en" ? "Use the explicit function signature above; do not look up the proxy ABI." : "使用上面的明确函数签名，不查询代理 ABI。"}`);
}
