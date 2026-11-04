import { useLanguage } from "./LanguageProvider";
import { useSuspenseQuery } from "@tanstack/react-query";
import { RefreshCw } from "lucide-react";
import { snapshotOptions } from "@/lib/fagent/queries";
import { VaultLedger } from "./VaultLedger";
import { Button } from "@/components/ui/button";
import { AgentCommands } from "./AgentCommands";
import { MarketBook } from "./MarketBook";
import { SiteShell } from "./SiteShell";
import { PoolStats } from "./PoolStats";

export type CardPage = "market" | "commands" | "vault";

const META: Record<CardPage, { index: string; code: string; title: string; lead: string; seed: number }> = {
  market: { index: "02", code: "MARKET", title: "卡牌市场", lead: "挂单、求购、成交，一张卡的流转都在这里。", seed: 202 },
  commands: { index: "03", code: "COMMANDS", title: "Agent 指令", lead: "复制指令，交给币安 Agent 钱包确认。网站不替你签名。", seed: 303 },
  vault: { index: "04", code: "VAULT", title: "金库账本", lead: "每一笔税收进了哪里，链上可查。", seed: 404 },
};

export function CardExperience({ page }: { page: CardPage }) {
  const { t } = useLanguage();
  const { data: result, refetch, isFetching } = useSuspenseQuery(snapshotOptions());
  const supply = result.data;
  const m = META[page];
  const status = (
    <div className="flex flex-wrap items-center gap-3 font-mono text-xs text-muted-foreground">
      <span className="flex items-center gap-2 text-primary"><span className="gx-live-dot" />{supply ? t("链上数据 · 区块 {0}", supply.block) : t("链上读取失败")}</span>
      <Button variant="ghost" size="icon" aria-label={t("刷新链上数据")} disabled={isFetching} onClick={() => void refetch()}><RefreshCw className={`size-3.5 ${isFetching ? "animate-spin" : ""}`} /></Button>
      <span className="rounded border border-border px-2 py-1 text-[11px]">{t("开池版合约即将上线 · 当前市场与账本数据来自旧版合约")}</span>
    </div>
  );
  return (
    <SiteShell {...m} aside={status}>
      {result.error && <div role="alert" className="mb-6 text-sm text-destructive">{t(result.error)}<Button variant="link" onClick={() => void refetch()}>{t("重试")}</Button></div>}
      {page === "market" && <MarketBook />}
      {page === "commands" && <AgentCommands />}
      {page === "vault" && <section className="mb-14"><p className="gx-kicker mb-2">{t("开池版 · 累计数据")}</p><PoolStats /></section>}
      {page === "vault" && supply && <VaultLedger data={supply} />}
    </SiteShell>
  );
}
