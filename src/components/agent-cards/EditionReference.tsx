import { useState } from "react";
import { formatEther } from "viem";
import { Button } from "@/components/ui/button";
import { ANTAGENT_EDITION as E, EDITION_RULES, antagentQuote } from "@/lib/fagent/antagent-edition";

type Language = "zh" | "en";
const nf = (value: number) => value.toLocaleString("en-US");
export function EditionStatus({ language }: { language: Language }) {
  return <p className="gx-callout" role="status">{language === "zh" ? "ANTAGENT 尚未上线，铸造、交易与领取暂未开放。" : "ANTAGENT is not live yet. Minting, trading and claims are not open."}</p>;
}

export function RarityReference({ language }: { language: Language }) {
  const i = language === "zh" ? 0 : 1;
  return <>
    <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      {E.tiers.map((tier, index) => <article key={tier.weight} className="rounded-lg border border-border bg-card p-6">
        <p className="gx-kicker">0{index + 1} / {tier.name[1]}</p>
        <h2 className="mt-4 text-2xl font-semibold">{tier.name[i]}</h2>
        <p className="mt-7 font-mono text-5xl text-primary">{tier.weight / 2}<span className="ml-2 text-sm text-muted-foreground">{i === 0 ? "倍分红" : "× dividends"}</span></p>
        <dl className="mt-6 space-y-3 border-t border-border pt-5 text-sm">
          <div className="flex justify-between gap-2"><dt className="text-muted-foreground">{i === 0 ? "卡组数量" : "Deck count"}</dt><dd>{nf(tier.count)}</dd></div>
          <div className="flex justify-between gap-2"><dt className="text-muted-foreground">{i === 0 ? "初始占比" : "Initial share"}</dt><dd>{(tier.count / E.totalCards * 100).toFixed(2)}%</dd></div>
          <div className="flex justify-between gap-2"><dt className="text-muted-foreground">{i === 0 ? "分红基准" : "Dividend baseline"}</dt><dd>{i === 0 ? "普通卡 = 1 倍" : "Common = 1×"}</dd></div>
        </dl>
      </article>)}
    </div>
    <div className="mt-10 border-t border-border pt-8">
      <h2 className="text-2xl font-semibold">{i === 0 ? "先封存，后揭晓，再参与分红" : "Seal. Reveal. Share dividends."}</h2>
      <p className="mt-4 max-w-3xl text-sm leading-8 text-muted-foreground">{i === 0 ? "未揭晓的卡牌不参与分红。等级从剩余卡组中随机抽取，抽取概率随剩余数量变化。预售退款会归还该卡对应的等级名额，其他销毁不补回名额。" : "Unrevealed cards earn no dividends. Tiers are drawn randomly from the remaining deck, so odds change with available counts. Presale refunds restore the card's tier slot; other burns do not refill slots."}</p>
      <p className="gx-callout mt-6">{i === 0 ? "普通卡为 1 倍，稀有卡 2.5 倍，史诗卡 7 倍，传奇卡 20 倍。例：只有一张普通卡和一张传奇卡参与，若可分红 21 ANTB，普通卡得 1 ANTB，传奇卡得 20 ANTB。实际金额取决于参与分红的卡牌和可分配资金，不是固定收益；分红倍数不提高对决胜率。" : "Common earns 1×, Rare 2.5×, Epic 7× and Legendary 20× the dividends of a Common card. Example: with only one Common and one Legendary sharing 21 ANTB, they receive 1 and 20 ANTB respectively. Actual payouts depend on eligible cards and available funds, not a fixed return. Dividend multipliers do not increase duel odds."}</p>
    </div>
  </>;
}

