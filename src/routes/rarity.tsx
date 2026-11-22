import { createFileRoute } from "@tanstack/react-router";
import MintAiApp from "@/vaults/mintai/Component";

export const Route = createFileRoute("/rarity")({
  head: () => ({ meta: [
    { title: "ANTAGENT — 稀有度与分红权重" },
    { name: "description", content: "ANTAGENT 四档卡牌：普通、稀有、史诗、传奇；库存、揭晓与 2/5/14/40 分红权重。" },
    { property: "og:title", content: "ANTAGENT — 稀有度与分红权重" },
    { property: "og:description", content: "了解四档稀有度、剩余卡组抽取和按权重分配的 ANTB 分红。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: () => <MintAiApp initialView="rarity" />,
});