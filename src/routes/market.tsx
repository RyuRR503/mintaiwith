import { createFileRoute } from "@tanstack/react-router";
import MintAiApp from "@/vaults/mintai/Component";

export const Route = createFileRoute("/market")({
  head: () => ({ meta: [
    { title: "ANTAGENT — 卡牌市场" },
    { name: "description", content: "ANTAGENT 卡牌卖单、买单、求购与交易记录。" },
    { property: "og:title", content: "ANTAGENT — 卡牌市场" },
    { property: "og:description", content: "ANTAGENT 卡牌卖单、买单、求购与交易记录。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: Page,
});
function Page() { return <MintAiApp initialView="market" />; }
