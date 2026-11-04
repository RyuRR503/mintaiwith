import { createFileRoute } from "@tanstack/react-router";
import { snapshotOptions } from "@/lib/fagent/queries";
import { CardExperience } from "@/components/agent-cards/CardExperience";

export const Route = createFileRoute("/commands")({
  loader: ({ context }) => context.queryClient.ensureQueryData(snapshotOptions()),
  head: () => ({ meta: [
    { title: "MINT.AI — Agent 指令" },
    { name: "description", content: "币安 Agent 钱包的 MINT.AI 铸造、买卖、分红与兑换指令。" },
    { property: "og:title", content: "MINT.AI — Agent 指令" },
    { property: "og:description", content: "币安 Agent 钱包的 MINT.AI 铸造、买卖、分红与兑换指令。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: Page,
});
function Page() { return <CardExperience page="commands" />; }
