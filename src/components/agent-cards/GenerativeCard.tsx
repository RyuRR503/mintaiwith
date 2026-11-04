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

/** Brand "7" numeral per card: violet glyph, moving light band, receding echoes, pointer depth. */
export function GenerativeCard({ id, className, interactive = true, kind = "open" }: { id: number; className?: string; interactive?: boolean; kind?: "presale" | "open" | "team" }) {
  const ref = useRef<HTMLCanvasElement>(null);
  const pointer = useRef({ x: 0.5, y: 0.5, active: false });

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
    const display = token("--font-poster", "'Bebas Neue', sans-serif");
    const echoes = (kind === "team" ? 5 : 3) + Math.floor(rand() * 3);
    const sweepSpeed = 0.22 + rand() * 0.12;
    const sweepAngle = 0.5 + rand() * 0.6;
    const sparks = Array.from({ length: 30 }, () => ({ x: rand(), ph: rand(), sp: 0.08 + rand() * 0.12 }));
    let t = rand() * 100, raf = 0, visible = true, lastFrame = 0;
    let ox = 0, oy = 0;
    if (document.fonts) document.fonts.load(`400 100px ${display}`).then(() => repaint?.()).catch(() => {});

    const paint = () => {
      const w = canvas.width, h = canvas.height;
      ctx.globalAlpha = 1;
      ctx.globalCompositeOperation = "source-over";
      ctx.clearRect(0, 0, w, h);
      ctx.fillStyle = bg;
      ctx.fillRect(0, 0, w, h);

      const p = pointer.current;
      const tx = p.active ? p.x - 0.5 : Math.sin(t * 0.4) * 0.25;
      const ty = p.active ? p.y - 0.5 : Math.cos(t * 0.3) * 0.15;
      ox += (tx - ox) * 0.08; oy += (ty - oy) * 0.08;

      const fs = Math.min(h * 0.92, w * 1.5);
      const cx = w / 2, cy = h * 0.53;
      ctx.font = `400 ${fs}px ${display}`;
      ctx.textAlign = "center"; ctx.textBaseline = "middle";

      // Ambient glow behind the numeral.
      const glow = ctx.createRadialGradient(cx, cy, 0, cx, cy, w * 0.7);
      glow.addColorStop(0, flow); glow.addColorStop(1, "transparent");
      ctx.globalAlpha = 0.14 + 0.05 * Math.sin(t * 1.1);
      ctx.fillStyle = glow; ctx.fillRect(0, 0, w, h);

      // Echo outlines receding in depth.
      ctx.strokeStyle = flow; ctx.lineWidth = dpr * 1.2;
      for (let e = echoes; e >= 1; e--) {
        ctx.globalAlpha = (0.08 + 0.16 * (1 - e / (echoes + 1))) * (0.7 + 0.3 * Math.sin(t * 1.3 - e * 0.7));
        ctx.strokeText("7", cx - ox * e * w * 0.035, cy - oy * e * h * 0.03);
      }

      // Main numeral: violet body with a moving light band.
      const fx = cx + ox * w * 0.02, fy = cy + oy * h * 0.015;
      ctx.globalAlpha = 1;
      ctx.shadowColor = flow; ctx.shadowBlur = fs * 0.08;
      ctx.fillStyle = flow; ctx.fillText("7", fx, fy);
      ctx.shadowBlur = 0;
      const pos = ((t * sweepSpeed) % 1.6) - 0.3;
      const dx = Math.cos(sweepAngle) * w, dy = Math.sin(sweepAngle) * h;
      const band = ctx.createLinearGradient(cx - dx / 2, cy - dy / 2, cx + dx / 2, cy + dy / 2);
      const c = (v: number) => Math.min(1, Math.max(0, v));
      band.addColorStop(0, "transparent");
      band.addColorStop(c(pos - 0.12), "transparent");
      band.addColorStop(c(pos), fg);
      band.addColorStop(c(pos + 0.12), "transparent");
      band.addColorStop(1, "transparent");
      ctx.globalCompositeOperation = "lighter";
      ctx.globalAlpha = 0.75; ctx.fillStyle = band; ctx.fillText("7", fx, fy);
      // Thin bright inner outline.
      ctx.globalAlpha = 0.35; ctx.strokeStyle = fg; ctx.lineWidth = dpr; ctx.strokeText("7", fx, fy);

      // Fine sparks rising through the card.
      ctx.fillStyle = fg;
      for (const s of sparks) {
        const life = (t * s.sp + s.ph) % 1;
        ctx.globalAlpha = Math.sin(life * Math.PI) * 0.5;
        ctx.fillRect(s.x * w, h * (1 - life), dpr * 1.2, dpr * 1.2);
      }
      ctx.globalCompositeOperation = "source-over";
      ctx.globalAlpha = 1;
    };

    const advance = () => { t += 0.016; };
    for (let i = 0; i < 40; i++) advance();
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

  return <canvas ref={ref} className={className} aria-label={`MINT.AI #${id}`} role="img"
    onPointerMove={interactive ? e => { const r = e.currentTarget.getBoundingClientRect(); pointer.current = { x: (e.clientX - r.left) / r.width, y: (e.clientY - r.top) / r.height, active: true }; } : undefined}
    onPointerLeave={() => { pointer.current.active = false; }} />;
}
