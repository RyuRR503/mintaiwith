import { useState } from "react";
import { formatEther } from "viem";
import { Button } from "@/components/ui/button";
import { AntWordmark } from "./FagentLogo";
import { ANTAGENT_EDITION as E, antagentPrice } from "@/lib/fagent/antagent-edition";
import { EDITION_DEMO as D, previewOrderBook } from "@/lib/fagent/edition-demo";

type Language = "zh" | "en";
function VaultLedger({ language }: { language: Language }) {
  const zh = language === "zh";
  const entries = [
    [zh ? "累计已入账税收" : "Total tax received", D.vault.taxRevenue, "ANTB"],
    [zh ? "已分给持卡人" : "Tax allocated to cardholders", D.vault.dividendForwarded, "ANTB"],
    [zh ? "已计入地板基金" : "Allocated to floor fund", D.vault.floorForwarded, "ANTB"],
    [zh ? "地板买走并销毁的卡" : "Cards burned by floor buybacks", D.vault.floorBurnedCards, zh ? "张" : "cards"],
    [zh ? "已销毁代币" : "Tokens burned", D.burnedTokens.toLocaleString("en-US"), zh ? "枚" : "tokens"],
    [zh ? "已领取的分红" : "Dividends paid", D.vault.dividendPaid, "ANTB"],
    [zh ? "已记账、还没领的分红" : "Accrued dividends awaiting claim", D.vault.dividendLiability, "ANTB"],
    [zh ? "阶梯认购分红待释放" : "Ladder dividends awaiting release", D.vault.streamRemaining, "ANTB"],
  ];
  return <section aria-label={zh ? "金库账本数据" : "Vault ledger metrics"}>
    <dl className="grid gap-3 sm:grid-cols-2 lg:grid-cols-[1.6fr_1fr_1fr]">
      {entries.map(([label, value, unit], i) => <div key={label} className={`flex min-w-0 flex-col rounded-lg border border-border p-6 ${i === 0 ? "bg-accent sm:col-span-2 lg:col-span-1 lg:row-span-2" : "bg-card"}`}>
        <span aria-hidden="true" className="font-mono text-xs text-primary">{String(i + 1).padStart(2, "0")}</span>
        <dt className="mt-4 text-sm text-muted-foreground">{label}</dt>
        <dd className={`mt-6 flex flex-wrap items-baseline gap-x-2 gap-y-1 font-mono ${i === 0 ? "text-4xl lg:mt-auto lg:pt-10" : "text-2xl"}`}><span className="break-all">{value}</span><span className="text-xs text-muted-foreground">{unit}</span></dd>
      </div>)}
    </dl>
    <dl className="mt-6 grid grid-cols-2 gap-6 border-y border-border py-5"><div><dt className="text-xs text-muted-foreground">{zh ? "地板基金当前余额" : "Current floor balance"}</dt><dd className="mt-3 font-mono text-lg">{D.floor} ANTB</dd></div><div><dt className="text-xs text-muted-foreground">{zh ? "加池储备当前余额" : "Current liquidity reserve"}</dt><dd className="mt-3 font-mono text-lg">{D.liquidity} ANTB</dd></div></dl>
  </section>;
}
export function DemoTotals({ language }: { language: Language }) {
  const zh = language === "zh";
  return <section className="mt-8" aria-label={zh ? "演示账本" : "Demo ledger"}>
    <p className="text-xs text-primary">{zh ? "演示数据 · 开池后" : "Demo data · After pool launch"}</p>
    <dl className="mt-4 grid grid-cols-2 gap-6 lg:grid-cols-4">{[
      [zh ? "已销毁代币" : "Tokens burned", D.burnedTokens.toLocaleString("en-US"), zh ? "枚" : "tokens"],
      [zh ? "已销毁卡牌" : "Cards burned", D.burnedCards, zh ? "张" : "cards"],
      [zh ? "累计分红" : "Total dividends", D.dividends, "ANTB"],
      [zh ? "地板基金余额" : "Floor fund", D.floor, "ANTB"],
    ].map(([label, value, unit]) => <div key={label} className="border-b border-border py-5"><dt className="text-xs text-muted-foreground">{label}</dt><dd className="mt-3 break-words font-mono text-xl">{value}<span className="ml-2 text-xs text-muted-foreground">{unit}</span></dd></div>)}</dl>
  </section>;
}

