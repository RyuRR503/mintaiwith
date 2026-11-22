import { createFileRoute } from "@tanstack/react-router";
import MintAiApp from "@/vaults/mintai/Component";

export const Route = createFileRoute("/minting")({
  head: () => ({ meta: [
    { title: "ANTAGENT — 阶梯折扣铸造" },
    { name: "description", content: "了解 ANTAGENT 阶梯铸造价格与 Agent ID 持有折扣：满 10 天九折、20 天八五折、30 天八折，并试算 ANTB 铸造费用。铸造暂未开放。" },
    { property: "og:title", content: "ANTAGENT — 阶梯折扣铸造" },
    { property: "og:description", content: "从 0.016 ANTB 起铸，了解阶梯价格、持有折扣与铸造限额。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: () => <MintAiApp initialView="minting" />,
});
