import { useEffect } from "react";
import { useLocation } from "@tanstack/react-router";
import { useLanguage } from "./LanguageProvider";

const metadata: Record<string, { zh: [string, string]; en: [string, string] }> = {
  "/": { zh: ["7AGENT — 一卡双权 · 公平铸造", "币安 Agent 钱包铸造 7AGENT，参与 BNB 税收分配、卡牌交易与批次代币兑换。"], en: ["7AGENT — Fair Mint · One card, two rights", "Mint 7AGENT with Binance Agent Wallet. Share BNB trading tax, trade cards and redeem batch token allocations."] },
  "/market": { zh: ["7AGENT — 卡牌市场", "7AGENT 卡牌卖单、买单、求购与交易记录。"], en: ["7AGENT — Card market", "7AGENT card asks, bids, order books and on-chain trade history."] },
  "/commands": { zh: ["7AGENT — Agent 指令", "币安 Agent 钱包的 7AGENT 铸造、买卖、分红与兑换指令。"], en: ["7AGENT — Agent commands", "Binance Agent Wallet commands for 7AGENT minting, trading, dividends and redemption."] },
  "/vault": { zh: ["7AGENT — 金库账本", "7AGENT BNB 税收金库账本与分配说明。"], en: ["7AGENT — Vault ledger", "7AGENT BNB tax ledger, dividend distributions and unclaimed batch tokens."] },
  "/rules": { zh: ["7AGENT — 卡牌规则", "7AGENT 的发行数量、铸造价格、税收分配、交易与兑换规则。"], en: ["7AGENT — Card rules", "7AGENT supply, mint price, tax distribution, trading and redemption rules."] },
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