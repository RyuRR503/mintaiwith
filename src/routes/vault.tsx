import { createFileRoute } from "@tanstack/react-router";
import { snapshotOptions } from "@/lib/fagent/queries";
import { CardExperience } from "@/components/agent-cards/CardExperience";

export const Route = createFileRoute("/vault")({
  loader: ({ context }) => context.queryClient.ensureQueryData(snapshotOptions()),
  head: () => ({ meta: [
    { title: "7AGENT — 金库账本" },
    { name: "description", content: "7AGENT BNB 税收金库账本与分配说明。" },
    { property: "og:title", content: "7AGENT — 金库账本" },
    { property: "og:description", content: "7AGENT BNB 税收金库账本与分配说明。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: Page,
});
function Page() { return <CardExperience page="vault" />; }
