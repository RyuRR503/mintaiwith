import { createFileRoute } from "@tanstack/react-router";
import MintAiApp from "@/vaults/mintai/Component";

export const Route = createFileRoute("/commands")({
  head: () => ({ meta: [
    { title: "ANTAGENT — Agent 指令" },
    { name: "description", content: "ANTAGENT 新版 Agent 操作准备：ANTB 授权与 BNB 服务费；未部署前不提供可执行交易指令。" },
    { property: "og:title", content: "ANTAGENT — Agent 指令" },
    { property: "og:description", content: "通过 Binance Agent Wallet 确认交易；新版地址接入前暂不开放操作。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: Page,
});
function Page() { return <MintAiApp initialView="commands" />; }
