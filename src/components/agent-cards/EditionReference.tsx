import { useState } from "react";
import { formatEther } from "viem";
import { Button } from "@/components/ui/button";
import { ANTAGENT_EDITION as E, EDITION_RULES, antagentPrice, antagentQuote } from "@/lib/fagent/antagent-edition";
import { EDITION_DEMO as D } from "@/lib/fagent/edition-demo";
import { EditionDemo } from "./EditionDemo";

type Language = "zh" | "en";
const nf = (value: number) => value.toLocaleString("en-US");
export function EditionStatus({ language }: { language: Language }) {
  return <p className="gx-callout" role="status">{language === "zh" ? "演示预览 · 数值与记录为演示数据，非真实链上结果。ANTAGENT 尚未上线，真实交易暂未开放。" : "Demo preview · Figures and records are mock data, not on-chain results. ANTAGENT is not live; real transactions are not open."}</p>;
}

export function MintPriceProgress({ language }: { language: Language }) {
  const zh = language === "zh";
  const sold = D.paidMinted;
  const price = antagentPrice(sold + 1);
  const remaining = E.priceSpan - sold % E.priceSpan;
  const capped = price >= E.capPrice;
  return <section className="border-y border-border py-5" aria-label={zh ? "铸造价格进度" : "Mint price progress"}>
    <dl className="grid grid-cols-2 gap-5">
      <div><dt className="text-xs text-muted-foreground">{zh ? "当前铸造价（演示）" : "Current mint price (demo)"}</dt><dd className="mt-2 text-xl font-semibold">{formatEther(antagentPrice(D.paidMinted + 1))} ANTB</dd></div>
      <div><dt className="text-xs text-muted-foreground">{zh ? "全站已铸付费卡（演示）" : "Paid cards minted (demo)"}</dt><dd className="mt-2 text-xl font-semibold">{nf(D.paidMinted)}</dd></div>
    </dl>
    <p className="mt-5 text-sm leading-7">{zh ? "每地址铸造额度：开池前最多 10 张，开池后累计最多 20 张。开池前已铸满 10 张，开池后还可补 10 张；每笔最多 10 张。" : "Per-wallet mint quota: up to 10 before launch, 20 total afterward. Minted 10 before launch? You can mint 10 more afterward. Maximum 10 per transaction."}</p>
    <div className="mt-5 border-t border-border pt-5">
      <p className="mt-4 text-xs text-muted-foreground">{zh ? "下一张原价（演示）" : "Next card full price (demo)"}</p>
      <p className="mt-2 break-words font-mono text-3xl text-primary">{formatEther(price)} <span className="text-sm">ANTB</span></p>
      <p className="mt-3 text-sm leading-6 text-muted-foreground">{capped ? (zh ? "已达到 0.16 ANTB 上限，后续原价不再上涨。" : "The 0.16 ANTB cap has been reached; full price no longer increases.") : (zh ? `本档还可铸 ${nf(remaining)} 张，随后原价升至 ${formatEther(antagentPrice(sold + remaining + 1))} ANTB。` : `${nf(remaining)} cards remain at this price, then full price rises to ${formatEther(antagentPrice(sold + remaining + 1))} ANTB.`)}</p>
      <p className="mt-3 text-xs text-muted-foreground">{zh ? "演示进度 · 尚未上线，非真实销售数据。" : "Demo progress · Not live; not actual sales data."}</p>
    </div>
  </section>;
}

