import { useLanguage } from "./LanguageProvider";
import { useState } from "react";
import { useServerFn } from "@tanstack/react-start";
import { isAddress } from "viem";
import { Copy, Check, Search } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { getWallet, getCard } from "@/lib/fagent/chain.functions";
import { cardCommand } from "@/lib/fagent/commands";
import { explorer, redemptionReady } from "@/lib/fagent/config";
import { binanceCard, useCommandStyle } from "@/lib/fagent/binance";
import { StyleSwitch } from "./AgentCommands";

export function CommandDialog({ text: general, binanceText, onClose }: { text: string | null; binanceText?: string | null; onClose: () => void }) {
  const { t } = useLanguage();
  const [style, setStyle] = useCommandStyle();
  const text = general !== null && binanceText && style === "binance" ? binanceText : general;
  const [copied, setCopied] = useState(false);
  const [error, setError] = useState("");
  return <Dialog open={text !== null} onOpenChange={open => { if (!open) { setCopied(false); setError(""); onClose(); } }}><DialogContent className="max-w-2xl"><DialogHeader><DialogTitle>{t("币安 Agent 钱包指令")}</DialogTitle><DialogDescription>{t("发送给你的币安 Agent 钱包，核对交易预览后确认；网站不会代你发送交易。")}</DialogDescription></DialogHeader>{binanceText && <StyleSwitch style={style} onChange={s => { setStyle(s); setCopied(false); }} />}<textarea aria-label={t("交易指令")} className="h-64 w-full resize-none border border-input bg-background p-3 text-xs leading-6 text-foreground" value={text ?? ""} readOnly /><Button onClick={async () => { try { await navigator.clipboard.writeText(text ?? ""); setCopied(true); setError(""); } catch { setError(t("复制失败，请选中上方文字手动复制。")); } }}>{copied ? <Check /> : <Copy />}{copied ? t("已复制") : t("复制指令")}</Button>{error && <p role="alert" className="text-sm text-destructive">{t(error)}</p>}</DialogContent></Dialog>;
}

export function WalletCheck({ onResult }: { onResult?: (data: NonNullable<Awaited<ReturnType<typeof getWallet>>["data"]>) => void }) {
  const { t } = useLanguage();
  const [address, setAddress] = useState("");
  const [result, setResult] = useState<{ data: Awaited<ReturnType<typeof getWallet>>["data"]; error: string | null } | null>(null);
  const [busy, setBusy] = useState(false);
  const load = useServerFn(getWallet);
  return <div className="space-y-3"><label className="block text-xs text-muted-foreground" htmlFor="wallet-check">{t("币安 Agent 钱包地址")}</label><div className="flex gap-2"><input id="wallet-check" aria-label={t("钱包地址")} placeholder="0x…" value={address} onChange={e => { setAddress(e.target.value); setResult(null); }} className="h-10 min-w-0 flex-1 border border-input bg-background px-3 font-mono text-xs text-foreground" /><Button variant="outline" disabled={busy || !isAddress(address)} onClick={async () => { setBusy(true); try { const next = await load({ data: { address } }); setResult(next); if (next.data) onResult?.(next.data); } catch { setResult({ data: null, error: t("读取失败，请重试。") }); } finally { setBusy(false); } }}><Search />{busy ? t("查询中") : t("查询")}</Button></div>{result?.error && <p role="alert" className="text-xs text-destructive">{t(result.error)}</p>}{result?.data && <div className="space-y-2 text-xs"><p>Agent ID：<span className="text-primary">{result.data.hasAgentId ? t("已持有") : t("未持有，不能付费铸造")}</span></p><p>{t("已用名额")}{result.data.used} {t("/ 7 · 剩余")}{Math.max(0, 7 - result.data.used)} {t("张")}</p><p>{t("BNB 余额：")}{result.data.balance}</p><p>{t("待提取卖卡款：")}{Number(result.data.proceeds) / 1e18} BNB</p></div>}</div>;
}

