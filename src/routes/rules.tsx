import { createFileRoute } from "@tanstack/react-router";
import MintAiApp from "@/vaults/mintai/Component";

export const Route = createFileRoute("/rules")({
  head: () => ({ meta: [
    { title: "MINT.AI — 卡牌规则" },
    { name: "description", content: "MINT.AI 开池版：预售、开池、5 天释放、交易税与地板基金规则。" },
    { property: "og:title", content: "MINT.AI — 卡牌规则" },
    { property: "og:description", content: "777,777 张卡的预售、开池、释放与交易税规则。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ], links: ["16x16", "32x32", "64x64"].map(sizes => ({ rel: "icon", type: "image/png", sizes, href: "/favicon.png" })) }),
  component: Page,
});

function Page() {
  return <MintAiApp initialView="rules" />;
}