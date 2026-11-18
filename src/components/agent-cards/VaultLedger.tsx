import { useLanguage } from "./LanguageProvider";
import { formatBnb } from "@/lib/fagent/market";
import type { Snapshot } from "@/lib/fagent/chain.server";
import { DeploymentContracts } from "./DeploymentContracts";
export function VaultLedger({ data }: { data: Snapshot }) {
  const { language } = useLanguage(); const en = language === "en";
  const rows = [
    [en ? "Presale escrow · NFT card" : "预售托管资金 · 卡牌合约", data.raisedBnb],
    [en ? "Total tax received · vault" : "累计收到税收 · 金库", data.vaultStats ? formatBnb(data.vaultStats.taxReceived) : "—"],
    [en ? "Unclaimed dividends · NFT card" : "未领取分红 · 卡牌合约", formatBnb(data.dividendLiability)],
    [en ? "Dividends paid" : "已支付分红", formatBnb(data.dividendsPaid)],
  ];
  return <><DeploymentContracts vault={data.vault} token={data.token} /><dl className="gx-tiles">{rows.map(([label,value]) => <div key={label}><dt className="text-xs text-muted-foreground">{label}</dt><dd className="gx-tile-value">{value}<span>BNB</span></dd></div>)}</dl>{!data.vault && <p className="mt-8 text-sm text-muted-foreground">{en ? "Presale funds are held by the NFT card, not the vault factory. The vault is not deployed yet; no old vault balances are shown." : "预售资金保存在卡牌合约，不在金库工厂。金库尚未部署，此处不展示旧金库余额。"}</p>}</>;
}
