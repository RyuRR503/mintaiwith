import { createFileRoute, Link } from "@tanstack/react-router";
import { ArrowUpRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { SiteShell } from "@/components/agent-cards/SiteShell";
import { useLanguage } from "@/components/agent-cards/LanguageProvider";

export const Route = createFileRoute("/rules")({
  head: () => ({ meta: [
    { title: "MINT.AI — 卡牌规则" },
    { name: "description", content: "MINT.AI 开池版：预售、开池、5 天释放、交易税与地板基金规则。" },
    { property: "og:title", content: "MINT.AI — 卡牌规则" },
    { property: "og:description", content: "777,777 张卡的预售、开池、释放与交易税规则。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ], links: ["16x16", "32x32", "64x64"].map(sizes => ({ rel: "icon", type: "image/png", sizes, href: "/favicon.png" })) }),
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
    "开池后铸造的卡不占以上额度：它们用 BNB 当场在池子里买币，10% 销毁，90% 5 天释放给铸造地址。",
  ] },
  { title: "预售", paragraphs: [
    "前 20,000 张为预售，每张 0.00245 BNB，合计 49 BNB。预售窗口 7 天。",
    "每张预售卡对应 8,440 枚代币，开池立即释放 20%，剩余 80% 在 5 天内线性释放。代币记在铸造地址名下，不跟卡转移。",
    "预售截止后若未卖满，可主动销毁自己的预售卡，全额退回 BNB。",
  ] },
  { title: "开池", paragraphs: [
    "卖出第 20,000 张的那一笔铸造会自动开池：36.75 BNB 与 124,672,000 枚代币进入池子，LP 直接销毁；同一步骤把 97,479,938 枚打进黑洞地址销毁。另 12.25 BNB 为运营费用。",
    "卖满与开池是同一笔交易，卖满后不存在等待期，也不能再退款。",
  ] },
  { title: "开池后铸造", paragraphs: [
    "开池后每张 0.0049 BNB，不涨价。25% 为运营费用，75% 当场在池子里买币。",
    "买到的代币：10% 直接销毁，90% 记在铸造地址名下，5 天线性释放。到手数量按成交时池子价格决定。",
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
    "代币每笔交易收 2% 税：50% 按卡等权分红，30% 进入地板基金（用来托底，见下面「地板基金」一节），20% 为运营费用。",
    "分红记在卡上，需主动领取。卡牌转让后，后续分红归新持有人。",
  ] },
  { title: "地板基金", paragraphs: [
    "它是干什么的：托底。市场上最便宜的卖单被它一张一张买走并销毁，低价单被清空、卡被烧掉，地板价就被抬住，想砸盘也砸不穿。",
    "钱从哪来：每笔交易 2% 税里的 30% 进地板基金，记在金库合约里，只用来买卡，任何人都取不走。",
    "先留一笔执行费：基金先补足 0.02 BNB 的触发储备，这笔钱只付自动化服务的手续费，绝不用于买卡。",
    "什么时候买：每 30 分钟自动跑一次，任何人也可以手动触发一次。",
    "怎么买：从市场最低挂单往上排，一路买过去。只要挂价在封顶线以内、基金余额够，就按卖家挂的价格全额买下；同一价位上，预售卡和团队卡优先，然后才是开池后铸造的卡。",
    "卖家拿到多少：挂单价 + 这张卡到目前为止累积的分红，一分不少，当场结清。",
    "买到的卡直接销毁：卡永久消失，总供应量变少，剩下的卡更稀缺。",
    "封顶线：预售卡和团队卡最高 0.00245 BNB，开池后铸造的卡最高 0.0049 BNB。挂价高于封顶线的单不接。",
    "顺带销毁：开池后铸造的卡被买走时，这张卡还没领走的代币一起销毁（已经领走的归原持有人）；预售卡和团队卡的代币不动。",
    "什么时候停：下一档价格超过基金余额，或者超过 0.0049 BNB，这一轮就停，等下一轮。",
    "!简单说：交易越多，基金越有钱，低价单清得越快，卡烧得越多，地板就越高。托底的钱来自市场本身，不靠任何人掏腰包。",
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
  return <SiteShell index="05" code="RULES" title="卡牌规则" lead="依据 MINT.AI 卡牌合约。卡牌已上线，金库在成功开池时创建。" seed={505}>
      <div className="grid gap-10 lg:grid-cols-[220px_1fr]">
        <nav aria-label={t("规则目录")} className="gx-toc hidden lg:block">{sections.map((s, i) => <a key={s.title} href={`#r${i}`}><span>{String(i + 1).padStart(2, "0")}</span>{t(s.title)}</a>)}</nav>
        <div className="min-w-0 space-y-5">{sections.map((section, i) => <section id={`r${i}`} key={section.title} className="gx-panel gx-rule scroll-mt-28 p-6 sm:p-8"><span className="gx-rule-no" aria-hidden="true">{String(i + 1).padStart(2, "0")}</span><h2 className="mb-5 text-2xl font-bold">{t(section.title)}</h2><div className="space-y-3">{section.paragraphs.map(paragraph => paragraph.startsWith("!") ? <p key={paragraph} className="gx-callout">{t(paragraph.slice(1))}</p> : <p key={paragraph} className="text-sm leading-7 text-muted-foreground">{t(paragraph)}</p>)}</div></section>)}</div>
      </div>
      <Button asChild className="mt-6"><Link to="/">{t("返回铸造")}<ArrowUpRight /></Link></Button>
  </SiteShell>;
}