export function MintLadderDetails({ language }: { language: Language }) {
  const zh = language === "zh";
  const rows = [[1, 1000], [1001, 2000], [2001, 3000], [8001, 9000], [180001, E.paidCards]] as const;
  return <section className="mt-8 border-t border-border pt-8">
    <h2 className="text-2xl font-semibold">{zh ? "铸到哪一档，就按哪一档付款" : "Your mint position determines the price"}</h2>
    <p className="mt-4 text-sm leading-8 text-muted-foreground">{zh ? "阶梯按全站累计付费铸造数量推进，不是按你个人买了多少张。每 1,000 张为一档，同档每张原价相同；下一档每张增加 0.0008 ANTB。团队卡不计入付费阶梯，开池后继续累积，不重新从起价计算。" : "The ladder follows total paid mints across all wallets, not your personal purchases. Each rung contains 1,000 cards at the same full price; the next adds 0.0008 ANTB per card. Team cards do not count. Pool launch does not reset the ladder."}</p>
    <div className="mt-6 overflow-x-auto"><table className="w-full text-left text-sm"><thead><tr className="border-b border-border"><th className="py-3 pr-4">{zh ? "全站付费铸造顺序" : "Paid mint positions"}</th><th className="py-3">{zh ? "每张原价" : "Full price per card"}</th></tr></thead><tbody>{rows.map(([start, end]) => <tr key={start} className="border-b border-border"><td className="py-4 pr-4">{nf(start)}–{nf(end)}</td><td className="py-4 font-mono text-primary">{formatEther(antagentPrice(start))} ANTB</td></tr>)}</tbody></table></div>
    <p className="mt-4 text-sm leading-7 text-muted-foreground">{zh ? "中间各档按相同规则递增。第 180,001 张起达到 0.16 ANTB 上限，后续原价保持不变。" : "Intermediate rungs follow the same increment. From paid mint 180,001, full price reaches 0.16 ANTB and stays capped."}</p>
    <h3 className="mt-8 text-xl font-semibold">{zh ? "折扣在所在档位原价上计算" : "Discounts apply to each rung’s full price"}</h3>
    <p className="mt-4 text-sm leading-8 text-muted-foreground">{zh ? "例如全站已铸 1,000 张，下一张原价为 0.0168 ANTB。持有 Agent ID 满 10 天付 0.01512 ANTB；满 20 天付 0.01428 ANTB；满 30 天付 0.01344 ANTB。只享受符合条件的最高一档折扣，不叠加；网络和揭晓服务费另付。" : "After 1,000 paid mints, the next card costs 0.0168 ANTB at full price. With an eligible Agent ID, pay 0.01512 after 10 days, 0.01428 after 20 days, or 0.01344 after 30 days. Only the highest eligible discount applies; discounts do not stack. Network and reveal fees are separate."}</p>
    <h3 className="mt-8 text-xl font-semibold">{zh ? "一笔购买跨档，逐张计价" : "A batch crossing a rung is priced card by card"}</h3>
    <p className="mt-4 text-sm leading-8 text-muted-foreground">{zh ? "例如已铸 999 张，你一次买 2 张：第 1,000 张按 0.016 ANTB，第 1,001 张按 0.0168 ANTB，原价合计 0.0328 ANTB；符合八折条件则合计 0.02624 ANTB。不是整笔都按较低档或较高档计算。" : "After 999 paid mints, buying two cards costs 0.016 ANTB for card 1,000 and 0.0168 ANTB for card 1,001: 0.0328 ANTB total at full price, or 0.02624 with the eligible 20% discount. The batch is not priced entirely at either rung."}</p>
  </section>;
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
  const [active, setActive] = useState<number | null>(4);
  const allocations = [
    [zh ? "开池流动性" : "Opening liquidity", E.poolTokens],
    [zh ? "预售卡发放" : "Presale grants", E.presaleCards * E.cardGrant],
    [zh ? "阶梯认购储备" : "Ladder reserve", E.ladderTokens],
    [zh ? "开池销毁" : "Burned at launch", E.burnedAtLaunch],
    [zh ? "团队卡" : "Team cards", E.teamCards * E.cardGrant],
  ] as const;
  const teamShare = E.teamCards / E.totalCards * 100;
  const descriptions = zh ? [
    "与 120 ANTB 一起进池，LP 销毁。",
    "8,429 张 × 8,440 枚，代币分 5 天释放。",
    "达到价格门槛后开放认购，收入分给持卡人。",
    "开池时转入黑洞地址。",
    "每铸出 19 张付费卡，解锁 1 张团队卡；未达到条件就继续锁仓。",
  ] : [
    "Paired with 120 ANTB; LP is burned.",
    "8,429 cards × 8,440 tokens, released over five days.",
    "Subscriptions open at price thresholds; proceeds fund card dividends.",
    "Sent to the dead address at pool launch.",
    "One team card unlocks per 19 paid mints. Otherwise it stays locked.",
  ];
  const circumference = 2 * Math.PI * 80;
  let cursor = 0;
  const arcs = allocations.map(([label, amount], index) => {
    const length = amount / E.totalTokens * circumference;
    const start = cursor;
    cursor += length;
    return { label, amount, index, length, start };
  });
  const selected = active === null ? undefined : arcs[active];
  return <><EditionStatus language={language} />
    <div className="edition-token-layout mt-10">
      <div className="edition-token-ring" onMouseLeave={() => setActive(null)}>
        <svg viewBox="0 0 200 200" className="edition-token-svg" role="img" aria-label={zh ? "代币分配环形图" : "Token allocation donut chart"}>
          <circle cx="100" cy="100" r="80" fill="none" stroke="var(--border)" strokeWidth="22" />
          {arcs.map(({ label, index, length, start }) => <g key={label} className={`edition-token-slice edition-token-slice-${index}`} data-active={active === index} data-dimmed={active !== null && active !== index} onMouseEnter={() => setActive(index)}>
            <title>{label}: {index === 4 ? `${Number(teamShare.toFixed(1))}% ${zh ? "占全部卡牌" : "of all cards"}` : nf(allocations[index]?.[1] ?? 0)}</title>
            {index === 4 ? Array.from({ length: 26 }, (_, mark) => <circle key={mark} cx="100" cy="100" r="80" fill="none" strokeWidth="22" strokeDasharray={`${length / 26 * .55} ${circumference - length / 26 * .55}`} strokeDashoffset={-(start + mark * length / 26)} />) : <circle cx="100" cy="100" r="80" fill="none" strokeWidth="22" strokeDasharray={`${Math.max(0, length - 2)} ${circumference - length + 2}`} strokeDashoffset={-start} />}
          </g>)}
        </svg>
        <div className="edition-token-center" aria-live="polite">
          <p className="text-sm text-muted-foreground">{selected?.label ?? (zh ? "固定总量" : "Fixed supply")}</p>
          <p className="mt-3 font-mono text-2xl font-semibold text-foreground">{active === 4 ? `${Number(teamShare.toFixed(1))}%` : nf(selected?.amount ?? E.totalTokens)}</p>
          <p className="mt-3 text-sm text-primary">{active === 4 ? (zh ? "占全部卡牌" : "of all cards") : selected ? `${(selected.amount / E.totalTokens * 100).toFixed(1)}%` : "ANTAGENT"}</p>
          {active === 4 && <p className="mt-2 text-xs text-muted-foreground">{zh ? "代币锁在合约里" : "Tokens locked in the contract"}</p>}
        </div>
      </div>
      <div className="divide-y divide-border">{allocations.map(([label, amount], index) => <Button key={label} variant="ghost" className="edition-token-row" aria-pressed={active === index} onMouseEnter={() => setActive(index)} onMouseLeave={() => setActive(null)} onFocus={() => setActive(index)} onBlur={() => setActive(null)} onClick={() => setActive(index)}>
        <span className={`edition-token-key edition-token-slice-${index}`} aria-hidden="true" />
        <span className="min-w-0 flex-1 text-left"><span className="block font-medium">{label}{index === 4 && <span className="ml-2 text-xs text-muted-foreground">{zh ? "锁仓中" : "Locked"}</span>}</span><span className="mt-2 block text-xs leading-5 text-muted-foreground">{descriptions[index]}</span></span>
        <span className="ml-auto shrink-0 text-right"><span className="block font-mono text-sm text-foreground">{index === 4 ? `${Number(teamShare.toFixed(1))}%` : nf(amount)}</span><span className="mt-1 block text-xs text-muted-foreground">{index === 4 ? (zh ? "占全部卡牌" : "of all cards") : `${(amount / E.totalTokens * 100).toFixed(1)}%`}</span></span>
      </Button>)}</div>
    </div>
    <div className="gx-callout mt-6">
      <h2 className="text-base font-semibold">{zh ? "团队卡随铸造逐张解锁，不是一次拿走" : "Team cards unlock with paid mints, not all at once"}</h2>
      <p className="mt-3 text-sm leading-7">{zh ? "团队卡只占全部卡牌的 5%，而且不能自己放出来：大家每铸出 19 张付费卡，才解锁 1 张团队卡。没人铸造，团队卡就一张也解锁不了，对应的代币一直锁在合约里，相当于锁仓。团队卡和普通卡同权，没有额外权益。" : "Team cards represent only 5% of all cards and cannot be released independently: every 19 paid mints unlock one team card. Without paid mints, no team cards unlock, and their tokens remain locked in the contract. Team cards have the same rights as ordinary cards, with no extra benefits."}</p>
      <p className="mt-3 text-sm leading-7">{zh ? "团队卡铸造时也需支付稀有度揭晓服务费，与普通卡使用同一套随机抽取规则，不能指定等级。" : "Team-card minting also requires the rarity-reveal service fee. Team and ordinary cards use the same random draw rules; a tier cannot be chosen."}</p>
    </div>
    <p className="mt-6 text-sm leading-8 text-muted-foreground">{zh ? "120 ANTB 与 63,300,000 枚项目代币进入主池，LP 销毁；未分配的 285,363,539 枚代币在同笔开池交易中转入黑洞地址。阶梯认购收入以 ANTB 流向持卡分红，详见规则页。" : "120 ANTB and 63,300,000 project tokens enter the pool, and LP is burned. The unallocated 285,363,539 tokens go to the dead address in the same launch transaction. Ladder subscription proceeds fund ANTB card dividends; see the rules for details."}</p>
  </>;
}

