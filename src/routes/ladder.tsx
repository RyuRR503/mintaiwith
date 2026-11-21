import { createFileRoute } from "@tanstack/react-router";
import MintAiApp from "@/vaults/mintai/Component";

export const Route = createFileRoute("/ladder")({
  head: () => ({ meta: [
    { title: "ANT.AI — 阶梯卖单" },
    { name: "description", content: "ANT.AI 阶梯卖单：达到均价门槛后按档位认购，收入归持卡人分红。" },
    { property: "og:title", content: "ANT.AI — 阶梯卖单" },
    { property: "og:description", content: "ANT.AI 阶梯卖单：达到均价门槛后按档位认购，收入归持卡人分红。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: Page,
});

function Page() {
  return <MintAiApp initialView="ladder" />;
}