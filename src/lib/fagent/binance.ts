import { parseEther } from "viem";
import { useEffect, useState } from "react";
import type { Language } from "./i18n";
import { FAGENT } from "./config";
import { walletCommand, withChecks } from "./checks";

/** Short, explicit commands for the Binance Wallet built-in AI: full signature, one param per line, no ABI lookup. */
export type CommandStyle = "general" | "binance";
const KEY = "fagent-command-style";
export function useCommandStyle() {
  const [style, setStyle] = useState<CommandStyle>("general");
  useEffect(() => { if (localStorage.getItem(KEY) === "binance") setStyle("binance"); }, []);
  return [style, (s: CommandStyle) => { setStyle(s); localStorage.setItem(KEY, s); }] as const;
}

export const SIGNATURES = {
  mint: "function mint(uint256 count) payable",
  buy: "function buy(uint256[] tokenIds, uint256[] maxPrices) payable",
  placeBid: "function placeBid(uint256 price, uint256 quantity, uint256 batchPlusOne) payable",
  cancelBids: "function cancelBids(uint256[] bidIds)",
  list: "function list(uint256[] tokenIds, uint256[] prices)",
  sellToBid: "function sellToBid(uint256 bidId, uint256[] tokenIds)",
  unlist: "function unlist(uint256[] tokenIds)",
  claim: "function claim(uint256 tokenId)",
  redeem: "function redeem(uint256 tokenId)",
  sync: "function sync()",
  withdrawProceeds: "function withdrawProceeds(address to)",
} as const;

function weiText(wei: bigint, lang: Language) {
  const bnb = Number(wei) / 1e18;
  return wei === 0n ? "0" : lang === "en" ? `${bnb} BNB (${wei} wei)` : `${bnb} BNB（${wei} wei）`;
}
export function binanceCommand(sig: string, params: [string, string][], value: string, lang: Language, note = "") {
  const en = lang === "en";
  const lines = en
    ? [`You are my Binance Agent Wallet assistant. Network: BNB Chain (chainId=${FAGENT.chainId}).`, `Card Vault: ${FAGENT.vault}`, "Call this Vault function directly (do not look up the ABI on-chain; the signature is given):", sig, ...params.map(([k, v]) => `- param ${k}: ${v}`), `- value: ${value}`]
    : [`你是我的币安 Agent 钱包助手。网络：BNB Chain (chainId=${FAGENT.chainId})。`, `卡牌金库 Vault：${FAGENT.vault}`, "请直接调用金库合约的函数（不要去链上查 ABI，函数签名已给出）：", sig, ...params.map(([k, v]) => `- 参数 ${k}：${v}`), `- value：${value}`];
  if (note) lines.push(note);
  lines.push(en ? "Show me the transaction preview; send only after I confirm." : "生成交易预览让我确认，确认后再发送。");
  return lines.join("\n");
}

const price = (p: string) => { const w = parseEther(p); if (w <= 0n || w > (1n << 96n) - 1n) throw new Error("price"); return w; };

export function binanceMint(count: number, lang: Language = "zh") {
  if (!Number.isInteger(count) || count < 1 || count > 7) throw new Error("count");
  return binanceCommand(SIGNATURES.mint, [["count", String(count)]], weiText(2000000000000000n * BigInt(count), lang), lang);
}
export function binanceCard(kind: "claim" | "redeem" | "list" | "unlist", id: number | string, p = "0.003", lang: Language = "zh") {
  const en = lang === "en";
  if (kind === "list") { const w = price(p); return binanceCommand(SIGNATURES.list, [["tokenIds", `[${id}]`], ["prices", `[${w}]`]], "0", lang, en ? `Price ${p} BNB per card.` : `售价 ${p} BNB。`); }
  if (kind === "unlist") return binanceCommand(SIGNATURES.unlist, [["tokenIds", `[${id}]`]], "0", lang);
  if (kind === "claim") return binanceCommand(SIGNATURES.claim, [["tokenId", String(id)]], "0", lang);
  return binanceCommand(SIGNATURES.redeem, [["tokenId", String(id)]], "0", lang, en ? "Burning is irreversible; tell me the tokens and BNB I will receive first." : "销毁不可撤销，先告诉我将收到的代币和 BNB。");
}

export function getBinanceCommands(lang: Language = "zh") {
  const en = lang === "en";
  const ph = (zh: string, e: string) => (en ? `[${e}]` : `【${zh}】`);
  const id = ph("卡号", "cardId");
  const keys = ["mint", "buy", "placeBid", "cancelBids", "list", "sellToBid", "unlist", "claim", "redeem", "sync", "withdrawProceeds"];
  return [walletCommand(lang), ...[
    binanceMint(1, lang),
    binanceCommand(SIGNATURES.buy, [["tokenIds", `[${id}]`], ["maxPrices", `[${ph("最高价 wei", "max price in wei")}]`]], ph("等于最高价 wei", "equal to max price in wei"), lang),
    binanceCommand(SIGNATURES.placeBid, [["price", ph("每张出价 wei", "price per card in wei")], ["quantity", ph("数量", "quantity")], ["batchPlusOne", ph("第 N 批填 N，不限填 0", "batch N, or 0 for any")]], ph("出价 wei × 数量", "price wei × quantity"), lang),
    binanceCommand(SIGNATURES.cancelBids, [["bidIds", `[${ph("bidId", "bidId")}]`]], "0", lang),
    binanceCommand(SIGNATURES.list, [["tokenIds", `[${id}]`], ["prices", `[${ph("售价 wei", "price in wei")}]`]], "0", lang),
    binanceCommand(SIGNATURES.sellToBid, [["bidId", ph("bidId", "bidId")], ["tokenIds", `[${id}]`]], "0", lang),
    binanceCard("unlist", id, undefined, lang),
    binanceCard("claim", id, undefined, lang),
    binanceCard("redeem", id, undefined, lang),
    binanceCommand(SIGNATURES.sync, [], "0", lang),
    binanceCommand(SIGNATURES.withdrawProceeds, [["to", ph("我的钱包地址", "my wallet address")]], "0", lang),
  ].map((text, i) => withChecks(keys[i] ?? "", text, lang))];
}
