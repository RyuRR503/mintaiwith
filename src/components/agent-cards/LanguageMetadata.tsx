import { useEffect } from "react";
import { useLocation } from "@tanstack/react-router";
import { useLanguage } from "./LanguageProvider";

const metadata: Record<string, { zh: [string, string]; en: [string, string] }> = {
  "/": { zh: ["MINT.AI — 一卡双权 · 公平铸造", "币安 Agent 钱包铸造 MINT.AI，参与 BNB 税收分配、卡牌交易与代币线性释放。"], en: ["MINT.AI — Fair Mint · One card, two rights", "Mint MINT.AI with Binance Agent Wallet. Share BNB trading tax, trade cards and receive vested tokens."] },
  "/market": { zh: ["MINT.AI — 卡牌市场", "MINT.AI 卡牌卖单、买单、求购与交易记录。"], en: ["MINT.AI — Card market", "MINT.AI card asks, bids, order books and on-chain trade history."] },
  "/commands": { zh: ["MINT.AI — Agent 指令", "币安 Agent 钱包的 MINT.AI 铸造、买卖、分红与退款指令。"], en: ["MINT.AI — Agent commands", "Binance Agent Wallet commands for MINT.AI minting, trading, dividends and refunds."] },
  "/vault": { zh: ["MINT.AI — 金库账本", "MINT.AI BNB 税收金库账本与分配说明。"], en: ["MINT.AI — Vault ledger", "MINT.AI BNB tax ledger, dividend distributions and presale escrow."] },
  "/rules": { zh: ["MINT.AI — 卡牌规则", "MINT.AI 的发行数量、铸造价格、税收分配、交易与释放规则。"], en: ["MINT.AI — Card rules", "MINT.AI supply, mint price, tax distribution, trading and vesting rules."] },
};
export function LanguageMetadata() {
  const { language } = useLanguage();
  const { pathname } = useLocation();
  useEffect(() => {
    const entry = metadata[pathname];
    if (!entry) return;
    const [title, description] = entry[language];
    document.title = title;
    for (const [attribute, key, content] of [["name", "description", description], ["property", "og:title", title], ["property", "og:description", description]] as const) {
      document.head.querySelector(`meta[${attribute}="${key}"]`)?.setAttribute("content", content);
    }
  }, [language, pathname]);
  return null;
}