export function EditionSummary({ language }: { language: Language }) {
  const zh = language === "zh";
  return <><dl className="mt-8 grid grid-cols-2 gap-6 lg:grid-cols-4">
    {[[zh ? "预售开池门槛" : "Presale launch threshold", "8,429", zh ? "张付费卡" : "paid cards"], [zh ? "开池配置" : "Pool allocation", "120", "ANTB"], [zh ? "卡牌上限" : "Card cap", "777,777", zh ? "张" : "cards"], [zh ? "分红倍数" : "Dividend multipliers", "1 / 2.5 / 7 / 20", zh ? "普通卡为 1 倍" : "Common = 1×"]].map(([label, value, note]) => <div key={label} className="border-b border-border py-5"><dt className="text-xs text-muted-foreground">{label}</dt><dd className="mt-3 text-2xl font-semibold">{value}</dd><dd className="mt-2 text-xs text-primary">{note}</dd></div>)}
  </dl></>;
}

export function TokenReference({ language }: { language: Language }) {
  const zh = language === "zh";
  const allocations = [
    [zh ? "开池流动性" : "Opening liquidity", E.poolTokens],
    [zh ? "预售卡配置" : "Presale grants", E.presaleCards * E.cardGrant],
    [zh ? "团队卡配置" : "Team grants", E.teamCards * E.cardGrant],
    [zh ? "阶梯认购储备" : "Ladder reserve", E.ladderTokens],
    [zh ? "开池销毁" : "Burned at launch", E.burnedAtLaunch],
  ] as const;
  return <><EditionStatus language={language} />
    <p className="mt-10 text-sm text-muted-foreground">{zh ? "固定总量" : "Fixed supply"}</p>
    <h2 className="mt-3 break-words font-mono text-4xl text-primary">777,777,777</h2>
    <dl className="mt-8 divide-y divide-border">{allocations.map(([label, amount]) => <div key={label} className="grid grid-cols-2 items-center gap-4 py-6 sm:grid-cols-3"><dt>{label}</dt><dd className="text-right font-mono">{nf(amount)}</dd><dd className="col-span-2 text-right text-sm text-muted-foreground sm:col-span-1">{(amount / E.totalTokens * 100).toFixed(2)}%</dd></div>)}</dl>
    <p className="gx-callout mt-6">{zh ? "团队卡 19,745 张，约占卡牌总量 2.54%；团队代币配置 166,647,800 枚，约占代币总量 21.43%。配置先锁定，每 19 张付费卡解锁 1 张团队卡，领取与释放遵循规则。" : "19,745 team cards are about 2.54% of NFT supply. Their 166,647,800-token allocation is about 21.43% of token supply. Slots unlock one per 19 paid cards; claiming and vesting follow the rules."}</p>
    <p className="mt-6 text-sm leading-8 text-muted-foreground">{zh ? "120 ANTB 与 63,300,000 枚项目代币进入主池，LP 销毁；未分配的 446,930,459 枚代币在同笔开池交易中转入黑洞地址。阶梯认购收入以 ANTB 流向持卡分红，详见规则页。" : "120 ANTB and 63,300,000 project tokens enter the pool, and LP is burned. The unallocated 446,930,459 tokens go to the dead address in the same launch transaction. Ladder subscription proceeds fund ANTB card dividends; see the rules for details."}</p>
  </>;
}

