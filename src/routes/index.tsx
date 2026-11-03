import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useRef, useState } from "react";
import { Shuffle, Lock, ArrowDownRight, ArrowUpRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Slider } from "@/components/ui/slider";
import { FagentLogo } from "@/components/agent-cards/FagentLogo";
import { CardNavigation } from "@/components/agent-cards/CardNavigation";
import { LanguageSwitch } from "@/components/agent-cards/LanguageSwitch";
import { GenerativeCard } from "@/components/agent-cards/GenerativeCard";
import { HoloCard } from "@/components/agent-cards/HoloCard";
import { POOL_EDITION as P, POOL_MOCK as M, poolStatus, mintQuote, vested, isPoolDeployed } from "@/lib/fagent/pool-edition";

export const Route = createFileRoute("/")({
  head: () => ({ meta: [
    { title: "7AGENT Genesis — 开池版卡牌" },
    { name: "description", content: "7AGENT 开池版：20,000 张预售、开池买币、5 天线性释放、地板基金自动收卡。每张卡都是独一无二的代码艺术。" },
    { property: "og:title", content: "7AGENT Genesis — 开池版卡牌" },
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
  { k: "03", title: "释放", body: `预售卡每张 ${fmt(P.cardGrant)} 枚，5 天线性释放，每天 1,688 枚。币跟地址走，不跟卡走。` },
  { k: "04", title: "开池后铸造", body: `每张 ${P.openPrice} BNB，不涨价。25% 给运营，75% 当场买币：30% 进黑洞，70% 记在你名下 5 天释放。` },
  { k: "05", title: "地板基金", body: `交易税的一部分进入地板基金，每 30 分钟从最低挂单收卡并销毁，全价付给卖家。比例见规则。` },
];

function useReveal() {
  useEffect(() => {
    const els = document.querySelectorAll<HTMLElement>("[data-reveal]");
    const io = new IntersectionObserver(es => es.forEach(e => {
      if (e.isIntersecting) { e.target.classList.add("gx-in"); io.unobserve(e.target); }
    }), { threshold: 0.08 });
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
  const [active, setActive] = useState(0);
  const progress = useRef<HTMLDivElement>(null);
  useEffect(() => {
    let frame = 0;
    const update = () => {
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(() => {
        const height = document.documentElement.scrollHeight - window.innerHeight;
        if (progress.current) progress.current.style.transform = `scaleX(${height > 0 ? window.scrollY / height : 0})`;
      });
    };
    window.addEventListener("scroll", update, { passive: true });
    update();
    return () => { window.removeEventListener("scroll", update); cancelAnimationFrame(frame); };
  }, []);
  const q = mintQuote(count, phase);
  const grant = phase === "presale" ? q.tokens ?? 0 : P.cardGrant * count;
  const kind = id <= P.presaleCards ? "presale" : "open";
  const st = poolStatus(M.minted);
  const selectedPhase = phases[active] ?? phases[0];
  if (!selectedPhase) return null;

  return (
    <main className="min-h-screen bg-background text-foreground overflow-x-hidden">
      <header className="sticky top-0 z-30 border-b border-border/60 bg-background/80 backdrop-blur">
        <div className="gx-container flex items-center justify-between gap-5 py-3">
          <FagentLogo className="text-xl" />
          <CardNavigation compact className="hidden gap-7 md:flex" />
          <LanguageSwitch />
        </div>
        <CardNavigation compact className="gx-container flex justify-between gap-4 overflow-x-auto md:hidden" />
        <div ref={progress} className="gx-reading-progress" aria-hidden="true" />
      </header>

      {/* Hero */}
      <section className="gx-container gx-intro">
        <div className="gx-title-row">
          <div data-reveal className="gx-rise min-w-0">
            <p className="gx-kicker">GENESIS / 001</p>
            <h1 className="gx-heading mt-3"><span className="gx-heading-seven">7</span>AGENT<span className="text-primary">.</span></h1>
          </div>
          <div data-reveal className="gx-rise gx-manifesto">
            <p className="text-2xl font-semibold leading-relaxed">一张卡，接住 AI 时代的<br className="hidden md:block" />每一笔税收</p>
            <p className="mt-3 text-sm text-muted-foreground">777,777 张独一无二 · 币安 Agent 钱包</p>
          </div>
        </div>
        <div className="gx-exhibit">
          <div data-reveal className="gx-rise gx-art-stage hc-stage">
            <HoloCard id={id} kind={kind} />
          </div>
          <aside data-reveal className="gx-rise gx-exhibit-rail">
            <div>
              <p className="gx-kicker">THE COLLECTION</p>
              <p className="mt-4 text-xl font-medium">编号即身份<br />每张，只有一张</p>
              <p className="mt-3 text-sm text-muted-foreground">每张卡由编号生成，世上只有一张。</p>
            </div>
            <div className="gx-art-controls">
              <label className="mb-4 flex justify-between font-mono text-xs text-muted-foreground"><span>卡号</span><span>{fmt(id)}</span></label>
              <Slider min={1} max={P.totalCards} step={1} value={[id]} onValueChange={v => setId(v[0] ?? 1)} aria-label="卡号" />
              <Button size="lg" variant="outline" className="mt-5 w-full justify-between" onClick={() => setId(1 + Math.floor(Math.random() * P.totalCards))}>随机一张<Shuffle className="size-4" /></Button>
            </div>
            <Button size="lg" disabled={!isPoolDeployed()} className="gap-2">
              {isPoolDeployed() ? "去铸造" : <><Lock className="size-4" />合约未上线</>}
            </Button>
          </aside>
        </div>
        <div className="gx-exhibit-caption"><span>777,777 / GENESIS EDITION</span><ArrowDownRight className="size-4 text-primary" aria-hidden="true" /></div>
      </section>

      <section className="border-y border-border/60">
        <div className="gx-container py-8">
          <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
            <p className="flex items-center gap-2 font-mono text-xs text-primary"><span className="gx-live-dot" />LIVE / {st.phase === "presale" ? "预售进行中" : "开池后铸造"}</p>
            <span className="rounded border border-border px-2 py-1 font-mono text-[11px] text-muted-foreground">演示数据 · 合约部署后自动换成链上实时数据</span>
          </div>
          <dl className="gx-metrics">
            {[
              { label: "已铸造", value: fmt(M.minted), note: `总量 ${fmt(P.totalCards)} 张` },
              { label: "已募集", value: `${fmt(M.presaleRaisedBnb, 2)} BNB`, note: `预售目标 49 BNB` },
              { label: "铸造地址", value: fmt(M.minters), note: `每地址最多 ${P.maxPerAddress} 张` },
              { label: "预售剩余", value: fmt(st.presaleLeft), note: `卖满 ${fmt(P.presaleCards)} 张即可开池` },
            ].map(item => <div key={item.label}><dt className="text-xs text-muted-foreground">{item.label}</dt><dd className="mt-2 font-display text-4xl">{item.value}</dd><dd className="mt-2 text-xs text-muted-foreground">{item.note}</dd></div>)}
          </dl>
          <div className="mt-6">
            <div className="mb-2 flex justify-between font-mono text-xs text-muted-foreground"><span>预售进度</span><span className="text-primary">{st.presalePct.toFixed(1)}%</span></div>
            <div className="h-2 overflow-hidden rounded-full bg-muted"><div className="gx-live-bar h-full rounded-full bg-primary" style={{ width: `${st.presalePct}%` }} /></div>
          </div>
        </div>
      </section>

      {/* Lifecycle */}
      <section className="gx-container gx-chapter">
        <div data-reveal className="gx-rise gx-chapter-heading"><p className="gx-kicker">01 / LIFECYCLE</p><h2>一张卡的一生</h2><span className="gx-chapter-note">从铸造，到价值流转</span></div>
        <div className="mt-8">
          <ol className="gx-phase-nav">
            {phases.map((p, i) => <li key={p.k}>
              <Button variant="ghost" aria-pressed={active === i} onClick={() => setActive(i)} className={`gx-phase-button ${active === i ? "gx-phase-active" : ""}`}>
                <span className="font-mono text-xs">{p.k}</span><span className="whitespace-nowrap text-base font-semibold">{p.title}</span>
              </Button>
            </li>)}
          </ol>
          <div key={active} className="gx-swap gx-phase-detail">
            <span className="gx-phase-number" aria-hidden="true">{selectedPhase.k}</span>
            <div>
              <p className="font-mono text-xs text-primary">{selectedPhase.k} / 05</p>
              <h3 className="mt-4 text-2xl font-bold">{selectedPhase.title}</h3>
              <p className="mt-4 max-w-lg text-base text-muted-foreground">{selectedPhase.body}</p>
            </div>
            <div className="gx-phase-art">
              <GenerativeCard id={active * 131071 + 19} kind={active === 0 ? "presale" : "open"} className="h-full w-full" />
            </div>
          </div>
        </div>
      </section>

      {/* Calculators */}
      <section className="gx-container gx-workspace">
        <div data-reveal className="gx-rise gx-chapter-heading lg:col-span-2"><p className="gx-kicker">02 / CALCULATOR</p><h2>先算清楚，再铸造</h2><span className="gx-chapter-note">铸造 · 释放</span></div>
        <div data-reveal className="gx-rise gx-mint-tool">
          <p className="gx-kicker">A / MINT</p>
          <h3 className="mt-2 text-3xl font-bold">铸造试算</h3>
          <div className="mt-5 inline-flex rounded-md border border-border p-1">
            {(["presale", "open"] as const).map(p => <Button key={p} size="sm" variant={phase === p ? "default" : "ghost"} aria-pressed={phase === p} onClick={() => setPhase(p)}>{p === "presale" ? "预售" : "开池后"}</Button>)}
          </div>
          <div className="mt-6 flex items-end justify-between"><span className="text-muted-foreground">张数</span><span className="font-display text-5xl">{q.count}</span></div>
          <Slider className="mt-3" min={1} max={P.maxPerAddress} step={1} value={[count]} onValueChange={v => setCount(v[0] ?? 0)} aria-label="张数" />
          <div className="mt-6 grid h-12 grid-cols-10 gap-1.5" aria-hidden="true">{Array.from({ length: P.maxPerAddress }, (_, i) => <div key={i} className={`gx-mint-mark ${i < q.count ? "gx-mint-mark-active" : ""}`} />)}</div>
          <dl className="mt-6 grid grid-cols-2 gap-4 font-mono text-sm">
            <div><dt className="text-muted-foreground">支付</dt><dd className="text-2xl text-foreground">{q.bnb} BNB</dd></div>
            {phase === "presale"
              ? <div><dt className="text-muted-foreground">获得代币</dt><dd className="text-2xl text-primary">{fmt(q.tokens ?? 0)}</dd></div>
              : <><div><dt className="text-muted-foreground">运营 25%</dt><dd className="text-2xl">{q.ops}</dd></div>
                 <div className="col-span-2"><dt className="text-muted-foreground">进池买币 75%</dt><dd className="text-2xl text-primary">{q.swap} BNB → 70% 归你 · 30% 销毁</dd></div></>}
          </dl>
          {phase === "open" && <p className="mt-3 text-xs text-muted-foreground">到手代币按当时池子价格决定，网站上线后实时报价。</p>}
        </div>

        <div data-reveal className="gx-rise gx-vesting-tool">
          <p className="gx-kicker">B / VESTING</p>
          <h3 className="mt-2 text-3xl font-bold">5 天线性释放</h3>
          <p className="mt-2 text-muted-foreground">以 {q.count} 张预售卡为例，共 {fmt(grant)} 枚。</p>
          <div className="mt-8 flex h-40 items-end gap-1">
            {Array.from({ length: 40 }, (_, i) => { const on = i / 40 < day / P.vestDays; return <div key={i} className={`flex-1 rounded-t-sm transition-all duration-500 ${on ? "bg-primary" : "bg-muted"}`} style={{ height: `${20 + (i / 40) * 80}%`, transitionDelay: `${i * 8}ms` }} />; })}
          </div>
          <div className="mt-6 flex items-end justify-between"><span className="text-muted-foreground">第 {day.toFixed(1)} 天</span><span className="font-display text-5xl text-primary">{fmt(vested(grant, day))}</span></div>
          <Slider className="mt-3" min={0} max={P.vestDays} step={0.1} value={[day]} onValueChange={v => setDay(v[0] ?? 0)} aria-label="天数" />
        </div>

      </section>

      <footer className="border-t border-border/60 px-6 py-8 text-center font-mono text-xs text-muted-foreground">
        开池版合约尚未部署 · 铸造数据为演示数据，不代表链上实时数据
      </footer>
    </main>
  );
}
