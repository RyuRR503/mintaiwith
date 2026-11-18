import { useLanguage } from "./LanguageProvider";
import { useState } from "react";
import { Check, Copy } from "lucide-react";
import { Button } from "@/components/ui/button";
import { getAgentCommands } from "@/lib/fagent/commands";
import { getBinanceCommands, useCommandStyle, type CommandStyle } from "@/lib/fagent/binance";
import { DeploymentContracts } from "./DeploymentContracts";
import { useSuspenseQuery } from "@tanstack/react-query";
import { snapshotOptions } from "@/lib/fagent/queries";
import { CardCheck, WalletCheck } from "./ChainTools";

export function StyleSwitch({ style, onChange }: { style: CommandStyle; onChange: (s: CommandStyle) => void }) {
  const { language } = useLanguage();
  const en = language === "en";
  return <div role="group" aria-label={en ? "Command format" : "指令格式"} className="inline-flex border border-border">{(["general", "binance"] as const).map(s => <Button variant="ghost" key={s} type="button" aria-pressed={style === s} onClick={() => onChange(s)} className={`px-3 py-1.5 text-xs ${style === s ? "bg-primary text-primary-foreground" : "text-muted-foreground"}`}>{s === "general" ? (en ? "General AI" : "通用 AI") : (en ? "Binance Wallet" : "币安钱包")}</Button>)}</div>;
}

export function AgentCommands() {
  const { t, language } = useLanguage();
  const { data: snapshot } = useSuspenseQuery(snapshotOptions());
  const agentCommands = getAgentCommands(language);
  const binance = getBinanceCommands(language);
  const [style, setStyle] = useCommandStyle();
  const [copied, setCopied] = useState<string | null>(null);
  const [error, setError] = useState("");
  const en = language === "en";
  return <div><div className="gx-panel mb-10 p-6"><h3 className="text-xl font-bold">{t("Agent 指令")}</h3><DeploymentContracts vault={snapshot.data?.vault ?? null} token={snapshot.data?.token ?? null} /><div className="mt-4 flex flex-wrap items-center gap-3"><StyleSwitch style={style} onChange={setStyle} /><p className="text-xs text-muted-foreground">{style === "binance" ? (en ? "Short format for the Binance Wallet built-in AI." : "币安钱包内置 AI 专用的短格式。") : (en ? "Full format for other AI assistants." : "适合其他 AI 助手的完整格式。")}</p></div></div>{error && <p role="alert" className="mb-4 text-sm text-destructive">{t(error)}</p>}{["铸造", "买", "卖", "收益"].map(group => <section key={group} className="gx-cmd-group"><p className="gx-cmd-label">{group === "买" ? t("买入 · 买单") : group === "卖" ? t("卖出 · 卖单") : t(group)}</p><div className="grid gap-4 md:grid-cols-2">{agentCommands.map((c, i) => ({ ...c, text: style === "binance" ? binance[i] : c.text })).filter(c => c.group === group).map(c => <article key={c.title} className="gx-term"><div className="flex flex-wrap items-start justify-between gap-3"><h4 className="text-base">{c.title}</h4></div><code className="gx-term-fn">{"> "}{c.fn}</code><p className="mt-2 flex-1 text-xs leading-6 text-muted-foreground">{c.desc}</p><Button size="sm" variant="outline" className="mt-4 w-full" onClick={async () => { try { await navigator.clipboard.writeText(c.text ?? ""); setCopied(c.title); setError(""); setTimeout(() => setCopied(null), 1800); } catch { setError(t("复制失败，请重试。")); } }}>{copied === c.title ? <Check /> : <Copy />}{copied === c.title ? t("已复制") : t("复制指令")}</Button></article>)}</div></section>)}<section className="gx-panel max-w-xl p-6"><h3 className="mb-4 text-lg">{t("铸造资格查询")}</h3><WalletCheck /></section><CardCheck /></div>;
}