export function EditionCalculator({ language }: { language: Language }) {
  const zh = language === "zh";
  const [index, setIndex] = useState(1);
  const [count, setCount] = useState(1);
  const [rate, setRate] = useState(10000);
  const total = antagentQuote(index, count, rate);
  return <section className="mt-8 grid gap-8 border-y border-border py-8 md:grid-cols-2">
    <div>
      <label htmlFor="edition-index" className="block text-sm">{zh ? "全站已售出付费卡数量（试算）" : "Paid cards already sold (estimate)"}</label>
      <input id="edition-index" type="number" min={0} max={E.paidCards - count} value={index - 1} className="gx-field mt-3" onChange={event => setIndex(Math.max(1, Math.min(E.paidCards - count + 1, Math.floor(Number(event.target.value) || 0) + 1)))} />
      <label htmlFor="edition-count" className="mt-5 block text-sm">{zh ? "本笔数量" : "Cards in this batch"}</label>
      <input id="edition-count" type="range" min={1} max={10} value={count} className="mt-4" onChange={event => { const n = Number(event.target.value); setCount(n); setIndex(current => Math.min(current, E.paidCards - n + 1)); }} />
      <p className="mt-3 font-mono text-primary">{count} / 10</p>
      <label htmlFor="edition-discount" className="mt-5 block text-sm">{zh ? "Agent ID 持有折扣（试算）" : "Agent ID holding discount (estimate)"}</label>
      <select id="edition-discount" value={rate} onChange={event => setRate(Number(event.target.value))} className="gx-field mt-3">
        <option value={10000}>{zh ? "原价 / 无有效证明" : "Full price / no eligible proof"}</option>
        <option value={9000}>{zh ? "满 10 天 · 九折" : "10 days · 10% off"}</option>
        <option value={8500}>{zh ? "满 20 天 · 八五折" : "20 days · 15% off"}</option>
        <option value={8000}>{zh ? "满 30 天 · 八折" : "30 days · 20% off"}</option>
      </select>
    </div>
    <div className="flex flex-col justify-center">
      <p className="gx-kicker">ANTB / {zh ? "铸造费用试算" : "LADDER ESTIMATE"}</p>
      <p className="mt-5 break-words text-4xl font-semibold text-primary">{formatEther(total)} <span className="text-base">ANTB</span></p>
      <p className="mt-5 text-sm leading-7 text-muted-foreground">{zh ? "预计铸造费用按购买数量和所选折扣计算，不含网络手续费与卡牌揭晓服务费。享受折扣需当前持有 Agent ID，并通过历史持有验证；实际费用以交易确认时为准。" : "Estimated mint costs follow the batch size and selected discount, excluding network and card-reveal fees. Discounts require a current Agent ID and verified holding history. Actual costs are determined at transaction confirmation."}</p>
      <Button variant="outline" className="mt-6 self-start" disabled>{zh ? "铸造待上线" : "Minting not open"}</Button>
    </div>
  </section>;
}

export function EditionInner({ language, view }: { language: Language; view: "market" | "vault" | "commands" | "ladder" | "duel" }) {
  const zh = language === "zh";
  const ids = view === "vault" ? [6, 7] : view === "ladder" ? [8] : view === "duel" ? [10] : view === "commands" ? [0, 1, 2] : [0, 4, 5];
  return <>
    <EditionStatus language={language} />
    {view === "market" && <p className="mt-6 text-sm leading-8 text-muted-foreground">{zh ? "卡牌以 ANTB 挂单出售或发布求购。成交费为 1%，卖家收到扣费后的价款和该卡已累积的分红。市场暂未开放。" : "List cards or place bids in ANTB. The trading fee is 1%; sellers receive the net price plus accrued card dividends. The market is not open yet."}</p>}
    {view === "commands" && <p className="mt-6 text-sm leading-8 text-muted-foreground">{zh ? "通过 Binance Agent Wallet 确认每笔铸造、交易与领取。网站不代签或自动提交交易。请准备 ANTB 付款，以及支付网络和服务费用的 BNB；操作暂未开放。" : "Confirm each mint, trade and claim through Binance Agent Wallet. The website never signs or automatically submits transactions. Prepare ANTB for payments and BNB for network and service fees. Operations are not open yet."}</p>}
    <div className="mt-8 space-y-8">{ids.map(id => {
      const entry = EDITION_RULES[id];
      if (!entry) return null;
      const [title, body] = zh ? entry.zh : entry.en;
      return <section key={id} className="border-t border-border pt-6"><h2 className="text-2xl font-semibold">{title}</h2>{body.split("\n").map(line => <p key={line} className="mt-4 text-sm leading-8 text-muted-foreground">{line}</p>)}</section>;
    })}</div>
  </>;
}