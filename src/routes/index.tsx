import { PoolStats } from "@/components/agent-cards/PoolStats";
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
import { useLanguage } from "@/components/agent-cards/LanguageProvider";
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
    const showAll = () => els.forEach(el => el.classList.add("gx-in"));
    if (typeof IntersectionObserver === "undefined") { showAll(); return; }
    const io = new IntersectionObserver(es => es.forEach(e => {
      if (e.isIntersecting) { e.target.classList.add("gx-in"); io.unobserve(e.target); }
    }), { threshold: 0, rootMargin: "0px 0px 10% 0px" });
    els.forEach(el => io.observe(el));
    // Safety net: never leave content hidden if the observer doesn't fire (e.g. in iframes).
    const fallback = window.setTimeout(showAll, 1500);
    return () => { io.disconnect(); window.clearTimeout(fallback); };
  }, []);
}

/** Eased count-up that starts when the element scrolls into view. */
function CountUp({ value, decimals = 0, suffix = "" }: { value: number; decimals?: number; suffix?: string }) {
  const ref = useRef<HTMLSpanElement>(null);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduce) { el.textContent = fmt(value, decimals) + suffix; return; }
    let raf = 0;
    const io = new IntersectionObserver(entries => {
      if (!entries.some(e => e.isIntersecting)) return;
      io.disconnect();
      const t0 = performance.now(), dur = 1400;
      const tick = (now: number) => {
        const p = Math.min(1, (now - t0) / dur);
        const eased = 1 - Math.pow(1 - p, 4);
        el.textContent = fmt(value * eased, decimals) + suffix;
        if (p < 1) raf = requestAnimationFrame(tick);
      };
      raf = requestAnimationFrame(tick);
    }, { threshold: 0.4 });
    io.observe(el);
    return () => { io.disconnect(); cancelAnimationFrame(raf); };
  }, [value, decimals, suffix]);
  return <span ref={ref}>0{suffix}</span>;
}

