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

/** Sculpted brand numeral with sweeping light, breathing depth and bounded light points. */
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
    const sweepSpeed = 0.22 + rand() * 0.06;
    const sparks = Array.from({ length: 26 }, () => ({ x: rand(), phase: rand(), speed: 0.06 + rand() * 0.08, size: 0.6 + rand() * 0.8 }));
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
      const tx = reduce ? 0 : p.active ? p.x - 0.5 : Math.sin(t * 0.5) * 0.16;
      const ty = reduce ? 0 : p.active ? p.y - 0.5 : Math.cos(t * 0.4) * 0.1;
      ox += (tx - ox) * 0.08; oy += (ty - oy) * 0.08;

      const fs = Math.min(h * 0.86, w * 1.4);
      const cx = w / 2, cy = h / 2;
      ctx.font = `400 ${fs}px ${display}`;
      ctx.textAlign = "left"; ctx.textBaseline = "alphabetic";
      const metrics = ctx.measureText("7");
      const fx = cx + (metrics.actualBoundingBoxLeft - metrics.actualBoundingBoxRight) / 2 + ox * w * 0.018;
      const fy = cy + (metrics.actualBoundingBoxAscent - metrics.actualBoundingBoxDescent) / 2 + oy * h * 0.012;

      // Each frame is replaced completely; these are deliberate bounded depth layers, not trails.
      const breathe = reduce ? 0.5 : 0.5 + 0.5 * Math.sin(t * 1.3);
      ctx.fillStyle = flow;
      ctx.globalAlpha = 0.2 + breathe * 0.1;
      ctx.shadowColor = flow; ctx.shadowBlur = fs * (0.06 + breathe * 0.025);
      ctx.fillText("7", fx, fy);
      ctx.shadowBlur = 0;
      ctx.strokeStyle = flow; ctx.lineWidth = dpr * 0.8;
      for (let layer = 2; layer >= 1; layer--) {
        ctx.globalAlpha = (0.08 + breathe * 0.08) / layer;
        ctx.strokeText("7", fx - layer * dpr * (3 + ox * 10), fy + layer * dpr * (2 + oy * 8));
      }

      // Preserve the approved bevel and centered metal numeral.
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
      const pos = reduce ? 0.45 : 0.5 + 0.65 * Math.sin(t * sweepSpeed * Math.PI);
      const band = ctx.createLinearGradient(0, h * 0.1, w, h * 0.9);
      const c = (v: number) => Math.min(1, Math.max(0, v));
      band.addColorStop(0, "transparent");
      band.addColorStop(c(pos - 0.14), "transparent");
      band.addColorStop(c(pos), fg);
      band.addColorStop(c(pos + 0.14), "transparent");
      band.addColorStop(1, "transparent");
      ctx.globalAlpha = 0.65; ctx.fillStyle = band; ctx.fillText("7", fx, fy);
      for (const spark of sparks) {
        const life = (t * spark.speed + spark.phase) % 1;
        ctx.globalAlpha = Math.sin(life * Math.PI) * 0.5;
        ctx.fillStyle = light;
        ctx.beginPath();
        ctx.arc(spark.x * w + ox * w * 0.015, h * (1 - life), dpr * spark.size, 0, Math.PI * 2);
        ctx.fill();
      }
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
