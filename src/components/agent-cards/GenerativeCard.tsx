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

type Pulse = { r: number; speed: number; alpha: number; width: number };

/** Electric-pulse artwork unique to each card id: energy rings expand from the core over a faint grid; the pointer fires extra pulses. */
export function GenerativeCard({ id, className, interactive = true, kind = "open" }: { id: number; className?: string; interactive?: boolean; kind?: "presale" | "open" | "team" }) {
  const ref = useRef<HTMLCanvasElement>(null);
  const pointer = useRef({ x: 0.5, y: 0.5, active: false, fire: 0 });

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
    // Per-card identity: core position, ring count, pulse tempo, grid density.
    const core = { x: 0.32 + rand() * 0.36, y: 0.3 + rand() * 0.4 };
    const tempo = 0.5 + rand() * 0.5;
    const gridStep = 10 + Math.floor(rand() * 6);
    const ringCount = kind === "team" ? 4 : 3;
    const pulses: Pulse[] = Array.from({ length: ringCount }, (_, i) => ({
      r: i / ringCount, speed: (0.0016 + rand() * 0.0012) * tempo, alpha: 0.5, width: 1 + rand(),
    }));
    const sparks = Array.from({ length: kind === "team" ? 26 : 34 }, () => ({
      a: rand() * Math.PI * 2, d: 0.08 + rand() * 0.5, size: 0.6 + rand() * 1.6, tw: rand() * Math.PI * 2,
    }));
    let t = rand() * 100, raf = 0, visible = true, lastFrame = 0;

    const paint = () => {
      const w = canvas.width, h = canvas.height;
      const cx = core.x * w, cy = core.y * h;
      const maxR = Math.hypot(Math.max(cx, w - cx), Math.max(cy, h - cy));
      // Fully replace the previous frame: nothing accumulates as shadows.
      ctx.globalAlpha = 1;
      ctx.clearRect(0, 0, w, h);
      ctx.fillStyle = bg;
      ctx.fillRect(0, 0, w, h);

      // Faint circuit grid.
      const step = (Math.min(w, h) / gridStep) || 1;
      ctx.strokeStyle = flow;
      ctx.lineWidth = 0.5 * dpr;
      ctx.globalAlpha = 0.06;
      ctx.beginPath();
      for (let x = step; x < w; x += step) { ctx.moveTo(x, 0); ctx.lineTo(x, h); }
      for (let y = step; y < h; y += step) { ctx.moveTo(0, y); ctx.lineTo(w, y); }
      ctx.stroke();

      // Expanding energy rings.
      for (const p of pulses) {
        const rr = p.r * maxR;
        if (rr < 1) continue;
        const fade = 1 - p.r;
        ctx.globalAlpha = p.alpha * fade * 0.55;
        ctx.strokeStyle = flow;
        ctx.lineWidth = p.width * dpr;
        ctx.beginPath(); ctx.arc(cx, cy, rr, 0, Math.PI * 2); ctx.stroke();
        // Bright leading edge.
        ctx.globalAlpha = fade * 0.8;
        ctx.lineWidth = 0.7 * dpr;
        ctx.strokeStyle = fg;
        ctx.beginPath(); ctx.arc(cx, cy, rr, -0.4 + t, 0.15 + t); ctx.stroke();
      }

      // Pointer pulse: a sharp ring fired from the pointer position.
      const p = pointer.current;
      if (p.fire > 0) {
        const pr = (1 - p.fire) * maxR * 0.45;
        ctx.globalAlpha = p.fire * 0.5;
        ctx.strokeStyle = flow;
        ctx.lineWidth = 1.4 * dpr;
        ctx.beginPath(); ctx.arc(p.x * w, p.y * h, pr, 0, Math.PI * 2); ctx.stroke();
      }

      // Orbiting sparks.
      for (const s of sparks) {
        const a = s.a + t * 0.35;
        const sx = cx + Math.cos(a) * s.d * maxR * 0.8;
        const sy = cy + Math.sin(a) * s.d * maxR * 0.8;
        const tw = 0.35 + 0.65 * Math.abs(Math.sin(t * 2 + s.tw));
        ctx.globalAlpha = tw * 0.7;
        ctx.fillStyle = flow;
        ctx.beginPath(); ctx.arc(sx, sy, s.size * dpr, 0, Math.PI * 2); ctx.fill();
      }

      // Core glow.
      const glow = ctx.createRadialGradient(cx, cy, 0, cx, cy, maxR * 0.28);
      glow.addColorStop(0, flow);
      glow.addColorStop(1, "transparent");
      ctx.globalAlpha = 0.22 + 0.08 * Math.sin(t * 3);
      ctx.fillStyle = glow;
      ctx.fillRect(0, 0, w, h);
      ctx.globalAlpha = 0.9;
      ctx.fillStyle = fg;
      ctx.beginPath(); ctx.arc(cx, cy, 1.6 * dpr, 0, Math.PI * 2); ctx.fill();
      ctx.globalAlpha = 1;
    };

    const advance = () => {
      for (const p of pulses) { p.r += p.speed; if (p.r > 1) p.r = 0; }
      const p = pointer.current;
      if (p.fire > 0) p.fire = Math.max(0, p.fire - 0.02);
      t += 0.008;
    };

    // Prepaint a complete composition, including for reduced motion.
    for (let i = 0; i < 60; i++) advance();
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
    onPointerMove={interactive ? e => { const r = e.currentTarget.getBoundingClientRect(); pointer.current = { x: (e.clientX - r.left) / r.width, y: (e.clientY - r.top) / r.height, active: true, fire: 1 }; } : undefined}
    onPointerLeave={() => { pointer.current.active = false; }} />;
}