/** Magnetic hover: the element leans a few px toward the pointer. */
function useMagnet<T extends HTMLElement>(strength = 6) {
  const ref = useRef<T>(null);
  useEffect(() => {
    const el = ref.current;
    if (!el || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const move = (e: PointerEvent) => {
      const r = el.getBoundingClientRect();
      const x = (e.clientX - r.left) / r.width - 0.5;
      const y = (e.clientY - r.top) / r.height - 0.5;
      el.style.transform = `translate(${x * strength}px, ${y * strength}px)`;
    };
    const leave = () => { el.style.transform = ""; };
    el.addEventListener("pointermove", move);
    el.addEventListener("pointerleave", leave);
    return () => { el.removeEventListener("pointermove", move); el.removeEventListener("pointerleave", leave); };
  }, [strength]);
  return ref;
}

function GenesisPage() {
  useReveal();
  const { t } = useLanguage();
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
  const magnet = useMagnet<HTMLButtonElement>(7);
  const hero = useRef<HTMLElement>(null);
  const stage = useRef<HTMLDivElement>(null);
  // Ambient glow follows the pointer; the card stage drifts slightly on scroll.
  useEffect(() => {
    const heroEl = hero.current;
    if (!heroEl || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    let raf = 0;
    const onMove = (e: PointerEvent) => {
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(() => {
        const r = heroEl.getBoundingClientRect();
        heroEl.style.setProperty("--ax", `${((e.clientX - r.left) / r.width) * 100}%`);
        heroEl.style.setProperty("--ay", `${((e.clientY - r.top) / r.height) * 100}%`);
      });
    };
    const onScroll = () => {
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(() => {
        if (stage.current) stage.current.style.setProperty("--par", `${Math.min(60, window.scrollY * 0.08)}px`);
      });
    };
    heroEl.addEventListener("pointermove", onMove);
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => { heroEl.removeEventListener("pointermove", onMove); window.removeEventListener("scroll", onScroll); cancelAnimationFrame(raf); };
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
      <section ref={hero} className="gx-container gx-intro">
        <div className="gx-ambient" aria-hidden="true" />
        <div className="gx-title-row">
          <div data-reveal className="gx-rise min-w-0">
            <p className="gx-kicker">GENESIS / 001</p>
            <h1 className="gx-heading mt-3" aria-label="7AGENT.">
              {"7AGENT.".split("").map((ch, i) => (
                <span key={i} aria-hidden="true" className={`gx-char ${ch === "7" ? "gx-heading-seven" : ch === "." ? "text-primary" : ""}`} style={{ animationDelay: `${0.15 + i * 0.07}s` }}>{ch}</span>
              ))}
            </h1>
          </div>
          <div data-reveal className="gx-rise gx-manifesto">
            <p className="text-2xl font-semibold leading-relaxed">{t("把 AI 时代的流水，")}<br className="hidden md:block" />{t("折进一张卡")}</p>
            <p className="mt-3 text-sm text-muted-foreground">{t("777,777 张独一无二 · 币安 Agent 钱包")}</p>
          </div>
        </div>
        <div className="gx-exhibit">
          <div data-reveal className="gx-rise gx-art-stage hc-stage">
            <div ref={stage} className="gx-parallax h-full">
              <HoloCard id={id} kind={kind} />
            </div>
          </div>
          <aside data-reveal className="gx-rise gx-exhibit-rail">
            <div>
              <p className="gx-kicker">THE COLLECTION</p>
              <p className="mt-4 text-xl font-medium">{t("编号即身份")}<br />{t("每张，只有一张")}</p>
              <p className="mt-3 text-sm text-muted-foreground">{t("每张卡由编号生成，世上只有一张。")}</p>
            </div>
            <div className="gx-art-controls">
              <label className="mb-4 flex justify-between font-mono text-xs text-muted-foreground"><span>{t("卡号")}</span><span>{fmt(id)}</span></label>
              <Slider min={1} max={P.totalCards} step={1} value={[id]} onValueChange={v => setId(v[0] ?? 1)} aria-label={t("卡号")} />
              <Button size="lg" variant="outline" className="mt-5 w-full justify-between" onClick={() => setId(1 + Math.floor(Math.random() * P.totalCards))}>{t("随机一张")}<Shuffle className="size-4" /></Button>
            </div>
            <Button ref={magnet} size="lg" disabled={!isPoolDeployed()} className="gx-magnet gap-2">
              {isPoolDeployed() ? t("去铸造") : <><Lock className="size-4" />{t("合约未上线")}</>}
            </Button>
          </aside>
        </div>
        <div className="gx-exhibit-caption"><span>777,777 / GENESIS EDITION</span><ArrowDownRight className="size-4 text-primary" aria-hidden="true" /></div>
      </section>

      <section className="border-y border-border/60">
        <div className="gx-container py-8">
          <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
            <p className="flex items-center gap-2 font-mono text-xs text-primary"><span className="gx-live-dot" />LIVE / {st.phase === "presale" ? t("预售进行中") : t("开池后铸造")}</p>
            <span className="rounded border border-border px-2 py-1 font-mono text-[11px] text-muted-foreground">{t("演示数据 · 合约部署后自动换成链上实时数据")}</span>
          </div>
          <dl className="gx-metrics">
            {[
              { label: "已铸造", value: M.minted, d: 0, suffix: "", note: t("总量 {0} 张", fmt(P.totalCards)) },
              { label: "已募集", value: M.presaleRaisedBnb, d: 2, suffix: " BNB", note: t("预售目标 49 BNB") },
              { label: "铸造地址", value: M.minters, d: 0, suffix: "", note: t("每地址最多 {0} 张", P.maxPerAddress) },
              { label: "预售剩余", value: st.presaleLeft, d: 0, suffix: "", note: t("卖满 {0} 张即可开池", fmt(P.presaleCards)) },
            ].map(item => <div key={item.label}><dt className="text-xs text-muted-foreground">{t(item.label)}</dt><dd className="mt-2 font-display text-4xl"><CountUp value={item.value} decimals={item.d} suffix={item.suffix} /></dd><dd className="mt-2 text-xs text-muted-foreground">{item.note}</dd></div>)}
          </dl>
          <div className="mt-6">
            <div className="mb-2 flex justify-between font-mono text-xs text-muted-foreground"><span>{t("预售进度")}</span><span className="text-primary"><CountUp value={st.presalePct} decimals={1} suffix="%" /></span></div>
            <div className="h-2 overflow-hidden rounded-full bg-muted"><div className="gx-live-bar h-full rounded-full bg-primary" style={{ width: `${st.presalePct}%` }} /></div>
          </div>
          <div className="mt-10"><PoolStats /></div>
        </div>
      </section>

      {/* Lifecycle */}
      <section className="gx-container gx-chapter">
        <div data-reveal className="gx-rise gx-chapter-heading"><p className="gx-kicker">01 / LIFECYCLE</p><h2>{t("一张卡的一生")}</h2><span className="gx-chapter-note">{t("从铸造，到价值流转")}</span></div>
        <div className="mt-8">
          <ol className="gx-phase-nav">
            {phases.map((p, i) => <li key={p.k}>
              <Button variant="ghost" aria-pressed={active === i} onClick={() => setActive(i)} className={`gx-phase-button ${active === i ? "gx-phase-active" : ""}`}>
                <span className="font-mono text-xs">{p.k}</span><span className="whitespace-nowrap text-base font-semibold">{t(p.title)}</span>
              </Button>
            </li>)}
          </ol>
          <div key={active} className="gx-swap gx-phase-detail">
            <span className="gx-phase-number" aria-hidden="true">{selectedPhase.k}</span>
            <div>
              <p className="font-mono text-xs text-primary">{selectedPhase.k} / 05</p>
              <h3 className="mt-4 text-2xl font-bold">{t(selectedPhase.title)}</h3>
              <p className="mt-4 max-w-lg text-base text-muted-foreground">{t(selectedPhase.body)}</p>
            </div>
            <div className="gx-phase-art">
              <GenerativeCard id={active * 131071 + 19} kind={active === 0 ? "presale" : "open"} className="h-full w-full" />
            </div>
          </div>
        </div>
      </section>

      {/* Calculators */}
      <section className="gx-container gx-workspace">
        <div data-reveal className="gx-rise gx-chapter-heading lg:col-span-2"><p className="gx-kicker">02 / CALCULATOR</p><h2>{t("先算清楚，再铸造")}</h2><span className="gx-chapter-note">{t("铸造 · 释放")}</span></div>
        <div data-reveal className="gx-rise gx-mint-tool">
          <p className="gx-kicker">A / MINT</p>
          <h3 className="mt-2 text-3xl font-bold">{t("铸造试算")}</h3>
          <div className="mt-5 inline-flex rounded-md border border-border p-1">
            {(["presale", "open"] as const).map(p => <Button key={p} size="sm" variant={phase === p ? "default" : "ghost"} aria-pressed={phase === p} onClick={() => setPhase(p)}>{p === "presale" ? t("预售") : t("开池后")}</Button>)}
          </div>
          <div className="mt-6 flex items-end justify-between"><span className="text-muted-foreground">{t("张数")}</span><span className="font-display text-5xl">{q.count}</span></div>
          <Slider className="mt-3" min={1} max={P.maxPerAddress} step={1} value={[count]} onValueChange={v => setCount(v[0] ?? 0)} aria-label={t("张数")} />
          <div className="mt-6 grid h-12 grid-cols-10 gap-1.5" aria-hidden="true">{Array.from({ length: P.maxPerAddress }, (_, i) => <div key={i} className={`gx-mint-mark ${i < q.count ? "gx-mint-mark-active" : ""}`} />)}</div>
          <dl className="mt-6 grid grid-cols-2 gap-4 font-mono text-sm">
            <div><dt className="text-muted-foreground">{t("支付")}</dt><dd className="text-2xl text-foreground">{q.bnb} BNB</dd></div>
            {phase === "presale"
              ? <div><dt className="text-muted-foreground">{t("获得代币")}</dt><dd className="text-2xl text-primary">{fmt(q.tokens ?? 0)}</dd></div>
              : <><div><dt className="text-muted-foreground">{t("运营 25%")}</dt><dd className="text-2xl">{q.ops}</dd></div>
                 <div className="col-span-2"><dt className="text-muted-foreground">{t("进池买币 75%")}</dt><dd className="text-2xl text-primary">{q.swap} BNB → {t("70% 归你 · 30% 销毁")}</dd></div></>}
          </dl>
          {phase === "open" && <p className="mt-3 text-xs text-muted-foreground">{t("到手代币按当时池子价格决定，网站上线后实时报价。")}</p>}
        </div>

        <div data-reveal className="gx-rise gx-vesting-tool">
          <p className="gx-kicker">B / VESTING</p>
          <h3 className="mt-2 text-3xl font-bold">{t("5 天线性释放")}</h3>
          <p className="mt-2 text-muted-foreground">{t("以 {0} 张预售卡为例，共 {1} 枚。", q.count, fmt(grant))}</p>
          <div className="mt-8 flex h-40 items-end gap-1">
            {Array.from({ length: 40 }, (_, i) => { const on = i / 40 < day / P.vestDays; return <div key={i} className={`flex-1 rounded-t-sm transition-all duration-500 ${on ? "bg-primary" : "bg-muted"}`} style={{ height: `${20 + (i / 40) * 80}%`, transitionDelay: `${i * 8}ms` }} />; })}
          </div>
          <div className="mt-6 flex items-end justify-between"><span className="text-muted-foreground">{t("第 {0} 天", day.toFixed(1))}</span><span className="font-display text-5xl text-primary">{fmt(vested(grant, day))}</span></div>
          <Slider className="mt-3" min={0} max={P.vestDays} step={0.1} value={[day]} onValueChange={v => setDay(v[0] ?? 0)} aria-label={t("天数")} />
        </div>

      </section>

      <footer className="border-t border-border/60 px-6 py-8 text-center font-mono text-xs text-muted-foreground">
        {t("开池版合约尚未部署 · 铸造数据为演示数据，不代表链上实时数据")}
      </footer>
    </main>
  );
}
