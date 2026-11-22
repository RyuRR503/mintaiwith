import { createFileRoute } from "@tanstack/react-router";
import MintAiApp from "@/vaults/mintai/Component";

export const Route = createFileRoute("/ladder")({
  head: () => ({ meta: [
    { title: "ANTAGENT — 阶梯卖单" },
    { name: "description", content: "ANTAGENT 29,758,758 枚阶梯储备，1.5/2/3 倍开池价认购，ANTB 收入流式分红。" },
    { property: "og:title", content: "ANTAGENT — 阶梯卖单" },
    { property: "og:description", content: "达到 30 分钟均价门槛后使用 ANTB 认购，收入进入七天分红计划。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: Page,
});

function Page() {
  return <MintAiApp initialView="ladder" />;
}