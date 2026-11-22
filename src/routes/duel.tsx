import { createFileRoute } from "@tanstack/react-router";
import MintAiApp from "@/vaults/mintai/Component";

export const Route = createFileRoute("/duel")({
  head: () => ({ meta: [
    { title: "ANTAGENT — NFT 对决" },
    { name: "description", content: "ANTAGENT 夺卡对决规则：第六胜销毁赢来的卡，BNB 服务费独立支付；对决暂未开放。" },
    { property: "og:title", content: "ANTAGENT — NFT 对决" },
    { property: "og:description", content: "胜场随卡、无输家补偿，了解 NFT 对决与超时退卡规则。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: Page,
});

function Page() {
  return <MintAiApp initialView="duel" />;
}