import { createFileRoute, Link } from "@tanstack/react-router";
import { useState } from "react";
import { ArrowUpRight, Flame, Gift, Droplets } from "lucide-react";
import { Button } from "@/components/ui/button";
import { SiteShell } from "@/components/agent-cards/SiteShell";
import { PoolStats } from "@/components/agent-cards/PoolStats";
import { useLanguage } from "@/components/agent-cards/LanguageProvider";
import { ALLOCATION, POOL_EDITION as P } from "@/lib/fagent/pool-edition";

export const Route = createFileRoute("/tokenomics")({
  head: () => ({ meta: [
    { title: "7AGENT — 代币经济" },
    { name: "description", content: "7AGENT 代币总量 777,777,777 枚的分配，以及分红、销毁、进池的去向。" },
    { property: "og:title", content: "7AGENT — 代币经济" },
    { property: "og:description", content: "总量固定，分配透明：开池流动性、预售发放、阶梯卖单、开池销毁、团队卡。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: TokenomicsPage,
});

const fmt = (n: number) => n.toLocaleString("en-US");
const OPACITY = [1, 0.75, 0.55, 0.35, 0.2];

function Donut({ active, onHover }: { active: number; onHover: (i: number) => void }) {
  const r = 80, c = 2 * Math.PI * r;
  let offset = 0;
  return <svg viewBox="0 0 200 200" className="gx-donut" role="img" aria-label="代币分配">
    {ALLOCATION.map((a, i) => {
      const len = (a.amount / P.totalTokens) * c;
      const el = <circle key={a.key} cx="100" cy="100" r={r} fill="none" stroke="var(--primary)" strokeOpacity={OPACITY[i]} strokeWidth={active === i ? 30 : 22} strokeDasharray={`${len - 2} ${c - len + 2}`} strokeDashoffset={-offset} onMouseEnter={() => onHover(i)} style={{ transition: "stroke-width .3s", cursor: "pointer" }} />;
      offset += len;
      return el;
    })}
  </svg>;
}

function TokenomicsPage() {
  const { t } = useLanguage();
  const [active, setActive] = useState(0);
  const a = ALLOCATION[active]!;
  const flows = [
    { icon: Gift, title: "分红", items: ["每笔交易 2% 税，其中 50% 按卡平均分给持卡人", "阶梯卖单卖币所得 BNB 100% 分给持卡人，7 天匀速发放"] },
    { icon: Flame, title: "销毁", items: ["开池时 97,479,938 枚打入黑洞，LP 同时销毁", "开池后铸造买到的代币，30% 当场销毁", "地板基金收走的卡直接销毁，开池后卡未领的代币一起销毁"] },
    { icon: Droplets, title: "进池", items: [`只在开池时进一次：${P.poolBnb} BNB + ${fmt(P.poolTokens)} 枚`, "开池后铸造的 BNB 75% 在池子里买币，不是加流动性"] },
  ];
  return <SiteShell index="06" code="TOKENOMICS" title="代币经济" lead={`总量 ${fmt(P.totalTokens)} 枚，合约写死，不能增发。每一枚去了哪里，都在下面。`} seed={606}>
    <div className="grid items-center gap-10 lg:grid-cols-[minmax(0,420px)_1fr]">
      <div className="relative mx-auto w-full max-w-[420px]">
        <Donut active={active} onHover={setActive} />
        <div key={active} className="gx-swap pointer-events-none absolute inset-0 grid place-content-center text-center">
          <p className="font-mono text-4xl font-bold text-primary">{((a.amount / P.totalTokens) * 100).toFixed(1)}%</p>
          <p className="mt-1 text-sm">{t(a.label)}</p>
        </div>
      </div>
      <ul className="space-y-2">{ALLOCATION.map((x, i) => <li key={x.key}>
        <button type="button" onMouseEnter={() => setActive(i)} onFocus={() => setActive(i)} onClick={() => setActive(i)} className={`gx-alloc ${active === i ? "gx-alloc-active" : ""}`}>
          <span className="size-3 rounded-full bg-primary" style={{ opacity: OPACITY[i] }} />
          <span className="min-w-0 flex-1 text-left"><span className="block font-medium">{t(x.label)}</span><span className="block text-xs text-muted-foreground">{t(x.note)}</span></span>
          <span className="text-right font-mono text-sm">{fmt(x.amount)}<span className="block text-xs text-muted-foreground">{((x.amount / P.totalTokens) * 100).toFixed(1)}%</span></span>
        </button>
      </li>)}</ul>
    </div>

    <h2 className="mt-20 mb-6 text-2xl font-bold">{t("钱和币的去向")}</h2>
    <div className="grid gap-5 md:grid-cols-3">{flows.map(f => <section key={f.title} className="gx-panel p-6">
      <f.icon className="size-6 text-primary" aria-hidden="true" />
      <h3 className="mt-4 text-xl font-bold">{t(f.title)}</h3>
      <ul className="mt-4 space-y-3 text-sm leading-7 text-muted-foreground">{f.items.map(i => <li key={i}>{t(i)}</li>)}</ul>
    </section>)}</div>

    <div className="mt-16"><PoolStats /></div>
    <Button asChild variant="outline" className="mt-10"><Link to="/rules">{t("查看完整规则")}<ArrowUpRight /></Link></Button>
  </SiteShell>;
}
