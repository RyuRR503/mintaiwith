import { useEffect, useRef } from "react";

function rng(seed: number) {
  let s = (seed * 2654435761) >>> 0 || 1;
  return () => { s ^= s << 13; s ^= s >>> 17; s ^= s << 5; return ((s >>> 0) % 100000) / 100000; };
}

function token(name: string, fallback: string) {
  if (typeof window === "undefined") return fallback;
  const v = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  return v || fallback;
}

/** Flow-field artwork unique to each card id; the pointer bends the field. */
export function GenerativeCard({ id, className, interactive = true, kind = "open" }: { id: number; className?: string; interactive?: boolean; kind?: "presale" | "open" | "team" }) {
  const ref = useRef<HTMLCanvasElement>(null);
  const pointer = useRef({ x: -1, y: -1, active: false });

  useEffect(() => {
    const canvas = ref.current; if (!canvas) return;
    const ctx = canvas.getContext("2d"); if (!ctx) return;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const dpr = Math.min(2, window.devicePixelRatio || 1);
    let repaint: (() => void) | undefined;
    const resize = () => {
      canvas.width = Math.round(canvas.clientWidth * dpr);
      canvas.height = Math.round(canvas.clientHeight * dpr);
      repaint?.();
    };
    resize();
    const ro = new ResizeObserver(resize); ro.observe(canvas);
    const gold = token("--primary", "#d4a94a");
    const bg = token("--background-deep", token("--background", "#0a0a0a"));
    const fg = token("--foreground", "#f5f0e6");
    const rand = rng(id + 7);
    const freq = 0.6 + rand() * 2.4, twist = rand() * Math.PI * 2, arms = 2 + Math.floor(rand() * 5);
    const count = kind === "team" ? 140 : 220;
    const parts = Array.from({ length: count }, () => ({ x: rand(), y: rand(), life: rand() * 200 }));
    let t = 0, raf = 0, visible = true;
    const field = (x: number, y: number) => {
      const cx = x - 0.5, cy = y - 0.5;
      let a = Math.atan2(cy, cx) * arms + Math.sin(x * freq * 6 + t) * 1.2 + Math.cos(y * freq * 5 - t * 0.7) + twist;
      const p = pointer.current;
      if (p.active) { const dx = x - p.x, dy = y - p.y, d = Math.hypot(dx, dy); if (d < 0.35) a += (0.35 - d) * 9 * Math.sign(Math.sin(id)); }
      return a;
    };
    ctx.fillStyle = bg; ctx.fillRect(0, 0, canvas.width, canvas.height);
    const paint = () => {
      const w = canvas.width, h = canvas.height;
      ctx.globalAlpha = 0.06; ctx.fillStyle = bg; ctx.fillRect(0, 0, w, h);
      ctx.globalAlpha = 0.55; ctx.lineWidth = 1.1 * dpr;
      for (const q of parts) {
        const a = field(q.x, q.y), nx = q.x + Math.cos(a) * 0.004, ny = q.y + Math.sin(a) * 0.004;
        ctx.strokeStyle = q.life % 9 < 1 ? fg : gold;
        ctx.beginPath(); ctx.moveTo(q.x * w, q.y * h); ctx.lineTo(nx * w, ny * h); ctx.stroke();
        q.x = nx; q.y = ny; q.life -= 1;
        if (q.life < 0 || nx < 0 || nx > 1 || ny < 0 || ny > 1) { q.x = rand(); q.y = rand(); q.life = 120 + rand() * 160; }
      }
      t += 0.004;
    };
    repaint = () => {
      ctx.globalAlpha = 1;
      ctx.fillStyle = bg;
      ctx.fillRect(0, 0, canvas.width, canvas.height);
      for (let i = 0; i < 100; i++) paint();
    };
    repaint();
    const draw = () => {
      if (visible && !document.hidden) paint();
      raf = requestAnimationFrame(draw);
    };
    const observer = new IntersectionObserver(entries => { visible = entries.some(entry => entry.isIntersecting); });
    observer.observe(canvas);
    if (!reduce) draw();
    return () => { cancelAnimationFrame(raf); ro.disconnect(); observer.disconnect(); };
  }, [id, kind]);

  return <canvas ref={ref} className={className} aria-label={`7AGENT #${id}`} role="img"
    onPointerMove={interactive ? e => { const r = e.currentTarget.getBoundingClientRect(); pointer.current = { x: (e.clientX - r.left) / r.width, y: (e.clientY - r.top) / r.height, active: true }; } : undefined}
    onPointerLeave={() => { pointer.current.active = false; }} />;
}
