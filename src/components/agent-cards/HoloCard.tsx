import { useRef, type PointerEvent } from "react";
import { GenerativeCard } from "./GenerativeCard";

type Kind = "presale" | "open" | "team";

/** Collectible-card presentation: portrait frame, 3D pointer tilt, holographic foil and glare. */
export function HoloCard({ id, kind }: { id: number; kind: Kind }) {
  const ref = useRef<HTMLDivElement>(null);
  const serial = String(id).padStart(6, "0");
  const tier = kind === "presale" ? "PRESALE" : kind === "team" ? "TEAM" : "OPEN";

  const move = (e: PointerEvent<HTMLDivElement>) => {
    const el = ref.current;
    if (!el || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const r = el.getBoundingClientRect();
    const x = (e.clientX - r.left) / r.width;
    const y = (e.clientY - r.top) / r.height;
    el.style.setProperty("--rx", `${(0.5 - y) * 22}deg`);
    el.style.setProperty("--ry", `${(x - 0.5) * 26}deg`);
    el.style.setProperty("--mx", `${x * 100}%`);
    el.style.setProperty("--my", `${y * 100}%`);
    el.dataset["active"] = "true";
  };
  const leave = () => {
    const el = ref.current;
    if (!el) return;
    el.style.setProperty("--rx", "0deg");
    el.style.setProperty("--ry", "0deg");
    el.dataset["active"] = "false";
  };

  return (
    <div className="hc-scene" onPointerMove={move} onPointerLeave={leave}>
      <div className="hc-shadow" aria-hidden="true" />
      <div ref={ref} className="hc-card" data-active="false">
        <div className="hc-inner">
          <header className="hc-head">
            <span className="gx-wordmark text-sm">MINT<span className="gx-wordmark-seven">.AI</span></span>
            <span className="hc-tier">{tier}</span>
          </header>
          <div className="hc-art">
            <GenerativeCard id={id} kind={kind} className="absolute inset-0 h-full w-full" />
            <div className="hc-art-vignette" aria-hidden="true" />
          </div>
          <footer className="hc-foot">
            <div>
              <p className="hc-label">AGENT ID</p>
              <p className="hc-serial">#{serial}</p>
            </div>
            <div className="text-right">
              <p className="hc-label">EDITION</p>
              <p className="hc-edition">1 / 1</p>
            </div>
          </footer>
        </div>
        <div className="hc-foil" aria-hidden="true" />
        <div className="hc-glare" aria-hidden="true" />
      </div>
    </div>
  );
}
