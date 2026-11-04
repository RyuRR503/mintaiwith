import { useEffect, useRef } from "react";

/** Brand word drawn on every card. */
const GLYPH = ".AI";

function rng(seed: number) {
  let s = (seed * 2654435761) >>> 0 || 1;
  return () => { s ^= s << 13; s ^= s >>> 17; s ^= s << 5; return ((s >>> 0) % 100000) / 100000; };
}

function token(name: string, fallback: string) {
  if (typeof window === "undefined") return fallback;
  const v = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  return v || fallback;
}

/** Brand glyph per card: violet letterform, moving light band, receding echoes, pointer depth. */
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
    const sweepSpeed = 0.22 + rand() * 0.12;
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

      // Per-letter layout: tracked letters, each with its own depth, float and light.
      let fs = h * 0.66;
      ctx.font = `400 ${fs}px ${display}`;
      ctx.textAlign = "left"; ctx.textBaseline = "middle";
      const letters = GLYPH.split("");
      const measure = () => letters.map(ch => ctx.measureText(ch).width);
      let widths = measure();
      let track = fs * 0.06;
      let total = widths.reduce((a, v) => a + v, 0) + track * (letters.length - 1);
      if (total > w * 0.84) {
        fs *= (w * 0.84) / total; ctx.font = `400 ${fs}px ${display}`;
        widths = measure(); track = fs * 0.06;
        total = widths.reduce((a, v) => a + v, 0) + track * (letters.length - 1);
      }
      const cx = w / 2, cy = h * 0.52;

      // Ambient glow, stretched horizontally to match the word.
      ctx.save();
      ctx.translate(cx, cy); ctx.scale(1, 0.6);
      const glow = ctx.createRadialGradient(0, 0, 0, 0, 0, w * 0.6);
      glow.addColorStop(0, flow); glow.addColorStop(1, "transparent");
      ctx.globalAlpha = 0.18 + 0.06 * Math.sin(t * 1.1);
      ctx.fillStyle = glow; ctx.fillRect(-w, -h, w * 2, h * 2);
      ctx.restore();

      // Thin horizon line through the word.
      ctx.globalAlpha = 0.25; ctx.fillStyle = flow;
      ctx.fillRect(w * 0.08, cy + fs * 0.42, w * 0.84, Math.max(1, dpr * 0.8));

      let x = cx - total / 2;
      const top = cy - fs * 0.42, bottom = cy + fs * 0.42;
      letters.forEach((ch, i) => {
        const phase = t * 1.2 - i * 0.55;
        const lift = Math.sin(phase) * fs * 0.018;
        const lx = x + ox * w * 0.02 * (1 + i * 0.15);
        const ly = cy + lift + oy * h * 0.015;
        const depth = 0.55 + 0.45 * (0.5 + 0.5 * Math.sin(phase));

        // Single soft echo per letter (no stacked clutter).
        ctx.globalCompositeOperation = "source-over";
        ctx.globalAlpha = 0.22 * depth;
        ctx.strokeStyle = flow; ctx.lineWidth = dpr;
        ctx.strokeText(ch, lx - ox * w * 0.03, ly - oy * h * 0.025 + fs * 0.03);

        // Body: lavender top -> violet -> deep fade, brightness breathes letter by letter.
        const body = ctx.createLinearGradient(0, top + lift, 0, bottom + lift);
        body.addColorStop(0, fg);
        body.addColorStop(0.35, flow);
        body.addColorStop(1, bg);
        ctx.globalAlpha = 1;
        ctx.shadowColor = flow; ctx.shadowBlur = fs * 0.1 * depth;
        ctx.fillStyle = body; ctx.fillText(ch, lx, ly);
        ctx.shadowBlur = 0;

        // Staggered light sweep: passes M, I, N, T one after another.
        const cycle = ((t * sweepSpeed * 1.4) % 1.8) - 0.4 - i * 0.12;
        if (cycle > -0.2 && cycle < 1.2) {
          const band = ctx.createLinearGradient(lx, top, lx + (widths[i] ?? 0), bottom);
          const c = (v: number) => Math.min(1, Math.max(0, v));
          band.addColorStop(0, "transparent");
          band.addColorStop(c(cycle - 0.18), "transparent");
          band.addColorStop(c(cycle), fg);
          band.addColorStop(c(cycle + 0.18), "transparent");
          band.addColorStop(1, "transparent");
          ctx.globalCompositeOperation = "lighter";
          ctx.globalAlpha = 0.7; ctx.fillStyle = band; ctx.fillText(ch, lx, ly);
        }
        ctx.globalCompositeOperation = "lighter";
        ctx.globalAlpha = 0.3; ctx.strokeStyle = fg; ctx.lineWidth = dpr * 0.8; ctx.strokeText(ch, lx, ly);
        x += (widths[i] ?? 0) + track;
      });

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
