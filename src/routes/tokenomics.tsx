import { createFileRoute } from "@tanstack/react-router";
import MintAiApp from "@/vaults/mintai/Component";

export const Route = createFileRoute("/tokenomics")({
  head: () => ({ meta: [
    { title: "MINT.AI — 代币经济" },
    { name: "description", content: "MINT.AI 代币总量 777,777,777 枚的分配，以及分红、销毁、进池的去向。" },
    { property: "og:title", content: "MINT.AI — 代币经济" },
    { property: "og:description", content: "总量固定，分配透明：开池流动性、预售发放、阶梯卖单、开池销毁、团队卡。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: Page,
});

function Page() {
  return <MintAiApp initialView="tokenomics" />;
}
