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
    const flow = token("--primary", "#8b5cf6");
    const bg = token("--background-deep", token("--background", "#0a0a0a"));
    const fg = token("--foreground", "#f5f0e6");
    const rand = rng(id + 7);
    const freq = 0.6 + rand() * 2.4, twist = rand() * Math.PI * 2, arms = 2 + Math.floor(rand() * 5);
    const count = kind === "team" ? 140 : 180;
    const parts = Array.from({ length: count }, () => ({
      x: rand(), y: rand(), life: 40 + rand() * 200,
      highlight: rand() < 0.08,
      path: [] as { x: number; y: number }[],
    }));
    let t = 0, raf = 0, visible = true, lastFrame = 0;
    const field = (x: number, y: number) => {
      const cx = x - 0.5, cy = y - 0.5;
      let a = Math.atan2(cy, cx) * arms + Math.sin(x * freq * 6 + t) * 1.2 + Math.cos(y * freq * 5 - t * 0.7) + twist;
      const p = pointer.current;
      if (p.active) { const dx = x - p.x, dy = y - p.y, d = Math.hypot(dx, dy); if (d < 0.35) a += (0.35 - d) * 9 * Math.sign(Math.sin(id)); }
      return a;
    };
    const advance = () => {
      for (const q of parts) {
        const a = field(q.x, q.y), nx = q.x + Math.cos(a) * 0.004, ny = q.y + Math.sin(a) * 0.004;
        q.path.push({ x: q.x, y: q.y });
        if (q.path.length > 36) q.path.shift();
        q.x = nx; q.y = ny; q.life -= 1;
        if (q.life < 0 || nx < 0 || nx > 1 || ny < 0 || ny > 1) {
          q.x = rand(); q.y = rand(); q.life = 120 + rand() * 160; q.path = [];
        }
      }
      t += 0.004;
    };
    const paint = () => {
      const w = canvas.width, h = canvas.height;
      // Fully replace the previous frame: old paths never accumulate as shadows.
      ctx.globalAlpha = 1;
      ctx.clearRect(0, 0, w, h);
      ctx.fillStyle = bg;
      ctx.fillRect(0, 0, w, h);
      ctx.lineWidth = 0.9 * dpr;
      ctx.lineCap = "round";
      ctx.lineJoin = "round";
      for (const q of parts) {
        const start = q.path[0];
        if (!start || q.path.length < 2) continue;
        ctx.globalAlpha = q.highlight ? 0.35 : 0.65;
        ctx.strokeStyle = q.highlight ? fg : flow;
        ctx.beginPath();
        ctx.moveTo(start.x * w, start.y * h);
        for (let i = 1; i < q.path.length; i++) {
          const point = q.path[i];
          if (point) ctx.lineTo(point.x * w, point.y * h);
        }
        ctx.stroke();
      }
      ctx.globalAlpha = 1;
    };
    // Seed a complete, bounded composition, including for reduced motion.
    for (let i = 0; i < 36; i++) advance();
    repaint = paint;
    repaint();
    const draw = (timestamp: number) => {
      if (visible && !document.hidden && timestamp - lastFrame >= 1000 / 60) {
        advance(); paint(); lastFrame = timestamp;
      }
      raf = requestAnimationFrame(draw);
    };
    const observer = new IntersectionObserver(entries => { visible = entries.some(entry => entry.isIntersecting); });
    observer.observe(canvas);
    if (!reduce) raf = requestAnimationFrame(draw);
    return () => { cancelAnimationFrame(raf); ro.disconnect(); observer.disconnect(); };
  }, [id, kind]);

  return <canvas ref={ref} className={className} aria-label={`7AGENT #${id}`} role="img"
    onPointerMove={interactive ? e => { const r = e.currentTarget.getBoundingClientRect(); pointer.current = { x: (e.clientX - r.left) / r.width, y: (e.clientY - r.top) / r.height, active: true }; } : undefined}
    onPointerLeave={() => { pointer.current.active = false; }} />;
}