export function EditionDemo({ language, view }: { language: Language; view: "market" | "vault" | "commands" | "ladder" | "duel" | "minting" | "rarity" }) {
  const zh = language === "zh";
  const [filter, setFilter] = useState(-1);
  const [selected, setSelected] = useState<number | null>(null);
  const [marketTier, setMarketTier] = useState(0);
  const card = D.cards.find(item => item.id === selected);
  const orders = previewOrderBook(marketTier);
  return <section className="mt-8 border-y border-border py-8" aria-label={zh ? "演示数据" : "Demo data"}>
    <p className="mb-6 text-xs text-primary">{zh ? "演示数据 · 非真实链上记录" : "Demo data · Not on-chain records"}</p>
    {view === "market" && <>
      <div className="mb-6 flex flex-wrap gap-2" role="tablist" aria-label={zh ? "挂单稀有度" : "Order rarity"}>
        {E.tiers.map((tier, i) => <Button key={tier.weight} role="tab" aria-selected={marketTier === i} variant={marketTier === i ? "default" : "outline"} onClick={() => setMarketTier(i)}>{tier.name[zh ? 0 : 1]} · {tier.weight / 2}×</Button>)}
      </div>
      <div className="grid gap-10 lg:grid-cols-2">
      <section aria-label={zh ? "卖单" : "Sell orders"}>
        <div className="mb-4 flex flex-wrap items-baseline justify-between gap-2"><h3 className="text-xl">{E.tiers[marketTier]?.name[zh ? 0 : 1]} · {zh ? "卖单" : "Sell orders"}</h3><span className="text-xs text-muted-foreground">{zh ? "价格从低到高 · 前 20 条" : "Lowest first · Top 20"}</span></div>
        <table className="w-full table-fixed text-left text-sm"><thead className="text-xs text-muted-foreground"><tr><th className="py-3 font-normal">{zh ? "出价（ANTB）" : "Price (ANTB)"}</th><th className="text-right font-normal">{zh ? "数量（张）" : "Quantity (cards)"}</th></tr></thead>
          <tbody>{orders.sells.map(item => <tr key={item.id} className="border-t border-border"><td className="py-3 font-mono text-primary">{item.price}</td><td className="text-right font-mono">1</td></tr>)}</tbody>
        </table>
      </section>
      <section aria-label={zh ? "买单" : "Buy orders"}>
        <div className="mb-4 flex items-baseline justify-between"><h3 className="text-xl">{zh ? "买单" : "Buy orders"}</h3><span className="text-xs text-muted-foreground">{zh ? "价格从高到低 · 前 20 条" : "Highest first · Top 20"}</span></div>
        <p className="mb-3 text-xs leading-6 text-muted-foreground">{zh ? "买单不限定稀有度，四档卡牌均可成交。" : "Bids accept any revealed rarity; the same bids apply to all four tiers."}</p>
        <table className="w-full table-fixed text-left text-sm"><thead className="text-xs text-muted-foreground"><tr><th className="py-3 font-normal">{zh ? "出价（ANTB）" : "Price (ANTB)"}</th><th className="text-right font-normal">{zh ? "数量（张）" : "Quantity (cards)"}</th></tr></thead>
          <tbody>{orders.buys.map(item => <tr key={item.id} className="border-t border-border"><td className="py-3 font-mono text-primary">{item.price}</td><td className="text-right font-mono">{item.quantity}</td></tr>)}</tbody>
        </table>
      </section>
    </div></>}
    {(view === "rarity" || view === "duel") && <>
      <div className="mb-6 flex flex-wrap gap-2" role="group" aria-label={zh ? "稀有度筛选" : "Rarity filter"}>
        <Button size="sm" variant={filter === -1 ? "default" : "outline"} onClick={() => setFilter(-1)}>{zh ? "全部" : "All"}</Button>
        {E.tiers.map((tier, i) => <Button key={tier.weight} size="sm" variant={filter === i ? "default" : "outline"} onClick={() => setFilter(i)}>{tier.name[zh ? 0 : 1]}</Button>)}
      </div>
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">{D.cards.filter(item => filter === -1 || item.tier === filter).map(item => {
        const tier = E.tiers[item.tier];
        if (!tier) return null;
        return <article key={item.id} className="rounded-lg border border-border bg-card p-5">
          <div className="flex aspect-[4/3] flex-col justify-between border border-border bg-background p-4"><AntWordmark /><span className="self-center font-display text-4xl text-primary">{tier.weight / 2}×</span><span className="font-mono text-xs text-muted-foreground">#{String(item.id).padStart(6, "0")} · {tier.name[zh ? 0 : 1]}</span></div>
          <dl className="mt-5 space-y-3 text-sm"><div className="flex justify-between gap-2"><dt className="text-muted-foreground">{zh ? "挂单价格" : "Ask price"}</dt><dd>{item.price} ANTB</dd></div><div className="flex justify-between gap-2"><dt className="text-muted-foreground">{zh ? "已累积分红" : "Accrued dividends"}</dt><dd>{item.dividend}</dd></div>{view === "duel" && <div className="flex justify-between"><dt>{zh ? "胜场" : "Wins"}</dt><dd>{item.wins} / 6</dd></div>}</dl>
          <Button className="mt-5 w-full" variant="outline" onClick={() => setSelected(item.id)}>{zh ? "查看卡牌" : "View card"}</Button>
        </article>;
      })}</div>
      {card && <div className="mt-6 border-l-2 border-primary bg-accent p-5" role="status"><div className="flex flex-wrap justify-between gap-3"><h3 className="text-lg">#{String(card.id).padStart(6, "0")}</h3><Button variant="ghost" size="sm" onClick={() => setSelected(null)}>{zh ? "关闭" : "Close"}</Button></div><p className="mt-3 text-sm leading-7">{zh ? `演示挂单 ${card.price} ANTB，累积分红 ${card.dividend} ANTB。卡牌已揭晓，代币释放进度 68%。` : `Demo ask: ${card.price} ANTB. Accrued dividends: ${card.dividend} ANTB. Rarity revealed; token release 68%.`}</p><Button className="mt-4" disabled>{zh ? "真实交易未开放" : "Live trading not open"}</Button></div>}
      {view === "duel" && <div className="mt-8 grid gap-6 sm:grid-cols-2"><div className="border-t border-border pt-5"><h3>{zh ? "对决 #018 · 等待配对" : "Duel #018 · Waiting"}</h3><p className="mt-3 text-sm text-muted-foreground">#002067 · {zh ? "稀有卡 · 2 胜" : "Rare · 2 wins"}</p></div><div className="border-t border-border pt-5"><h3>{zh ? "对决 #019 · 已配对" : "Duel #019 · Paired"}</h3><p className="mt-3 text-sm text-muted-foreground">#008421 vs #010986 · {zh ? "等待随机结算" : "Awaiting random settlement"}</p></div></div>}
    </>}
    {view === "vault" && <><VaultLedger language={language} /><h3 className="mt-8 text-xl">{zh ? "最近收支" : "Recent ledger entries"}</h3><div className="mt-4 overflow-x-auto"><table className="w-full text-left text-sm"><thead><tr><th className="py-3">{zh ? "时间" : "Time"}</th><th>{zh ? "项目" : "Entry"}</th><th>{zh ? "收支 ANTB" : "Amount ANTB"}</th></tr></thead><tbody>{D.ledger.map(item => <tr key={item.time} className="border-t border-border"><td className="py-4 pr-4 font-mono">{item.time}</td><td className="pr-4">{item.kind[zh ? 0 : 1]}</td><td className="font-mono text-primary">{item.amount}</td></tr>)}</tbody></table></div></>}
    {view === "ladder" && <div className="grid gap-6 sm:grid-cols-3">{[1.5, 2, 3].map((multiple, i) => <article key={multiple} className="border-t border-border py-5"><h3 className="text-3xl text-primary">{multiple}×</h3><p className="mt-3 text-sm">{zh ? "开池价" : "Opening price"}</p><p className="mt-5 font-mono">{(E.ladderTokens / 3 - i * 125000).toLocaleString("en-US")} <span className="text-xs">{zh ? "枚剩余（演示）" : "tokens left (demo)"}</span></p><p className="mt-3 text-sm text-muted-foreground">{i === 0 ? (zh ? "达到门槛 · 可认购" : "Threshold met · Available") : (zh ? "未达到门槛" : "Threshold not met")}</p><Button variant="outline" className="mt-5" disabled>{zh ? "认购未开放" : "Subscriptions not open"}</Button></article>)}</div>}
    {(view === "commands" || view === "minting") && <dl className="grid grid-cols-2 gap-6"><div><dt className="text-xs text-muted-foreground">{zh ? "我的卡牌（演示）" : "My cards (demo)"}</dt><dd className="mt-3 text-2xl">10</dd></div><div><dt className="text-xs text-muted-foreground">{zh ? "剩余铸造额度（演示）" : "Remaining mint quota (demo)"}</dt><dd className="mt-3 text-2xl">10 / 20</dd></div><div><dt className="text-xs text-muted-foreground">{zh ? "满 30 天折扣价（演示）" : "30-day discounted price (demo)"}</dt><dd className="mt-3 font-mono text-lg">{formatEther(antagentPrice(D.paidMinted + 1) * 8000n / 10000n)} ANTB</dd></div><div><dt className="text-xs text-muted-foreground">{zh ? "可领分红（演示）" : "Claimable dividends (demo)"}</dt><dd className="mt-3 font-mono text-lg">0.0641 ANTB</dd></div></dl>}
  </section>;
}