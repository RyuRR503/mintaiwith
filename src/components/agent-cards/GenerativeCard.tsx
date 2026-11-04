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

/** A glowing violet "7" monogram unique to each card id: light traces along the stroke, echo outlines breathe, the pointer shifts the depth. */
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
    // "7" path in unit space (x 0..1, y 0..1): top bar, then the diagonal with a slight curve.
    const slant = 0.08 + rand() * 0.1;
    const pts: [number, number][] = [[0.18, 0.12], [0.82, 0.12]];
    for (let i = 1; i <= 24; i++) {
      const u = i / 24;
      pts.push([0.82 - u * (0.42 + slant) + Math.sin(u * Math.PI) * 0.06, 0.12 + u * 0.78]);
    }
    const seg: number[] = [0];
    for (let i = 1; i < pts.length; i++) seg.push(seg[i - 1] + Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]));
    const total = seg[seg.length - 1];
    const echoes = (kind === "team" ? 5 : 3) + Math.floor(rand() * 3);
    const speed = 0.18 + rand() * 0.12;
    const sparks = Array.from({ length: 26 }, () => ({ at: rand(), off: (rand() - 0.5) * 0.08, ph: rand() * Math.PI * 2 }));
    let t = rand() * 100, raf = 0, visible = true, lastFrame = 0;
    let ox = 0, oy = 0;

    const pointAt = (f: number): [number, number] => {
      const d = (((f % 1) + 1) % 1) * total;
      let i = 1; while (i < seg.length - 1 && seg[i] < d) i++;
      const k = (d - seg[i - 1]) / (seg[i] - seg[i - 1] || 1);
      return [pts[i - 1][0] + (pts[i][0] - pts[i - 1][0]) * k, pts[i - 1][1] + (pts[i][1] - pts[i - 1][1]) * k];
    };

    const paint = () => {
      const w = canvas.width, h = canvas.height;
      ctx.globalAlpha = 1;
      ctx.globalCompositeOperation = "source-over";
      ctx.clearRect(0, 0, w, h);
      ctx.fillStyle = bg;
      ctx.fillRect(0, 0, w, h);

      const p = pointer.current;
      const tx = p.active ? (p.x - 0.5) : Math.sin(t * 0.4) * 0.25;
      const ty = p.active ? (p.y - 0.5) : Math.cos(t * 0.3) * 0.15;
      ox += (tx - ox) * 0.08; oy += (ty - oy) * 0.08;

      const size = Math.min(w * 0.78, h * 0.62);
      const left = (w - size) / 2, top = h * 0.17;
      const X = (x: number, depth = 0) => left + x * size + ox * depth * size * 0.06;
      const Y = (y: number, depth = 0) => top + y * size + oy * depth * size * 0.06;
      const trace = (depth: number) => {
        ctx.beginPath();
        pts.forEach(([x, y], i) => (i ? ctx.lineTo(X(x, depth), Y(y, depth)) : ctx.moveTo(X(x, depth), Y(y, depth))));
      };
      ctx.lineCap = "round"; ctx.lineJoin = "round";

      // Echo outlines stepping back in depth, breathing.
      for (let e = echoes; e >= 1; e--) {
        trace(e * 1.6);
        ctx.strokeStyle = flow;
        ctx.globalAlpha = (0.05 + 0.1 * (1 - e / (echoes + 1))) * (0.7 + 0.3 * Math.sin(t * 1.2 - e * 0.6));
        ctx.lineWidth = size * 0.012;
        ctx.stroke();
      }

      // Main stroke: soft glow + solid body.
      trace(0);
      ctx.globalAlpha = 0.25; ctx.strokeStyle = flow; ctx.lineWidth = size * 0.14; ctx.stroke();
      ctx.globalAlpha = 0.9; ctx.lineWidth = size * 0.075; ctx.stroke();

      // Light running along the 7.
      ctx.globalCompositeOperation = "lighter";
      const head = t * speed;
      for (let i = 0; i < 28; i++) {
        const [x, y] = pointAt(head - i * 0.006);
        ctx.globalAlpha = (1 - i / 28) * 0.8;
        ctx.fillStyle = fg;
        ctx.beginPath(); ctx.arc(X(x), Y(y), size * (0.03 - i * 0.0008), 0, Math.PI * 2); ctx.fill();
      }
      // Sparks drifting off the stroke.
      for (const s of sparks) {
        const [x, y] = pointAt(s.at + t * 0.01);
        const lift = ((t * 0.15 + s.ph) % 1);
        ctx.globalAlpha = (1 - lift) * 0.6;
        ctx.fillStyle = fg;
        ctx.fillRect(X(x + s.off), Y(y - lift * 0.08), dpr * 1.2, dpr * 1.2);
      }

      ctx.globalCompositeOperation = "source-over";
      const glow = ctx.createRadialGradient(w / 2, h * 0.48, 0, w / 2, h * 0.48, size * 0.9);
      glow.addColorStop(0, flow); glow.addColorStop(1, "transparent");
      ctx.globalAlpha = 0.1 + 0.04 * Math.sin(t * 1.1);
      ctx.fillStyle = glow; ctx.fillRect(0, 0, w, h);
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

  return <canvas ref={ref} className={className} aria-label={`7AGENT #${id}`} role="img"
    onPointerMove={interactive ? e => { const r = e.currentTarget.getBoundingClientRect(); pointer.current = { x: (e.clientX - r.left) / r.width, y: (e.clientY - r.top) / r.height, active: true }; } : undefined}
    onPointerLeave={() => { pointer.current.active = false; }} />;
}
