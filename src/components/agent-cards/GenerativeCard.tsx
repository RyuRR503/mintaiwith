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

/** Aurora-silk artwork unique to each card id: wide violet light bands drift slowly like silk; the pointer gently bends them. */
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
    // Per-card identity: band count, drift direction, wave shape, silk tilt.
    const bandCount = (kind === "team" ? 5 : 4) + Math.floor(rand() * 2);
    const tilt = (rand() - 0.5) * 0.9;
    const bands = Array.from({ length: bandCount }, (_, i) => ({
      base: (i + 0.5) / bandCount + (rand() - 0.5) * 0.14,
      amp: 0.05 + rand() * 0.09,
      freq: 1.2 + rand() * 2.2,
      speed: (0.12 + rand() * 0.2) * (rand() < 0.5 ? 1 : -1),
      phase: rand() * Math.PI * 2,
      thick: 0.1 + rand() * 0.16,
      alpha: 0.16 + rand() * 0.14,
    }));
    const glimmer = Array.from({ length: 18 }, () => ({ x: rand(), y: rand(), tw: rand() * Math.PI * 2, size: 0.5 + rand() * 1.2 }));
    let t = rand() * 100, raf = 0, visible = true, lastFrame = 0;

    const paint = () => {
      const w = canvas.width, h = canvas.height;
      // Fully replace the previous frame: nothing accumulates as shadows.
      ctx.globalAlpha = 1;
      ctx.globalCompositeOperation = "source-over";
      ctx.clearRect(0, 0, w, h);
      ctx.fillStyle = bg;
      ctx.fillRect(0, 0, w, h);

      const p = pointer.current;
      ctx.globalCompositeOperation = "lighter";
      for (const b of bands) {
        // Silk ribbon: a smooth wave band filled with a soft vertical gradient.
        const grad = ctx.createLinearGradient(0, (b.base - b.thick) * h, 0, (b.base + b.thick) * h);
        grad.addColorStop(0, "transparent");
        grad.addColorStop(0.5, flow);
        grad.addColorStop(1, "transparent");
        ctx.fillStyle = grad;
        ctx.globalAlpha = b.alpha;
        ctx.beginPath();
        const steps = 48;
        for (let i = 0; i <= steps; i++) {
          const x = i / steps;
          let y = b.base + Math.sin(x * b.freq * Math.PI * 2 + t * b.speed + b.phase) * b.amp + (x - 0.5) * tilt;
          if (p.active) {
            const dx = x - p.x, dy = y - p.y, d = Math.hypot(dx, dy);
            if (d < 0.3) y += (0.3 - d) * 0.25 * Math.sign(dy || 1);
          }
          const px = x * w, py = (y - b.thick / 2) * h;
          if (i === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
        }
        for (let i = steps; i >= 0; i--) {
          const x = i / steps;
          let y = b.base + Math.sin(x * b.freq * Math.PI * 2 + t * b.speed + b.phase) * b.amp + (x - 0.5) * tilt;
          if (p.active) {
            const dx = x - p.x, dy = y - p.y, d = Math.hypot(dx, dy);
            if (d < 0.3) y += (0.3 - d) * 0.25 * Math.sign(dy || 1);
          }
          ctx.lineTo(x * w, (y + b.thick / 2) * h);
        }
        ctx.closePath();
        ctx.fill();
      }

      // Faint glimmers drifting on the silk.
      for (const g of glimmer) {
        const tw = 0.3 + 0.7 * Math.abs(Math.sin(t * 0.9 + g.tw));
        ctx.globalAlpha = tw * 0.5;
        ctx.fillStyle = fg;
        ctx.beginPath();
        ctx.arc(g.x * w, (g.y + Math.sin(t * 0.3 + g.tw) * 0.02) * h, g.size * dpr, 0, Math.PI * 2);
        ctx.fill();
      }

      // Soft ambient glow anchoring the composition.
      ctx.globalCompositeOperation = "source-over";
      const glow = ctx.createRadialGradient(w * 0.5, h * 0.62, 0, w * 0.5, h * 0.62, Math.max(w, h) * 0.7);
      glow.addColorStop(0, flow);
      glow.addColorStop(1, "transparent");
      ctx.globalAlpha = 0.1 + 0.03 * Math.sin(t * 0.6);
      ctx.fillStyle = glow;
      ctx.fillRect(0, 0, w, h);
      ctx.globalAlpha = 1;
    };

    const advance = () => { t += 0.016; };

    // Prepaint a complete composition, including for reduced motion.
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

  return <canvas ref={ref} className={className} aria-label={`7AGENT #${id}`} role="img"
    onPointerMove={interactive ? e => { const r = e.currentTarget.getBoundingClientRect(); pointer.current = { x: (e.clientX - r.left) / r.width, y: (e.clientY - r.top) / r.height, active: true }; } : undefined}
    onPointerLeave={() => { pointer.current.active = false; }} />;
}
