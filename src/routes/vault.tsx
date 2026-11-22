import { createFileRoute } from "@tanstack/react-router";
import MintAiApp from "@/vaults/mintai/Component";

export const Route = createFileRoute("/vault")({
  head: () => ({ meta: [
    { title: "ANTAGENT — 金库账本" },
    { name: "description", content: "ANTAGENT ANTB 税收金库：50% 分红、15% 地板、15% 加池、20% 运营；新版尚未部署。" },
    { property: "og:title", content: "ANTAGENT — 金库账本" },
    { property: "og:description", content: "ANTAGENT ANTB 税收分配与加池储备规则。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: Page,
});
function Page() { return <MintAiApp initialView="vault" />; }
