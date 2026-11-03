import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { Shuffle, Lock } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Slider } from "@/components/ui/slider";
import { FagentLogo } from "@/components/agent-cards/FagentLogo";
import { CardNavigation } from "@/components/agent-cards/CardNavigation";
import { LanguageSwitch } from "@/components/agent-cards/LanguageSwitch";
import { GenerativeCard } from "@/components/agent-cards/GenerativeCard";
import { POOL_EDITION as P, mintQuote, vested, taxFlow, isPoolDeployed } from "@/lib/fagent/pool-edition";

export const Route = createFileRoute("/")({
  head: () => ({ meta: [
    { title: "FAGENT Genesis — 开池版卡牌" },
    { name: "description", content: "FAGENT 开池版：20,000 张预售、开池买币、5 天线性释放、地板基金自动收卡。每张卡都是独一无二的代码艺术。" },
    { property: "og:title", content: "FAGENT Genesis — 开池版卡牌" },
    { property: "og:description", content: "777,777 张卡，每张一幅由编号生成的代码艺术。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: GenesisPage,
});

const fmt = (n: number, d = 0) => n.toLocaleString("en-US", { maximumFractionDigits: d });

const phases = [
  { k: "01", title: "预售", body: `前 ${fmt(P.presaleCards)} 张，每张 ${P.presalePrice} BNB，共 49 BNB。窗口 7 天。没卖满可烧卡全额退款。` },
  { k: "02", title: "开池", body: `卖满后 7 天内任何人可开池：${P.poolBnb} BNB + ${fmt(P.poolTokens)} 枚进池，LP 销毁。超时则永久关闭，只能退款。` },
  { k: "03", title: "释放", body: `预售卡、团队卡各 ${fmt(P.cardGrant)} 枚，5 天线性释放，每天 1,688 枚。币跟地址走，不跟卡走。` },
  { k: "04", title: "开池后铸造", body: `每张 ${P.openPrice} BNB，不涨价。25% 给运营，75% 当场买币：30% 进黑洞，70% 记在你名下 5 天释放。` },
  { k: "05", title: "地板基金", body: `交易税 2%：50% 分红、30% 地板基金、20% 运营。每 30 分钟从最低挂单收卡并销毁，全价付给卖家。` },
];

function useReveal() {
  useEffect(() => {
    const els = document.querySelectorAll<HTMLElement>("[data-reveal]");
    const io = new IntersectionObserver(es => es.forEach(e => e.isIntersecting && e.target.classList.add("gx-in")), { threshold: 0.15 });
    els.forEach(el => io.observe(el));
    return () => io.disconnect();
  }, []);
}

function GenesisPage() {
  useReveal();
  const [id, setId] = useState(7777);
  const [phase, setPhase] = useState<"presale" | "open">("presale");
  const [count, setCount] = useState(3);
  const [day, setDay] = useState(2);
  const [volume, setVolume] = useState(100);
  const [active, setActive] = useState(0);
  const q = mintQuote(count, phase);
  const grant = phase === "presale" ? q.tokens ?? 0 : P.cardGrant * count;
  const flow = taxFlow(volume);
  const kind = id <= P.presaleCards ? "presale" : id % 20 === 0 ? "team" : "open";
  const selectedPhase = phases[active] ?? phases[0];

  return (
    <main className="min-h-screen bg-background text-foreground overflow-x-hidden">
      <header className="sticky top-0 z-30 border-b border-border/60 bg-background/80 backdrop-blur">
        <div className="gx-container flex items-center justify-between gap-5 py-3">
          <FagentLogo />
          <CardNavigation compact className="hidden gap-7 md:flex" />
          <LanguageSwitch />
        </div>
        <CardNavigation compact className="gx-container flex justify-between gap-4 overflow-x-auto md:hidden" />
      </header>

      {/* Hero */}
      <section className="gx-container gx-intro">
        <div data-reveal className="gx-rise min-w-0">
          <p className="font-mono text-xs text-primary">GENESIS / 001</p>
          <h1 className="gx-heading mt-4">FAGENT<span className="gx-heading-sub text-primary">777,777 张独一无二</span></h1>
          <p className="mt-6 text-xl font-medium">一张卡，接住 AI 时代的每一笔税收</p>
          <p className="mt-3 max-w-sm text-sm text-muted-foreground">每张卡由编号生成，世上只有一张。</p>
          <div className="mt-7 flex flex-wrap items-center gap-3">
            <Button size="lg" disabled={!isPoolDeployed()} className="gap-2">
              {isPoolDeployed() ? "去铸造" : <><Lock className="size-4" />合约未上线</>}
            </Button>
            <Button size="lg" variant="outline" className="gap-2" onClick={() => setId(1 + Math.floor(Math.random() * P.totalCards))}>
              <Shuffle className="size-4" />随机一张
            </Button>
          </div>
        </div>
        <div data-reveal className="gx-rise gx-collectible">
          <div className="gx-card relative aspect-[3/4] overflow-hidden rounded-lg border border-primary/40">
            <GenerativeCard id={id} kind={kind} className="absolute inset-0 h-full w-full cursor-crosshair" />
            <div className="pointer-events-none absolute inset-x-0 top-0 flex justify-between p-5 font-mono text-xs">
              <span className="text-primary">FAGENT</span>
              <span className="text-muted-foreground">{kind === "presale" ? "PRESALE" : kind === "team" ? "TEAM" : "OPEN"}</span>
            </div>
            <div className="pointer-events-none absolute inset-x-0 bottom-0 p-5">
              <p className="font-display text-5xl leading-none">#{String(id).padStart(6, "0")}</p>
            </div>
          </div>
          <div className="mt-5">
            <label className="mb-2 flex justify-between font-mono text-xs text-muted-foreground"><span>卡号</span><span>{fmt(id)} / {fmt(P.totalCards)}</span></label>
            <Slider min={1} max={P.totalCards} step={1} value={[id]} onValueChange={v => setId(v[0] ?? 0)} aria-label="卡号" />
          </div>
        </div>
      </section>

      <section className="border-y border-border/60">
        <dl className="gx-container gx-metrics">
          {[
            { label: "公开铸造", value: fmt(P.paidCards), note: `总量 ${fmt(P.totalCards)} 张` },
            { label: "团队卡牌", value: fmt(P.teamCards), note: "每 19 张解锁 1 张团队卡" },
            { label: "每地址上限", value: "10 张", note: `代币总量 ${fmt(P.totalTokens)}` },
            { label: "初始池子", value: `${P.poolBnb} BNB`, note: "LP 销毁" },
          ].map(item => <div key={item.label}><dt className="text-xs text-muted-foreground">{item.label}</dt><dd className="mt-2 font-display text-4xl">{item.value}</dd><dd className="mt-2 text-xs text-muted-foreground">{item.note}</dd></div>)}
        </dl>
      </section>

      {/* Lifecycle */}
      <section className="gx-container py-14 md:py-16">
        <h2 data-reveal className="gx-rise font-display text-3xl md:text-4xl">一张卡的一生</h2>
        <div className="mt-8 grid gap-8 lg:grid-cols-[210px_1fr]">
          <ol className="flex gap-2 overflow-x-auto lg:flex-col">
            {phases.map((p, i) => <li key={p.k}>
              <Button variant="ghost" aria-pressed={active === i} onClick={() => setActive(i)} className={`group flex h-12 w-full justify-start gap-4 rounded-none border-l-2 px-4 text-left ${active === i ? "border-primary text-foreground" : "border-border text-muted-foreground hover:text-foreground"}`}>
                <span className="font-mono text-xs">{p.k}</span><span className="whitespace-nowrap text-base font-semibold">{p.title}</span>
              </Button>
            </li>)}
          </ol>
          <div key={active} className="gx-swap grid min-h-60 gap-6 border-t border-border pt-6 md:grid-cols-[1fr_180px] md:items-center lg:border-l lg:border-t-0 lg:pl-8 lg:pt-0">
            <div>
              <p className="font-mono text-xs text-primary">{selectedPhase.k} / 05</p>
              <h3 className="mt-4 text-2xl font-bold">{selectedPhase.title}</h3>
              <p className="mt-4 max-w-lg text-base text-muted-foreground">{selectedPhase.body}</p>
            </div>
            <div className="hidden aspect-square overflow-hidden rounded-lg border border-primary/30 md:block">
              <GenerativeCard id={active * 131071 + 19} kind={active === 0 ? "presale" : "open"} className="h-full w-full" />
            </div>
          </div>
        </div>
      </section>

      {/* Calculators */}
      <section className="gx-container grid items-stretch gap-5 pb-16 lg:grid-cols-2">
        <div data-reveal className="gx-rise min-w-0 rounded-lg border border-border bg-card p-5 md:p-7">
          <p className="font-mono text-xs tracking-[0.3em] text-primary">MINT</p>
          <h3 className="mt-2 text-3xl font-bold">铸造试算</h3>
          <div className="mt-5 inline-flex rounded-md border border-border p-1">
            {(["presale", "open"] as const).map(p => <Button key={p} size="sm" variant={phase === p ? "default" : "ghost"} aria-pressed={phase === p} onClick={() => setPhase(p)}>{p === "presale" ? "预售" : "开池后"}</Button>)}
          </div>
          <div className="mt-6 flex items-end justify-between"><span className="text-muted-foreground">张数</span><span className="font-display text-5xl">{q.count}</span></div>
          <Slider className="mt-3" min={1} max={P.maxPerAddress} step={1} value={[count]} onValueChange={v => setCount(v[0] ?? 0)} aria-label="张数" />
          <div className="mt-6 flex gap-2">{Array.from({ length: q.count }, (_, i) => <div key={i} className="gx-pop h-14 flex-1 overflow-hidden rounded-md border border-primary/30" style={{ animationDelay: `${i * 40}ms` }}><GenerativeCard id={id + i} interactive={false} className="h-full w-full" /></div>)}</div>
          <dl className="mt-6 grid grid-cols-2 gap-4 font-mono text-sm">
            <div><dt className="text-muted-foreground">支付</dt><dd className="text-2xl text-foreground">{q.bnb} BNB</dd></div>
            {phase === "presale"
              ? <div><dt className="text-muted-foreground">获得代币</dt><dd className="text-2xl text-primary">{fmt(q.tokens ?? 0)}</dd></div>
              : <><div><dt className="text-muted-foreground">运营 25%</dt><dd className="text-2xl">{q.ops}</dd></div>
                 <div className="col-span-2"><dt className="text-muted-foreground">进池买币 75%</dt><dd className="text-2xl text-primary">{q.swap} BNB → 70% 归你 · 30% 销毁</dd></div></>}
          </dl>
          {phase === "open" && <p className="mt-3 text-xs text-muted-foreground">到手代币按当时池子价格决定，网站上线后实时报价。</p>}
        </div>

        <div data-reveal className="gx-rise min-w-0 rounded-lg border border-border bg-card p-5 md:p-7">
          <p className="font-mono text-xs tracking-[0.3em] text-primary">VESTING</p>
          <h3 className="mt-2 text-3xl font-bold">5 天线性释放</h3>
          <p className="mt-2 text-muted-foreground">以 {q.count} 张预售/团队卡为例，共 {fmt(grant)} 枚。</p>
          <div className="mt-8 flex h-40 items-end gap-1">
            {Array.from({ length: 40 }, (_, i) => { const on = i / 40 < day / P.vestDays; return <div key={i} className={`flex-1 rounded-t-sm transition-all duration-500 ${on ? "bg-primary" : "bg-muted"}`} style={{ height: `${20 + (i / 40) * 80}%`, transitionDelay: `${i * 8}ms` }} />; })}
          </div>
          <div className="mt-6 flex items-end justify-between"><span className="text-muted-foreground">第 {day.toFixed(1)} 天</span><span className="font-display text-5xl text-primary">{fmt(vested(grant, day))}</span></div>
          <Slider className="mt-3" min={0} max={P.vestDays} step={0.1} value={[day]} onValueChange={v => setDay(v[0] ?? 0)} aria-label="天数" />
        </div>

        <div data-reveal className="gx-rise min-w-0 border-t border-border pt-10 lg:col-span-2">
          <div className="flex flex-wrap items-end justify-between gap-4">
            <div><p className="font-mono text-xs tracking-[0.3em] text-primary">TAX FLOW</p><h3 className="mt-2 text-3xl font-bold">交易税去哪了</h3></div>
            <div className="text-right"><p className="text-muted-foreground">假设交易量</p><p className="font-display text-5xl">{fmt(volume)} BNB</p></div>
          </div>
          <Slider className="mt-4" min={10} max={5000} step={10} value={[volume]} onValueChange={v => setVolume(v[0] ?? 0)} aria-label="交易量" />
          <div className="mt-6 grid min-h-20 grid-cols-[5fr_3fr_2fr] overflow-hidden rounded-md">
            <div className="gx-flow flex flex-col items-center justify-center gap-1 bg-primary text-primary-foreground"><span>分红</span><strong>{flow.dividend.toFixed(2)}</strong></div>
            <div className="gx-flow flex flex-col items-center justify-center gap-1 bg-primary/60 text-primary-foreground"><span>地板</span><strong>{flow.floor.toFixed(2)}</strong></div>
            <div className="gx-flow flex flex-col items-center justify-center gap-1 bg-muted text-foreground"><span>运营</span><strong>{flow.ops.toFixed(2)}</strong></div>
          </div>
          <p className="mt-4 text-sm text-muted-foreground">2% 税 = {flow.tax.toFixed(2)} BNB（Flap 先抽协议费）。分红所有卡平分；地板基金先补 0.02 BNB 触发费，再从最低挂单收卡销毁。</p>
        </div>
      </section>

      <footer className="border-t border-border/60 px-6 py-8 text-center font-mono text-xs text-muted-foreground">
        开池版合约尚未部署 · 以上为合约规则演示，不代表实时数据
      </footer>
    </main>
  );
}
