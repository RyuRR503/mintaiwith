import { createFileRoute } from "@tanstack/react-router";
import MintAiApp from "@/vaults/mintai/Component";

export const Route = createFileRoute("/vault")({
  head: () => ({ meta: [
    { title: "ANTAGENT — 金库账本" },
    { name: "description", content: "ANTAGENT BNB 税收金库账本与分配说明。" },
    { property: "og:title", content: "ANTAGENT — 金库账本" },
    { property: "og:description", content: "ANTAGENT BNB 税收金库账本与分配说明。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: Page,
});
function Page() { return <MintAiApp initialView="vault" />; }
