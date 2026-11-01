import { createFileRoute } from "@tanstack/react-router";
import { snapshotOptions } from "@/lib/fagent/queries";
import { CardExperience } from "@/components/agent-cards/CardExperience";

export const Route = createFileRoute("/")({
  loader: ({ context }) => context.queryClient.ensureQueryData(snapshotOptions()),
  head: () => ({ meta: [
    { title: "FAGENT — 一卡双权 · 公平铸造" },
    { name: "description", content: "币安 Agent 钱包铸造 FAGENT，参与 BNB 税收分配、卡牌交易与批次代币兑换。" },
    { property: "og:title", content: "FAGENT — 一张卡，连接链上税收" },
    { property: "og:description", content: "77 批黑金卡牌，铸造、持有、交易与兑换。基于 AgentCardVault 合约的独立体验。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ], links: ["16x16", "32x32", "64x64"].map(sizes => ({ rel: "icon", type: "image/png", sizes, href: "/favicon-fagent-approved.png" })) }),
  component: MintPage,
});

function MintPage() { return <CardExperience page="mint" />; }
