import { createFileRoute } from "@tanstack/react-router";
import MintAiApp from "@/vaults/mintai/Component";

export const Route = createFileRoute("/")({
  head: () => ({ meta: [
    { title: "ANTAGENT — ANTB 底池与稀有度卡牌" },
    { name: "description", content: "ANTAGENT：777,777 张卡，四档稀有度与 ANTB 分红。了解铸造与持卡规则，参与暂未开放。" },
    { property: "og:title", content: "ANTAGENT — ANTB 底池与稀有度卡牌" },
    { property: "og:description", content: "777,777 张卡，ANTB 底池、阶梯铸造与四档分红倍数。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: Page,
});

function Page() {
  return <MintAiApp initialView="home" />;
}