export function CardCheck() {
  const { t, language } = useLanguage();
  const [id, setId] = useState("");
  const [result, setResult] = useState<{ data: Awaited<ReturnType<typeof getCard>>["data"]; error: string | null } | null>(null);
  const [busy, setBusy] = useState(false);
  const [command, setCommandState] = useState<string | null>(null);
  const [binanceText, setBinanceText] = useState<string | null>(null);
  const setCommand = (text: string | null, kind?: "claim" | "redeem" | "list" | "unlist", cardId?: number, p?: string) => { setCommandState(text); setBinanceText(kind && cardId !== undefined ? binanceCard(kind, cardId, p, language) : null); };
  const [price, setPrice] = useState("0.003");
  const load = useServerFn(getCard);
  const card = result?.data;
  const ready = card ? redemptionReady(card.accounted, card.openedAt, card.releaseSeconds, card.chainTime) : false;
  return <section className="mt-10 border-t border-border pt-7"><h3 className="text-lg">{t("卡牌权益查询")}</h3><div className="mt-4 flex max-w-md gap-2"><input aria-label={t("卡牌编号")} placeholder={t("卡牌编号，例如 500")} inputMode="numeric" value={id} onChange={e => { setId(e.target.value); setResult(null); }} className="h-10 min-w-0 flex-1 border border-input bg-background px-3 font-mono text-xs text-foreground" /><Button variant="outline" disabled={busy || !/^\d+$/.test(id) || Number(id) > 769999} onClick={async () => { setBusy(true); try { setResult(await load({ data: { id: Number(id) } })); } catch { setResult({ data: null, error: t("卡牌读取失败，请重试。") }); } finally { setBusy(false); } }}><Search />{busy ? t("查询中") : t("查询卡牌")}</Button></div>{result?.error && <p role="alert" className="mt-3 text-sm text-destructive">{t(result.error)}</p>}{card && <div className="mt-5 space-y-3 text-sm"><p>#{card.id} {t("· 第")}{Math.floor(card.id / 10000) + 1} {t("批 ·")}{card.active ? t("有效") : t("无效")}</p><p className="break-all text-xs">{t("持有人：")}<a className="text-primary" href={explorer(card.owner)} target="_blank" rel="noreferrer">{card.owner}</a></p><p>{t("已分配未领分红：")}{card.dividend} BNB</p><p>{t("当前可兑换：")}{card.tokens} FAGENT</p><p className="text-muted-foreground">{ready ? t("已达到兑换条件，实际数量以交易预览为准。") : t("本批尚未售满且未满 7 天，暂不可兑换。")}</p><div className="flex flex-wrap gap-2"><Button variant="outline" disabled={!card.active} onClick={() => setCommand(cardCommand("claim", card.id, undefined, language), "claim", card.id)}>{t("领取分红")}</Button><Button variant="outline" disabled={!card.active || !ready} onClick={() => setCommand(cardCommand("redeem", card.id, undefined, language), "redeem", card.id)}>{t("销毁兑换")}</Button><Button variant="outline" onClick={() => setCommand(cardCommand("unlist", card.id, undefined, language), "unlist", card.id)}>{t("下架挂单")}</Button></div><div className="flex max-w-md gap-2"><input aria-label={t("挂单售价 BNB")} type="number" min="0.000000001" step="0.001" value={price} onChange={e => setPrice(e.target.value)} className="h-10 min-w-0 flex-1 border border-input bg-background px-3 font-mono text-xs text-foreground" /><Button disabled={!card.active || !Number.isFinite(Number(price)) || Number(price) <= 0} onClick={() => { try { setCommand(cardCommand("list", card.id, price, language), "list", card.id, price); } catch { setResult({ data: card, error: t("价格格式或金额超出合约范围。") }); } }}>{t("挂单出售")}</Button></div></div>}<CommandDialog text={command} binanceText={binanceText} onClose={() => setCommand(null)} /></section>;
}