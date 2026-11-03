import { createFileRoute, Link } from "@tanstack/react-router";
import { ArrowLeft, ArrowUpRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { FagentLogo } from "@/components/agent-cards/FagentLogo";
import { CardNavigation } from "@/components/agent-cards/CardNavigation";
import { LanguageSwitch } from "@/components/agent-cards/LanguageSwitch";
import { useLanguage } from "@/components/agent-cards/LanguageProvider";

export const Route = createFileRoute("/rules")({
  head: () => ({ meta: [
    { title: "7AGENT — 卡牌规则" },
    { name: "description", content: "7AGENT 开池版：预售、开池、5 天释放、交易税与地板基金规则。" },
    { property: "og:title", content: "7AGENT — 卡牌规则" },
    { property: "og:description", content: "777,777 张卡的预售、开池、释放与交易税规则。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ], links: ["16x16", "32x32", "64x64"].map(sizes => ({ rel: "icon", type: "image/png", sizes, href: "/favicon-fagent-approved.png" })) }),
  component: CardRulesPage,
});

const sections = [
  { title: "发行总量", paragraphs: [
    "卡牌：共 777,777 张。738,889 张公开铸造，38,888 张团队卡。每个地址最多铸造 10 张，转让或销毁不恢复名额。",
    "代币：总量固定 777,777,777 枚，合约写死，不能增发。全部分配完毕，没有预留额度，也没有任何人可以动用。",
  ] },
  { title: "代币分配", paragraphs: [
    "① 开池流动性：124,672,000 枚（约 16.0%），与 36.75 BNB 一起进池子，LP 直接销毁。",
    "② 预售卡发放：20,000 张 × 8,440 = 168,800,000 枚（约 21.7%），开池后 5 天线性释放。",
    "!团队卡只占全部卡牌的 5%（38,888 / 777,777），而且不能一次放出：每铸出 19 张付费卡，才解锁 1 张团队卡。团队卡与普通卡同权。",
    "③ 阶梯卖单：58,611,119 枚（约 7.5%），只在币价涨上去之后才卖，卖币得到的 BNB 全部分给持卡人。具体怎么运作见下面「阶梯卖单」一节。",
    "④ 开池时销毁：97,479,938 枚（约 12.5%），开池那一刻直接打进黑洞地址，永久退出流通，不进入池子、不挂单、不计入任何人名下。",
    "①–④ 之外剩下的部分对应团队卡，按上面的解锁节奏逐张放出，不会一次性进入流通。",
    "开池后铸造的卡不占以上额度：它们用 BNB 当场在池子里买币，30% 销毁，70% 5 天释放给铸造地址。",
  ] },
  { title: "预售", paragraphs: [
    "前 20,000 张为预售，每张 0.00245 BNB，合计 49 BNB。预售窗口 7 天。",
    "每张预售卡对应 8,440 枚代币，开池后 5 天线性释放，每天约 1,688 枚。代币记在铸造地址名下，不跟卡转移。",
    "7 天内没卖满，可销毁预售卡，全额退回 BNB。",
  ] },
  { title: "开池", paragraphs: [
    "预售卖满后 7 天内，任何人都可触发开池：36.75 BNB 与 124,672,000 枚代币进入池子，LP 直接销毁；同一步骤把 97,479,938 枚打进黑洞地址销毁。另 12.25 BNB 为运营费用。",
    "超过 7 天未开池，开池永久关闭，预售卡只能退款。",
  ] },
  { title: "开池后铸造", paragraphs: [
    "开池后每张 0.0049 BNB，不涨价。25% 为运营费用，75% 当场在池子里买币。",
    "买到的代币：30% 直接销毁，70% 记在铸造地址名下，5 天线性释放。到手数量按成交时池子价格决定。",
  ] },
  { title: "阶梯卖单", paragraphs: [
    "一句话：金库里留了一批币，等币价涨到开盘价的 1.5 倍、2 倍、3 倍时，分三档按固定价格卖出，卖得的 BNB 全部分给持卡人。",
    "开盘价：36.75 BNB ÷ 124,672,000 枚，约每枚 0.000000295 BNB（即 1 BNB 约买 339 万枚）。",
    "第一档：约 1,953.7 万枚，价格 = 开盘价 × 1.5。第二档：约 1,953.7 万枚，价格 = 开盘价 × 2。第三档：约 1,953.7 万枚，价格 = 开盘价 × 3。",
    "什么时候能买：只有当最近 30 分钟的平均币价达到或超过这一档价格时，这一档才开放。币价没涨到，这批币一枚都不会卖出，不会砸盘。用平均价是为了防止有人瞬间拉价格来触发。",
    "谁来买：任何人都可以按这一档的固定价格直接从金库买，买到的币当场到账。每档卖完即关闭，三档总量就是 58,611,119 枚，卖完不再补充。",
    "钱去哪：卖币收到的 BNB 100% 给持卡人，不进运营。这笔 BNB 分 7 天匀速放进分红，每张卡分到一样多。",
    "!简单说：币价涨得越高，持卡人从阶梯卖单拿到的 BNB 分红越多；币价不涨，阶梯卖单就不动。",
  ] },
  { title: "交易税", paragraphs: [
    "代币每笔交易收 2% 税：50% 按卡等权分红，30% 进入地板基金，20% 为运营费用。",
    "分红记在卡上，需主动领取。卡牌转让后，后续分红归新持有人。",
  ] },
  { title: "地板基金", paragraphs: [
    "地板基金累计达到触发线后，每 30 分钟自动从市场最低挂单收一张卡并销毁，按挂单价全额付给卖家。",
  ] },
  { title: "团队卡", paragraphs: [
    "每铸造 19 张付费卡，激活 1 张团队卡，共 38,888 张，包含在总量内。团队卡与普通卡同权，没有额外权益。",
  ] },
  { title: "铸造方式", paragraphs: [
    "铸造通过币安 Agent 钱包发起，由你在钱包里确认后执行。网站不代你签名，也不代发交易。",
    "数字资产价格会波动，项目不承诺任何固定收益。",
  ] },
];

function CardRulesPage() {
  const { t } = useLanguage();
  return <div className="ac-page">
    <header className="ac-header"><div className="ac-container flex h-20 items-center justify-between gap-4">
      <Link to="/" aria-label={t("7AGENT 首页")}><FagentLogo className="text-lg" /></Link>
      <CardNavigation className="hidden items-center gap-5 lg:gap-7 md:flex" />
      <LanguageSwitch />
    </div></header>
    <main className="ac-container py-10 sm:py-14">
      <div className="mb-8 md:hidden"><CardNavigation className="ac-tabs" compact /></div>
      <Button asChild variant="ghost" className="mb-8 px-0 text-muted-foreground"><Link to="/"><ArrowLeft />{t("返回卡牌")}</Link></Button>
      <p className="mb-3 font-mono text-xs text-primary">7AGENT / RULES</p>
      <h1 className="text-4xl font-bold">{t("卡牌规则")}</h1>
      <p className="mt-4 max-w-2xl text-sm leading-7 text-muted-foreground">{t("依据 7AGENT 开池版合约。合约尚未部署，上线后以链上合约为准。")}</p>
      <div className="mt-10 max-w-3xl">{sections.map((section, i) => <section key={section.title} className="grid grid-cols-[32px_1fr] gap-4 border-t border-border py-7 sm:gap-8"><span className="font-mono text-xs text-primary">{String(i + 1).padStart(2, "0")}</span><div className="min-w-0"><h2 className="mb-3 text-xl">{t(section.title)}</h2><div className="space-y-3">{section.paragraphs.map(paragraph => paragraph.startsWith("!") ? <p key={paragraph} className="rounded-md border border-primary/50 bg-primary/10 px-4 py-3 text-sm font-medium leading-7 text-foreground">{t(paragraph.slice(1))}</p> : <p key={paragraph} className="text-sm leading-7 text-muted-foreground">{t(paragraph)}</p>)}</div></div></section>)}</div>
      <Button asChild className="mt-6"><Link to="/">{t("返回铸造")}<ArrowUpRight /></Link></Button>
    </main>
  </div>;
}