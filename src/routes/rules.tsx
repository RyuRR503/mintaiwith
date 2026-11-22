import { createFileRoute } from "@tanstack/react-router";
import MintAiApp from "@/vaults/mintai/Component";

export const Route = createFileRoute("/rules")({
  head: () => ({ meta: [
    { title: "ANTAGENT — 卡牌规则" },
    { name: "description", content: "ANTAGENT 最新合约：ANTB 付款、8,429 张预售、稀有度、身份折扣、释放、税收、地板与对决规则。" },
    { property: "og:title", content: "ANTAGENT — 卡牌规则" },
    { property: "og:description", content: "777,777 张卡的稀有度、加权分红与 ANTB 底池经济规则。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: Page,
});

function Page() {
  return <MintAiApp initialView="rules" />;
}