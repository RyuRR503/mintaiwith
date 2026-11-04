import { useEffect, useRef, type ReactNode } from "react";
import { Link } from "@tanstack/react-router";
import { ArrowDownRight } from "lucide-react";
import { FagentLogo } from "./FagentLogo";
import { CardNavigation } from "./CardNavigation";
import { LanguageSwitch } from "./LanguageSwitch";
import { GenerativeCard } from "./GenerativeCard";
import { useLanguage } from "./LanguageProvider";

/** Shared Genesis-style frame for every inner page, so all leaves match the homepage. */
export function SiteShell({ index, code, title, lead, seed, aside, children }: { index: string; code: string; title: string; lead: string; seed: number; aside?: ReactNode; children: ReactNode }) {
  const { t } = useLanguage();
  const progress = useRef<HTMLDivElement>(null);
  useEffect(() => {
    let frame = 0;
    const update = () => { cancelAnimationFrame(frame); frame = requestAnimationFrame(() => { const h = document.documentElement.scrollHeight - window.innerHeight; if (progress.current) progress.current.style.transform = `scaleX(${h > 0 ? window.scrollY / h : 0})`; }); };
    window.addEventListener("scroll", update, { passive: true }); update();
    const io = new IntersectionObserver(es => es.forEach(e => { if (e.isIntersecting) { e.target.classList.add("gx-in"); io.unobserve(e.target); } }), { threshold: 0.08 });
    document.querySelectorAll<HTMLElement>("[data-reveal]").forEach(el => io.observe(el));
    return () => { window.removeEventListener("scroll", update); cancelAnimationFrame(frame); io.disconnect(); };
  }, []);
  return (
    <main className="min-h-screen overflow-x-hidden bg-background text-foreground">
      <header className="sticky top-0 z-30 border-b border-border/60 bg-background/80 backdrop-blur">
        <div className="gx-container flex items-center justify-between gap-5 py-3">
          <Link to="/" aria-label={t("MINT.AI 首页")}><FagentLogo className="text-xl" /></Link>
          <CardNavigation compact className="hidden gap-7 md:flex" />
          <LanguageSwitch />
        </div>
        <CardNavigation compact className="gx-container flex justify-between gap-4 overflow-x-auto md:hidden" />
        <div ref={progress} className="gx-reading-progress" aria-hidden="true" />
      </header>

      <section className="gx-container gx-page-hero">
        <div data-reveal className="gx-rise min-w-0">
          <p className="gx-kicker">{index} / {code}</p>
          <h1 className="gx-page-title mt-4">{t(title)}<span className="text-primary">.</span></h1>
          <p className="mt-5 max-w-xl text-base leading-8 text-muted-foreground">{t(lead)}</p>
          {aside && <div className="mt-6">{aside}</div>}
        </div>
        <div data-reveal className="gx-rise gx-page-art" aria-hidden="true">
          <GenerativeCard id={seed} kind="open" className="h-full w-full" />
          <span className="gx-page-index">{index}</span>
        </div>
      </section>
      <div className="gx-container gx-exhibit-caption"><span>MINT.AI / {code}</span><ArrowDownRight className="size-4 text-primary" aria-hidden="true" /></div>

      <div data-reveal className="gx-rise gx-container py-12">{children}</div>

      <footer className="border-t border-border/60 px-6 py-8 text-center font-mono text-xs text-muted-foreground">
        {t("BNB Chain · 无固定收益承诺 · 数字资产存在风险")}
      </footer>
    </main>
  );
}
