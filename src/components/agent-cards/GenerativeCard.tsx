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

/** Rotating wireframe crystal unique to each card id; the pointer tilts it. */
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
    // Per-card identity: crystal shape (sides), height ratio, tilt and spin speed.
    const sides = (kind === "team" ? 6 : 4) + Math.floor(rand() * 4);
    const stretch = 1.1 + rand() * 0.6;
    const tiltX = 0.35 + rand() * 0.35;
    const spin = (0.25 + rand() * 0.2) * (rand() < 0.5 ? 1 : -1);
    // Bipyramid crystal + inner shell.
    type V = [number, number, number];
    const verts: V[] = [[0, -stretch, 0], [0, stretch, 0]];
    for (let i = 0; i < sides; i++) { const a = (i / sides) * Math.PI * 2; verts.push([Math.cos(a), 0, Math.sin(a)]); }
    const edges: [number, number][] = [];
    for (let i = 0; i < sides; i++) { const a = 2 + i, b = 2 + ((i + 1) % sides); edges.push([0, a], [1, a], [a, b]); }
    const orbit = Array.from({ length: 3 }, (_, i) => ({ r: 1.35 + i * 0.22, tilt: (rand() - 0.5) * 1.2, speed: 0.2 + rand() * 0.3 }));
    const stars = Array.from({ length: 22 }, () => ({ x: rand(), y: rand(), tw: rand() * Math.PI * 2 }));
    let t = rand() * 100, raf = 0, visible = true, lastFrame = 0;
    let rx = tiltX, ry = rand() * 6;

    const paint = () => {
      const w = canvas.width, h = canvas.height;
      ctx.globalAlpha = 1;
      ctx.globalCompositeOperation = "source-over";
      ctx.clearRect(0, 0, w, h);
      ctx.fillStyle = bg;
      ctx.fillRect(0, 0, w, h);

      // Faint perspective grid floor.
      ctx.strokeStyle = flow; ctx.lineWidth = dpr * 0.6;
      for (let i = 0; i < 8; i++) {
        const y = h * (0.78 + Math.pow(i / 8, 1.6) * 0.22);
        ctx.globalAlpha = 0.05 + i * 0.012;
        ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke();
      }
      for (let i = -6; i <= 6; i++) {
        ctx.globalAlpha = 0.06;
        ctx.beginPath(); ctx.moveTo(w / 2 + i * w * 0.04, h * 0.78); ctx.lineTo(w / 2 + i * w * 0.22, h); ctx.stroke();
      }

      for (const s of stars) {
        ctx.globalAlpha = 0.15 + 0.35 * Math.abs(Math.sin(t * 0.8 + s.tw));
        ctx.fillStyle = fg; ctx.fillRect(s.x * w, s.y * h * 0.75, dpr, dpr);
      }

      const p = pointer.current;
      const targetX = p.active ? tiltX + (p.y - 0.5) * 0.9 : tiltX;
      rx += (targetX - rx) * 0.06;
      const cx = w / 2, cy = h * 0.47, scale = Math.min(w, h) * 0.26;
      const project = ([x, y, z]: V, k = 1): [number, number, number] => {
        x *= k; y *= k; z *= k;
        const cY = Math.cos(ry), sY = Math.sin(ry);
        let x1 = x * cY - z * sY; const z1 = x * sY + z * cY;
        const cX = Math.cos(rx), sX = Math.sin(rx);
        const y1 = y * cX - z1 * sX, z2 = y * sX + z1 * cX;
        const persp = 3.2 / (3.2 + z2);
        x1 *= persp;
        return [cx + x1 * scale, cy + y1 * persp * scale + Math.sin(t * 0.8) * h * 0.012, z2];
      };

      // Orbit rings.
      for (const o of orbit) {
        ctx.beginPath();
        for (let i = 0; i <= 64; i++) {
          const a = (i / 64) * Math.PI * 2 + t * o.speed;
          const [x, y] = project([Math.cos(a) * o.r, Math.sin(a) * o.r * Math.sin(o.tilt), Math.sin(a) * o.r * Math.cos(o.tilt)]);
          if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
        }
        ctx.globalAlpha = 0.14; ctx.strokeStyle = flow; ctx.lineWidth = dpr * 0.7; ctx.stroke();
      }

      // Crystal: outer shell + inner shell, depth-shaded edges.
      ctx.globalCompositeOperation = "lighter";
      for (const k of [1, 0.55]) {
        const pts = verts.map(v => project(v, k));
        for (const [a, b] of edges) {
          const depth = (pts[a][2] + pts[b][2]) / 2;
          ctx.globalAlpha = (k === 1 ? 0.85 : 0.45) * (0.45 + 0.55 * (1 - (depth + 1.6) / 3.2));
          ctx.strokeStyle = flow; ctx.lineWidth = dpr * (k === 1 ? 1.3 : 0.8);
          ctx.beginPath(); ctx.moveTo(pts[a][0], pts[a][1]); ctx.lineTo(pts[b][0], pts[b][1]); ctx.stroke();
        }
        if (k === 1) for (const q of pts) {
          ctx.globalAlpha = 0.9; ctx.fillStyle = fg;
          ctx.beginPath(); ctx.arc(q[0], q[1], dpr * 1.6, 0, Math.PI * 2); ctx.fill();
        }
      }

      ctx.globalCompositeOperation = "source-over";
      const glow = ctx.createRadialGradient(cx, cy, 0, cx, cy, scale * 1.6);
      glow.addColorStop(0, flow); glow.addColorStop(1, "transparent");
      ctx.globalAlpha = 0.12 + 0.04 * Math.sin(t * 1.2);
      ctx.fillStyle = glow; ctx.fillRect(0, 0, w, h);
      ctx.globalAlpha = 1;
    };

    const advance = () => { t += 0.016; ry += 0.016 * spin; };

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
