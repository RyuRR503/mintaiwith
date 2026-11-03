import { useLanguage } from "./LanguageProvider";
import { useState } from "react";
import { Check, Copy } from "lucide-react";
import { Button } from "@/components/ui/button";
import { getAgentCommands } from "@/lib/fagent/commands";
import { getBinanceCommands, useCommandStyle, type CommandStyle } from "@/lib/fagent/binance";
import { 7AGENT, explorer } from "@/lib/fagent/config";
import { CardCheck, WalletCheck } from "./ChainTools";

export function StyleSwitch({ style, onChange }: { style: CommandStyle; onChange: (s: CommandStyle) => void }) {
  const { language } = useLanguage();
  const en = language === "en";
  return <div role="group" aria-label={en ? "Command format" : "指令格式"} className="inline-flex border border-border">{(["general", "binance"] as const).map(s => <button key={s} type="button" aria-pressed={style === s} onClick={() => onChange(s)} className={`px-3 py-1.5 text-xs ${style === s ? "bg-primary text-primary-foreground" : "text-muted-foreground"}`}>{s === "general" ? (en ? "General AI" : "通用 AI") : (en ? "Binance Wallet" : "币安钱包")}</button>)}</div>;
}

export function AgentCommands() {
  const { t, language } = useLanguage();
  const agentCommands = getAgentCommands(language);
  const binance = getBinanceCommands(language);
  const [style, setStyle] = useCommandStyle();
  const [copied, setCopied] = useState<string | null>(null);
  const [error, setError] = useState("");
  const en = language === "en";
  return <div><div className="mb-6"><h3 className="text-xl">{t("Agent 指令")}</h3><div className="mt-3 space-y-2 break-all font-mono text-xs text-muted-foreground"><p>CA：<a href={explorer(7AGENT.token)} target="_blank" rel="noreferrer" className="text-primary">{7AGENT.token}</a></p><p>Vault：<a href={explorer(7AGENT.vault)} target="_blank" rel="noreferrer" className="text-primary">{7AGENT.vault}</a></p></div><div className="mt-4 flex flex-wrap items-center gap-3"><StyleSwitch style={style} onChange={setStyle} /><p className="text-xs text-muted-foreground">{style === "binance" ? (en ? "Short format for the Binance Wallet built-in AI." : "币安钱包内置 AI 专用的短格式。") : (en ? "Full format for other AI assistants." : "适合其他 AI 助手的完整格式。")}</p></div></div>{error && <p role="alert" className="mb-4 text-sm text-destructive">{t(error)}</p>}{["铸造", "买", "卖", "收益"].map(group => <section key={group} className="mb-8"><p className="mb-3 font-mono text-xs text-primary">{group === "买" ? t("买入 · 买单") : group === "卖" ? t("卖出 · 卖单") : t(group)}</p><div className="grid gap-3 md:grid-cols-2">{agentCommands.map((c, i) => ({ ...c, text: style === "binance" ? binance[i] : c.text })).filter(c => c.group === group).map(c => <article key={c.title} className="flex flex-col border border-border p-4"><div className="flex flex-wrap items-start justify-between gap-3"><h4 className="text-base">{c.title}</h4><code className="break-all text-[10px] text-muted-foreground">{c.fn}</code></div><p className="mt-2 flex-1 text-xs leading-6 text-muted-foreground">{c.desc}</p><Button size="sm" variant="outline" className="mt-4 w-full" onClick={async () => { try { await navigator.clipboard.writeText(c.text ?? ""); setCopied(c.title); setError(""); setTimeout(() => setCopied(null), 1800); } catch { setError(t("复制失败，请重试。")); } }}>{copied === c.title ? <Check /> : <Copy />}{copied === c.title ? t("已复制") : t("复制指令")}</Button></article>)}</div></section>)}<section className="max-w-xl border-t border-border pt-7"><h3 className="mb-4 text-lg">{t("铸造资格查询")}</h3><WalletCheck /></section><CardCheck /></div>;
}