export function EditionCalculator({ language }: { language: Language }) {
  const zh = language === "zh";
  const index = D.paidMinted + 1;
  const [count, setCount] = useState(1);
  const [rate, setRate] = useState(10000);
  const total = antagentQuote(index, count, rate);
  return <section className="mt-8 grid gap-8 border-y border-border py-8 md:grid-cols-2">
    <div>
      <dl><dt className="text-sm text-muted-foreground">{zh ? "全站已售出付费卡（演示）" : "Paid cards sold (demo)"}</dt><dd className="mt-3 font-mono text-2xl">{nf(D.paidMinted)}</dd><dt className="mt-5 text-sm text-muted-foreground">{zh ? "当前每张原价（演示）" : "Current full price (demo)"}</dt><dd className="mt-3 font-mono text-xl text-primary">{formatEther(antagentPrice(index))} ANTB</dd></dl>
      <label htmlFor="edition-count" className="mt-5 block text-sm">{zh ? "本笔数量" : "Cards in this batch"}</label>
      <input id="edition-count" type="range" min={1} max={10} value={count} className="mt-4" onChange={event => setCount(Number(event.target.value))} />
      <p className="mt-3 font-mono text-primary">{count} / 10</p>
      <label htmlFor="edition-discount" className="mt-5 block text-sm">{zh ? "Agent ID 持有折扣" : "Agent ID holding discount"}</label>
      <select id="edition-discount" value={rate} onChange={event => setRate(Number(event.target.value))} className="gx-field mt-3">
        <option value={10000}>{zh ? "原价 / 无有效证明" : "Full price / no eligible proof"}</option>
        <option value={9000}>{zh ? "满 10 天 · 九折" : "10 days · 10% off"}</option>
        <option value={8500}>{zh ? "满 20 天 · 八五折" : "20 days · 15% off"}</option>
        <option value={8000}>{zh ? "满 30 天 · 八折" : "30 days · 20% off"}</option>
      </select>
    </div>
    <div className="flex flex-col justify-center">
      <p className="gx-kicker">ANTB / {zh ? "预计铸造费用（演示）" : "MINT TOTAL · DEMO"}</p>
      <p className="mt-5 break-words text-4xl font-semibold text-primary">{formatEther(total)} <span className="text-base">ANTB</span></p>
      <p className="mt-5 text-sm leading-7 text-muted-foreground">{zh ? "预计铸造费用按购买数量和所选折扣计算，不含网络手续费与卡牌揭晓服务费。享受折扣需当前持有 Agent ID，并通过历史持有验证；实际费用以交易确认时为准。" : "Estimated mint costs follow the batch size and selected discount, excluding network and card-reveal fees. Discounts require a current Agent ID and verified holding history. Actual costs are determined at transaction confirmation."}</p>
      <Button variant="outline" className="mt-6 self-start" disabled>{zh ? "铸造待上线" : "Minting not open"}</Button>
    </div>
  </section>;
}

export function EditionInner({ language, view }: { language: Language; view: "market" | "vault" | "commands" | "ladder" | "duel" | "minting" }) {
  const zh = language === "zh";
  const ids = view === "minting" ? [2, 1] : view === "vault" ? [6, 7] : view === "ladder" ? [8] : view === "duel" ? [10] : view === "commands" ? [0, 1, 2] : [0, 4, 5];
  return <>
    <EditionStatus language={language} />
    <EditionDemo language={language} view={view} />
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