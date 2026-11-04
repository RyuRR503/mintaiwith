import { POOL_MOCK as M, poolStatus } from "@/lib/fagent/pool-edition";
import { useLanguage } from "./LanguageProvider";

const fmt = (n: number, d = 0) => n.toLocaleString("en-US", { maximumFractionDigits: d });

/** Cumulative burn / dividend / floor-fund totals for the pool edition (demo until deployment). */
export function PoolStats() {
  const { t } = useLanguage();
  const presale = poolStatus(M.minted).phase === "presale";
  const items = [
    { label: "已销毁代币", value: fmt(M.burnedTokens), unit: t("枚") },
    { label: "已销毁卡牌", value: fmt(M.burnedCards), unit: t("张") },
    { label: "累计分红", value: fmt(M.dividendBnb, 4), unit: "BNB" },
    { label: "地板基金余额", value: fmt(M.floorFundBnb, 4), unit: "BNB" },
  ];
  return <div>
    <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
      <p className="font-mono text-xs text-primary">BURN · DIVIDEND · FLOOR</p>
      <span className="rounded border border-border px-2 py-1 font-mono text-[11px] text-muted-foreground">{presale ? t("预售阶段 · 开池后开始累计") : t("演示数据")}</span>
    </div>
    <dl className="gx-tiles">{items.map(i => <div key={i.label}><dt className="text-xs text-muted-foreground">{t(i.label)}</dt><dd className="gx-tile-value">{i.value}<span>{i.unit}</span></dd></div>)}</dl>
  </div>;
}
