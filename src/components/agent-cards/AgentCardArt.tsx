import cardArtwork from "@/assets/fagent-card-minimal.png.asset.json";

export function AgentCardArt({ id, compact = false }: { id?: number; compact?: boolean }) {
  return (
    <div className={`ac-card-art ${compact ? "ac-card-art--compact" : ""}`}>
      <img src={cardArtwork.url} alt="ANTAGENT 极简卡牌" width={1024} height={1536} loading={compact ? "lazy" : "eager"} />
      {id !== undefined && <span className="absolute bottom-[6%] right-[9%] font-mono text-primary text-[10px] sm:text-xs">#{String(id).padStart(6, "0")}</span>}
    </div>
  );
}
