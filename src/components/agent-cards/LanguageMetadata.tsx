import { useEffect } from "react";
import { useLocation } from "@tanstack/react-router";
import { useLanguage } from "./LanguageProvider";

const metadata: Record<string, { zh: [string, string]; en: [string, string] }> = {
  "/": { zh: ["FAGENT — 一卡双权 · 公平铸造", "币安 Agent 钱包铸造 FAGENT，参与 BNB 税收分配、卡牌交易与批次代币兑换。"], en: ["FAGENT — Fair Mint · One card, two rights", "Mint FAGENT with Binance Agent Wallet. Share BNB trading tax, trade cards and redeem batch token allocations."] },
  "/market": { zh: ["FAGENT — 卡牌市场", "FAGENT 卡牌卖单、买单、求购与交易记录。"], en: ["FAGENT — Card market", "FAGENT card asks, bids, order books and on-chain trade history."] },
  "/commands": { zh: ["FAGENT — Agent 指令", "币安 Agent 钱包的 FAGENT 铸造、买卖、分红与兑换指令。"], en: ["FAGENT — Agent commands", "Binance Agent Wallet commands for FAGENT minting, trading, dividends and redemption."] },
  "/vault": { zh: ["FAGENT — 金库账本", "FAGENT BNB 税收金库账本与分配说明。"], en: ["FAGENT — Vault ledger", "FAGENT BNB tax ledger, dividend distributions and unclaimed batch tokens."] },
  "/rules": { zh: ["FAGENT — 卡牌规则", "FAGENT 的发行数量、铸造价格、税收分配、交易与兑换规则。"], en: ["FAGENT — Card rules", "FAGENT supply, mint price, tax distribution, trading and redemption rules."] },
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