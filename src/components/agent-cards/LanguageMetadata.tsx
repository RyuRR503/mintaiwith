import { useEffect } from "react";
import { useLocation } from "@tanstack/react-router";
import { useLanguage } from "./LanguageProvider";

const metadata: Record<string, { zh: [string, string]; en: [string, string] }> = {
  "/": { zh: ["ANT.AI — 一卡双权 · 公平铸造", "币安 Agent 钱包铸造 ANT.AI，参与 BNB 税收分配、卡牌交易与代币线性释放。"], en: ["ANT.AI — Fair Mint · One card, two rights", "Mint ANT.AI with Binance Agent Wallet. Share BNB trading tax, trade cards and receive vested tokens."] },
  "/market": { zh: ["ANT.AI — 卡牌市场", "ANT.AI 卡牌卖单、买单、求购与交易记录。"], en: ["ANT.AI — Card market", "ANT.AI card asks, bids, order books and on-chain trade history."] },
  "/commands": { zh: ["ANT.AI — Agent 指令", "币安 Agent 钱包的 ANT.AI 铸造、买卖、分红与退款指令。"], en: ["ANT.AI — Agent commands", "Binance Agent Wallet commands for ANT.AI minting, trading, dividends and refunds."] },
  "/vault": { zh: ["ANT.AI — 金库账本", "ANT.AI BNB 税收金库账本与分配说明。"], en: ["ANT.AI — Vault ledger", "ANT.AI BNB tax ledger, dividend distributions and presale escrow."] },
  "/rules": { zh: ["ANT.AI — 卡牌规则", "ANT.AI 的发行数量、铸造价格、税收分配、交易与释放规则。"], en: ["ANT.AI — Card rules", "ANT.AI supply, mint price, tax distribution, trading and vesting rules."] },
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