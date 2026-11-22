import { createFileRoute } from "@tanstack/react-router";
import MintAiApp from "@/vaults/mintai/Component";

export const Route = createFileRoute("/market")({
  head: () => ({ meta: [
    { title: "ANTAGENT — 卡牌市场" },
    { name: "description", content: "ANTAGENT ANTB 卡牌市场规则：挂单、求购、1% 成交费与分红结算；市场暂未开放。" },
    { property: "og:title", content: "ANTAGENT — 卡牌市场" },
    { property: "og:description", content: "ANTB 计价的卡牌交易与分红结算，市场暂未开放。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: Page,
});
function Page() { return <MintAiApp initialView="market" />; }
