import { useEffect, useRef } from "react";

function token(name: string, fallback: string) {
  if (typeof window === "undefined") return fallback;
  const v = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  return v || fallback;
}

const GLYPHS = "7AGENT01ΞΣΔ₿";

/**
 * Golden digital rain: slow columns of glyphs falling over the hero.
 * Pointer movement stirs nearby columns; pauses offscreen; static frame for reduced motion.
 */
export function DigitalRain({ className }: { className?: string }) {
  const ref = useRef<HTMLCanvasElement>(null);
  const pointer = useRef({ x: -1, y: -1, active: false });

  useEffect(() => {
    const canvas = ref.current; if (!canvas) return;
    const ctx = canvas.getContext("2d"); if (!ctx) return;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const dpr = Math.min(2, window.devicePixelRatio || 1);
    const gold = token("--primary", "#d4a94a");
    const bg = token("--background-deep", token("--background", "#0a0a0a"));

    let cols = 0, drops: number[] = [], speeds: number[] = [], cell = 18;
    let visible = true, raf = 0, last = 0;

    const resize = () => {
      canvas.width = Math.round(canvas.clientWidth * dpr);
      canvas.height = Math.round(canvas.clientHeight * dpr);
      cell = Math.max(14, Math.round(canvas.width / 90));
      cols = Math.ceil(canvas.width / cell);
      drops = Array.from({ length: cols }, () => Math.random() * (canvas.height / cell));
      speeds = Array.from({ length: cols }, () => 0.25 + Math.random() * 0.6);
      ctx.fillStyle = bg; ctx.fillRect(0, 0, canvas.width, canvas.height);
    };
    resize();
    const ro = new ResizeObserver(resize); ro.observe(canvas);

    const paint = (dt: number) => {
      const w = canvas.width, h = canvas.height;
      ctx.fillStyle = bg; ctx.globalAlpha = 0.12; ctx.fillRect(0, 0, w, h);
      ctx.globalAlpha = 1;
      ctx.font = `${cell * 0.9}px monospace`;
      ctx.textBaseline = "top";
      const p = pointer.current;
      for (let c = 0; c < cols; c++) {
        const x = c * cell, y = (drops[c] ?? 0) * cell;
        const glyph = GLYPHS[Math.floor(Math.random() * GLYPHS.length)];
        // head glows brighter, trail fades via the translucent fill above
        const near = p.active && Math.hypot(x - p.x * w, y - p.y * h) < w * 0.12;
        ctx.fillStyle = gold;
        ctx.globalAlpha = near ? 0.95 : 0.5;
        ctx.fillText(glyph ?? "7", x, y);
        if (near) { ctx.globalAlpha = 0.35; ctx.fillText("7", x, y - cell); }
        drops[c] = (drops[c] ?? 0) + (speeds[c] ?? 0.4) * dt * (near ? 2.2 : 1);
        if (y > h && Math.random() > 0.975) drops[c] = 0;
      }
      ctx.globalAlpha = 1;
    };

    const draw = (now: number) => {
      const dt = Math.min(3, (now - last) / 16.7 || 1); last = now;
      if (visible && !document.hidden) paint(dt);
      raf = requestAnimationFrame(draw);
    };
    const io = new IntersectionObserver(es => { visible = es.some(e => e.isIntersecting); });
    io.observe(canvas);

    if (reduce) { for (let i = 0; i < 40; i++) paint(1); } else { raf = requestAnimationFrame(draw); }
    return () => { cancelAnimationFrame(raf); ro.disconnect(); io.disconnect(); };
  }, []);

  return (
    <canvas ref={ref} className={className} aria-hidden="true"
      onPointerMove={e => { const r = e.currentTarget.getBoundingClientRect(); pointer.current = { x: (e.clientX - r.left) / r.width, y: (e.clientY - r.top) / r.height, active: true }; }}
      onPointerLeave={() => { pointer.current.active = false; }} />
  );
}
