import { createFileRoute } from "@tanstack/react-router";
import MintAiApp from "@/vaults/mintai/Component";

export const Route = createFileRoute("/commands")({
  head: () => ({ meta: [
    { title: "MINT.AI — Agent 指令" },
    { name: "description", content: "币安 Agent 钱包的 MINT.AI 铸造、买卖、分红与退款指令。" },
    { property: "og:title", content: "MINT.AI — Agent 指令" },
    { property: "og:description", content: "币安 Agent 钱包的 MINT.AI 铸造、买卖、分红与退款指令。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: Page,
});
function Page() { return <MintAiApp initialView="commands" />; }
