import { createFileRoute } from "@tanstack/react-router";
import MintAiApp from "@/vaults/mintai/Component";

export const Route = createFileRoute("/")({
  head: () => ({ meta: [
    { title: "ANTAGENT — ANTB 底池与稀有度卡牌" },
    { name: "description", content: "ANTAGENT 新版：ANTB 底池、8,429 张预售、四档稀有度与加权分红。尚未部署，了解最新合约规则。" },
    { property: "og:title", content: "ANTAGENT — ANTB 底池与稀有度卡牌" },
    { property: "og:description", content: "777,777 张卡，ANTB 底池、阶梯铸造与四档分红权重。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: Page,
});

function Page() {
  return <MintAiApp initialView="home" />;
}
