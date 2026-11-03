import { useLanguage } from "./LanguageProvider";
import { LanguageSwitch } from "./LanguageSwitch";
import { Link } from "@tanstack/react-router";
import { useState } from "react";
import { useSuspenseQuery } from "@tanstack/react-query";
import { snapshotOptions } from "@/lib/fagent/queries";
import { mintCommand } from "@/lib/fagent/commands";
import { CommandDialog, WalletCheck } from "./ChainTools";
import { VaultLedger } from "./VaultLedger";
import { RefreshCw } from "lucide-react";
import { ArrowUpRight, ChevronRight, Layers, Minus, Plus, ShieldCheck } from "lucide-react";
import { Button } from "@/components/ui/button";
import { FagentLogo } from "@/components/agent-cards/FagentLogo";
import { AgentCardArt } from "@/components/agent-cards/AgentCardArt";
import { AgentCommands } from "@/components/agent-cards/AgentCommands";
import { MarketBook } from "@/components/agent-cards/MarketBook";
import { CARD_RULES } from "@/lib/agent-card-model";

import { CardNavigation } from "@/components/agent-cards/CardNavigation";
export type CardPage = "mint" | "market" | "commands" | "vault";
export function CardExperience({ page = "mint" }: { page?: CardPage }) {
  const { t, language } = useLanguage();
  const { data: result, refetch, isFetching } = useSuspenseQuery(snapshotOptions());
  const supply = result.data;
  const [quantity, setQuantity] = useState(1);
  const [command, setCommand] = useState<string | null>(null);
  return (
    <div className="ac-page">
      <header className="ac-header">
        <div className="ac-container flex h-20 items-center justify-between gap-4">
          <Link to="/" aria-label={t("7AGENT 首页")} className="min-w-0 shrink"><FagentLogo /></Link>
          <CardNavigation className="hidden items-center gap-5 lg:gap-7 md:flex" />
          <LanguageSwitch />
        </div>
      </header>

      <div className="ac-audit-bar" role="note">
        <div className="ac-container flex items-center justify-center gap-2 py-2 text-center text-xs font-medium">
          <ShieldCheck className="size-3.5 shrink-0" />
          <span>{t("机制与合约已通过 Flap 审计与验证 · 资金安全由链上合约保障")}</span>
        </div>
      </div>

      <main className="ac-container">{result.error && <div role="alert" className="border-b border-border py-4 text-sm text-destructive">{t(result.error)}<Button variant="link" onClick={() => void refetch()}>{t("重试")}</Button></div>}
        <div className="flex flex-wrap items-center justify-between gap-2 border-b border-border py-4 text-[11px] text-muted-foreground"><span className="flex items-center gap-2"><span className="size-1.5 rounded-full bg-primary" />BNB CHAIN <span className="mx-1 text-border">/</span> GENESIS COLLECTION</span><span className="flex items-center gap-2"><ShieldCheck className="size-3.5" />{supply ? t("链上数据 · 区块 {0}", supply.block) : t("链上读取失败")}<Button variant="ghost" size="icon" aria-label={t("刷新链上数据")} disabled={isFetching} onClick={() => void refetch()}><RefreshCw className={`size-3.5 ${isFetching ? "animate-spin" : ""}`} /></Button></span></div>

        {page === "mint" && <><section className="ac-intro">
          <div className="ac-intro-copy">
            <p className="mb-5 flex items-center gap-2 font-mono text-xs text-primary"><span className="h-px w-7 bg-primary" /> {t("FAIR MINT · 公平铸造 · 币安 Agent 钱包专属")}</p>
            <h1 className="py-2"><FagentLogo square={false} className="h-auto w-44 sm:w-52" /></h1>
            <h2 className="mt-5 text-xl font-bold sm:text-2xl">{t("一张卡，接住 .AI 时代的每一笔税收。")}</h2>
            <div className="mt-4 max-w-md space-y-3 text-sm leading-7 text-muted-foreground"><p><span className="block">{t("交易在发生，税收在累积。")}</span><span className="block text-foreground">{t("而这张卡，替你记下属于你的那一份。")}</span></p><p>{t("持有，就参与每一次分配；销毁，就兑换卡上记下的代币。")}</p></div>
            <div className="mt-7 flex flex-wrap items-center gap-3"><Button className="h-11 px-6" onClick={() => { document.getElementById("card-workspace")?.scrollIntoView({ behavior: "smooth", block: "start" }); }}>{t("开始铸造")}<ArrowUpRight /></Button><Button asChild variant="ghost" className="h-11 text-muted-foreground"><Link to="/rules">{t("合约规则")}<ChevronRight /></Link></Button></div>
            <div className="mt-8 flex flex-wrap items-center gap-3 text-xs text-muted-foreground"><ShieldCheck className="size-4 text-primary" /><span>{t("仅币安 Agent 钱包（Agent ID）可铸造")}</span><span className="text-border">/</span><span>{t("市场交易不限身份")}</span></div>
          </div>
          <div className="ac-collectible"><div className="ac-edition"><span>EDITION 001</span><span>THE GENESIS</span></div><AgentCardArt /><div className="ac-art-caption"><span aria-hidden="true" /><span className="text-primary">7AGENT ↗</span></div></div>
          <div className="ac-side-code" aria-hidden>77 BATCHES / ONE COLLECTION</div>
        </section>

        <p className="mb-3 text-xs text-muted-foreground">{t("链上数据 · BNB Chain")}</p>
        <section className="ac-stats" aria-label={t("合约固定参数")}>{[{ value: CARD_RULES.supply.toLocaleString(), unit: t("张"), label: t("总发行量") }, { value: supply?.minted.toLocaleString() ?? "—", unit: t("张"), label: t("已铸造") }, { value: supply?.burned?.toLocaleString() ?? "—", unit: t("张"), label: t("已销毁") }, { value: supply?.remaining.toLocaleString() ?? "—", unit: t("张"), label: t("剩余可发行") }, { value: supply?.price ?? "—", unit: "BNB", label: t("单张铸造价格") }].map(s => <div key={s.label}><p className="flex flex-wrap items-baseline gap-2"><span className="font-poster text-4xl sm:text-5xl">{s.value}</span><span className="text-xs text-primary">{s.unit}</span></p><p className="mt-3 text-xs text-muted-foreground">{s.label}</p></div>)}</section></>}

        <section id="card-workspace" className="scroll-mt-6 pb-16 pt-9">
          <div className="md:hidden"><CardNavigation className="ac-tabs" compact /></div>
          {page !== "mint" && <div className="mb-8 border-b border-border pb-6 pt-7"><p className="mb-3 font-mono text-xs text-primary">7AGENT / {page.toUpperCase()}</p><h1 className="text-3xl font-bold">{page === "market" ? t("卡牌市场") : page === "commands" ? t("Agent 指令") : t("金库账本")}</h1></div>}
          <div className="pt-7">
            {page === "mint" && <div className="ac-mint-grid">
              <div><div className="mb-7 flex items-end justify-between gap-4"><div><p className="mb-2 font-mono text-[10px] text-muted-foreground">TOTAL SUPPLY</p><h3 className="text-xl">{t("创世铸造 · 总发行量")}</h3></div><span className="text-xs text-muted-foreground">{t("共")} {CARD_RULES.batches} {t("批")}</span></div>
                <div className="flex flex-wrap items-baseline gap-2"><span className="font-poster text-4xl">{CARD_RULES.supply.toLocaleString()}</span><span className="text-sm text-primary">{t("张 · 77 万张")}</span></div>
                <div className="mt-5 flex flex-wrap justify-between gap-3 text-sm"><span>{t("已铸造")} <strong className="font-mono text-primary">{supply?.minted.toLocaleString() ?? "—"}</strong> {t("张")}</span><span>{t("剩余")} <strong className="font-mono text-primary">{supply?.remaining.toLocaleString() ?? "—"}</strong> {t("张")}</span><span>{t("已销毁")} <strong className="font-mono text-primary">{supply?.burned?.toLocaleString() ?? "—"}</strong> {t("张")}</span></div>
                <progress className="ac-progress mt-4" value={supply?.minted ?? 0} max={CARD_RULES.supply} aria-label={t("链上总发行进度")} />
                  <p className="mt-3 text-xs text-muted-foreground">{t("发行进度 {0}% · 第 {1} / 77 批 · 本批 {2} / 9,500", supply ? (supply.minted / CARD_RULES.supply * 100).toFixed(2) : "—", supply?.batch ?? "—", supply?.batchPaid.toLocaleString() ?? "—")}</p>
                 <div className="mt-5 space-y-2 border-t border-border pt-4 text-xs text-muted-foreground"><p>{t("分 77 批发行，每批共 10,000 张。")}</p><p>{t("其中 9,500 张公开铸造，500 张团队自留；均包含在 77 万张总量内。")}</p><p>{t("每批 9,500 张公开铸造售满，即结算一次。")}</p></div>
                <div className="mt-8 grid grid-cols-2 gap-6 border-t border-border pt-6"><div><p className="font-poster text-3xl text-primary">80%</p><p className="mt-2 text-sm">{t("买入项目代币")}</p><p className="mt-1 text-xs text-muted-foreground">{t("每张 0.0016 BNB")}</p></div><div><p className="font-poster text-3xl">20%</p><p className="mt-2 text-sm">{t("运营费用")}</p><p className="mt-1 text-xs text-muted-foreground">{t("每张 0.0004 BNB")}</p></div></div>
              </div>
              <div className="ac-mint-tool"><div className="mb-6 flex items-center justify-between"><span className="flex items-center gap-2 text-sm"><Layers className="size-4 text-primary" />{t("铸造 7AGENT")}</span><span className="font-mono text-xs text-muted-foreground">× {quantity}</span></div><div className="flex items-baseline gap-2"><strong className="font-poster text-5xl">{supply?.price ?? "—"}</strong><span className="text-primary">{t("BNB / 张")}</span></div><div className="my-6 space-y-3 border-y border-border py-4 text-xs"><WalletCheck /><div className="flex items-center justify-between"><span className="text-muted-foreground">{t("铸造数量")}</span><div className="flex items-center gap-3"><Button variant="outline" size="icon" aria-label={t("减少铸造数量")} disabled={quantity <= 1} onClick={() => setQuantity(n => n - 1)}><Minus /></Button><span className="w-6 text-center font-mono">{quantity}</span><Button variant="outline" size="icon" aria-label={t("增加铸造数量")} disabled={quantity >= (supply?.maxMints ?? 7)} onClick={() => setQuantity(n => n + 1)}><Plus /></Button></div></div><div className="flex justify-between"><span className="text-muted-foreground">{t("合计")}</span><span>{(quantity * Number(supply?.price ?? 0)).toFixed(3)} {t("BNB + 网络费")}</span></div></div><Button className="h-12 w-full" disabled={!supply || supply.paid >= 731500} onClick={() => setCommand(mintCommand(quantity, language))}>{supply?.paid === 731500 ? t("全部售完") : t("生成铸造指令")}<ArrowUpRight /></Button><p className="mt-3 text-center text-[11px] text-muted-foreground">{t("币安 Agent 钱包确认后发送交易")}</p></div>
            </div>}

            {page === "market" && <MarketBook />}
            {page === "commands" && <AgentCommands />}
            {page === "vault" && supply && <VaultLedger data={supply} />}

          </div>
        </section>

        <section className="ac-flow"><div className="mb-8 flex items-center justify-between"><h2 className="text-xl">{t("从交易税，到卡牌权益。")}</h2><span className="hidden font-mono text-[10px] text-muted-foreground sm:block">THE CARD CYCLE</span></div><div className="grid gap-8 md:grid-cols-3">{[{ n: "01", title: t("铸造 · 买入"), text: t("0.002 BNB 铸造一张卡，80% 通过 Flap 买入项目代币，按批次记账。") }, { n: "02", title: t("持有 · 分税"), text: t("每张有效卡牌等权。批次售满或本批满 7 天后经同步等操作分配；已分到卡上的 BNB 可单独领取。") }, { n: "03", title: t("交易 · 兑换"), text: t("卡牌自由挂单交易。本批售满或本批满 7 天后，可销毁兑换对应代币及未领分红。") }].map(item => <div key={item.n} className="border-t border-border pt-5"><span className="font-mono text-xs text-primary">{item.n} /</span><h3 className="mb-3 mt-4 text-base">{item.title}</h3><p className="text-xs leading-6 text-muted-foreground">{item.text}</p></div>)}</div></section>
        <footer className="flex flex-wrap items-center justify-between gap-4 border-t border-border py-7 text-xs text-muted-foreground"><FagentLogo square={false} className="h-auto w-32" /><span>{t("BNB Chain · 无固定收益承诺 · 数字资产存在风险")}</span><Button asChild variant="ghost" size="sm"><Link to="/rules">{t("合约规则")}<ArrowUpRight /></Link></Button></footer>
      </main>

      <CommandDialog text={command} onClose={() => setCommand(null)} />

    </div>
  );
}