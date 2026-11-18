import { useSuspenseQuery } from "@tanstack/react-query";
import { snapshotOptions } from "@/lib/fagent/queries";
import { formatBnb } from "@/lib/fagent/market";
import { useLanguage } from "./LanguageProvider";
export function PoolStats() {
  const { t, language } = useLanguage(); const en = language === "en";
  const { data: result } = useSuspenseQuery(snapshotOptions()); const data = result.data;
  const items = [
    { label: "已销毁代币", value: data ? data.vaultStats ? Number(data.vaultStats.burnedTokens).toLocaleString("en-US", { maximumFractionDigits: 0 }) : data.launched ? "—" : "0" : "—", unit: t("枚") },
    { label: "已销毁卡牌", value: data ? String(data.burned) : "—", unit: t("张") },
    { label: "累计分红", value: data ? formatBnb(data.dividendsPaid) : "—", unit: "BNB" },
    { label: "地板基金余额", value: data ? data.vaultStats ? data.vaultStats.floorFundBnb : data.launched ? "—" : "0" : "—", unit: "BNB" },
  ];
  return <div><div className="mb-4 flex flex-wrap items-center justify-between gap-3"><p className="font-mono text-xs text-primary">BURN · DIVIDEND · FLOOR</p><span className="rounded border border-border px-2 py-1 font-mono text-[11px] text-muted-foreground">{!data ? en ? "Chain data unavailable" : "链上数据暂不可用" : !data.launched ? en ? "Presale · vault not created" : "预售阶段 · 金库尚未创建" : en ? "Live on-chain totals" : "链上累计数据"}</span></div><dl className="gx-tiles">{items.map(i => <div key={i.label}><dt className="text-xs text-muted-foreground">{t(i.label)}</dt><dd className="gx-tile-value">{i.value}<span>{i.unit}</span></dd></div>)}</dl></div>;
}
