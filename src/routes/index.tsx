import { createFileRoute } from "@tanstack/react-router";
import MintAiApp from "@/vaults/mintai/Component";

export const Route = createFileRoute("/")({
  head: () => ({ meta: [
    { title: "ANT.AI — Anthropic 底池 AI 卡牌" },
    { name: "description", content: "ANT.AI 开池版：20,000 张预售、开池买币、5 天线性释放、地板基金自动收卡。每张卡都是独一无二的代码艺术。" },
    { property: "og:title", content: "ANT.AI — Anthropic 底池 AI 卡牌" },
    { property: "og:description", content: "777,777 张卡，每张一幅由编号生成的代码艺术。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ] }),
  component: Page,
});

function Page() {
  return <MintAiApp initialView="home" />;
}
