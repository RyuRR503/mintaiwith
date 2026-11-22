import { createFileRoute } from "@tanstack/react-router";
import MintAiApp from "@/vaults/mintai/Component";

export const Route = createFileRoute("/tokenomics")({
  head: () => ({ meta: [
    { title: "ANTAGENT — 代币经济" },
    { name: "description", content: "ANTAGENT 总量 777,777,777 枚：63,300,000 枚进 ANTB 池，446,930,459 枚开池销毁。" },
    { property: "og:title", content: "ANTAGENT — 代币经济" },
    { property: "og:description", content: "新版 ANTB 底池、8,429 张预售配置、团队配置、阶梯储备与开池销毁。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: Page,
});

function Page() {
  return <MintAiApp initialView="tokenomics" />;
}
