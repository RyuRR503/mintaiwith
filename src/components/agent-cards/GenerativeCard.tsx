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

/** A single sculpted brand numeral with a slow satin reflection, without particle or echo layers. */
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
    const edge = token("--card-art-edge", flow);
    const shade = token("--card-art-shade", bg);
    const light = token("--card-art-light", fg);
    const sweepSpeed = 0.065 + rand() * 0.015;
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
      const tx = p.active && !reduce ? p.x - 0.5 : 0;
      const ty = p.active && !reduce ? p.y - 0.5 : 0;
      ox += (tx - ox) * 0.08; oy += (ty - oy) * 0.08;

      const fs = Math.min(h * 0.86, w * 1.4);
      const cx = w / 2, cy = h / 2;
      ctx.font = `400 ${fs}px ${display}`;
      ctx.textAlign = "left"; ctx.textBaseline = "alphabetic";
      const metrics = ctx.measureText("7");
      const fx = cx + (metrics.actualBoundingBoxLeft - metrics.actualBoundingBoxRight) / 2 + ox * w * 0.018;
      const fy = cy + (metrics.actualBoundingBoxAscent - metrics.actualBoundingBoxDescent) / 2 + oy * h * 0.012;

      // A narrow bevel gives the glyph depth without detached outlines or bloom.
      ctx.globalAlpha = 1;
      ctx.fillStyle = edge;
      ctx.fillText("7", fx + dpr * 1.5, fy + dpr * 2);
      const body = ctx.createLinearGradient(w * 0.24, h * 0.2, w * 0.76, h * 0.8);
      body.addColorStop(0, light);
      body.addColorStop(0.25, flow);
      body.addColorStop(0.65, shade);
      body.addColorStop(1, flow);
      ctx.fillStyle = body; ctx.fillText("7", fx, fy);

      // One broad, restrained reflection passes across the satin surface.
      const pos = reduce ? 0.45 : ((t * sweepSpeed) % 1.8) - 0.4;
      const band = ctx.createLinearGradient(0, h * 0.1, w, h * 0.9);
      const c = (v: number) => Math.min(1, Math.max(0, v));
      band.addColorStop(0, "transparent");
      band.addColorStop(c(pos - 0.22), "transparent");
      band.addColorStop(c(pos), light);
      band.addColorStop(c(pos + 0.22), "transparent");
      band.addColorStop(1, "transparent");
      ctx.globalAlpha = 0.28; ctx.fillStyle = band; ctx.fillText("7", fx, fy);
      ctx.globalCompositeOperation = "source-over";
      ctx.globalAlpha = 1;
    };

    repaint = paint;
    repaint();
    const draw = (timestamp: number) => {
      if (visible && !document.hidden && timestamp - lastFrame >= 1000 / 60) {
        t += lastFrame ? Math.min((timestamp - lastFrame) / 1000, 0.05) : 0.016;
        paint(); lastFrame = timestamp;
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
