import { createFileRoute } from "@tanstack/react-router";
import { snapshotOptions, marketOptions } from "@/lib/fagent/queries";
import { CardExperience } from "@/components/agent-cards/CardExperience";

export const Route = createFileRoute("/market")({
  loader: ({ context }) => Promise.all([context.queryClient.ensureQueryData(snapshotOptions()), context.queryClient.ensureQueryData(marketOptions())]),
  head: () => ({ meta: [
    { title: "7AGENT — 卡牌市场" },
    { name: "description", content: "7AGENT 卡牌卖单、买单、求购与交易记录。" },
    { property: "og:title", content: "7AGENT — 卡牌市场" },
    { property: "og:description", content: "7AGENT 卡牌卖单、买单、求购与交易记录。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: Page,
});
function Page() { return <CardExperience page="market" />; }
