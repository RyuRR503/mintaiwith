import { useEffect } from "react";
import { useLocation } from "@tanstack/react-router";
import { useLanguage } from "./LanguageProvider";

const metadata: Record<string, { zh: [string, string]; en: [string, string] }> = {
  "/": { zh: ["ANTAGENT — 一卡双权 · 公平铸造", "币安 Agent 钱包铸造 ANTAGENT，参与 BNB 税收分配、卡牌交易与代币线性释放。"], en: ["ANTAGENT — Fair Mint · One card, two rights", "Mint ANTAGENT with Binance Agent Wallet. Share BNB trading tax, trade cards and receive vested tokens."] },
  "/market": { zh: ["ANTAGENT — 卡牌市场", "ANTAGENT 卡牌卖单、买单、求购与交易记录。"], en: ["ANTAGENT — Card market", "ANTAGENT card asks, bids, order books and on-chain trade history."] },
  "/commands": { zh: ["ANTAGENT — Agent 指令", "币安 Agent 钱包的 ANTAGENT 铸造、买卖、分红与退款指令。"], en: ["ANTAGENT — Agent commands", "Binance Agent Wallet commands for ANTAGENT minting, trading, dividends and refunds."] },
  "/vault": { zh: ["ANTAGENT — 金库账本", "ANTAGENT BNB 税收金库账本与分配说明。"], en: ["ANTAGENT — Vault ledger", "ANTAGENT BNB tax ledger, dividend distributions and presale escrow."] },
  "/rules": { zh: ["ANTAGENT — 卡牌规则", "ANTAGENT 的发行数量、铸造价格、税收分配、交易与释放规则。"], en: ["ANTAGENT — Card rules", "ANTAGENT supply, mint price, tax distribution, trading and vesting rules."] },
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