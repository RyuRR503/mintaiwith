import { createFileRoute } from "@tanstack/react-router";
import MintAiApp from "@/vaults/mintai/Component";

export const Route = createFileRoute("/rarity")({
  head: () => ({ meta: [
    { title: "ANTAGENT — 稀有度与分红倍数" },
    { name: "description", content: "ANTAGENT 四档卡牌：普通、稀有、史诗、传奇；库存、揭晓与 1/2.5/7/20 分红倍数。" },
    { property: "og:title", content: "ANTAGENT — 稀有度与分红倍数" },
    { property: "og:description", content: "了解四档稀有度、剩余卡组抽取和按倍数分配的 ANTB 分红。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: () => <MintAiApp initialView="rarity" />,
});