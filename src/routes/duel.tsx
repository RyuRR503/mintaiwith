import { createFileRoute } from "@tanstack/react-router";
import MintAiApp from "@/vaults/mintai/Component";

export const Route = createFileRoute("/duel")({
  head: () => ({ meta: [
    { title: "ANTAGENT — NFT 对决" },
    { name: "description", content: "ANTAGENT NFT 对决房间与链上规则，支持通过 Binance Agent Wallet 参与。" },
    { property: "og:title", content: "ANTAGENT — NFT 对决" },
    { property: "og:description", content: "ANTAGENT NFT 对决房间与链上规则，支持通过 Binance Agent Wallet 参与。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: Page,
});

function Page() {
  return <MintAiApp initialView="duel" />;
}