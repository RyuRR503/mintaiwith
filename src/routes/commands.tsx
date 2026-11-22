import { createFileRoute } from "@tanstack/react-router";
import MintAiApp from "@/vaults/mintai/Component";

export const Route = createFileRoute("/commands")({
  head: () => ({ meta: [
    { title: "ANTAGENT — Agent 指令" },
    { name: "description", content: "通过 Binance Agent Wallet 参与 ANTAGENT 铸造、交易与领取；操作暂未开放。" },
    { property: "og:title", content: "ANTAGENT — Agent 指令" },
    { property: "og:description", content: "通过 Binance Agent Wallet 确认交易；操作暂未开放。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: Page,
});
function Page() { return <MintAiApp initialView="commands" />; }
