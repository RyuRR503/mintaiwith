import { createFileRoute, Link } from "@tanstack/react-router";
import { ArrowLeft, ArrowUpRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { FagentLogo } from "@/components/agent-cards/FagentLogo";
import { CARD_RULES } from "@/lib/agent-card-model";
import { CardNavigation } from "@/components/agent-cards/CardNavigation";
import { LanguageSwitch } from "@/components/agent-cards/LanguageSwitch";
import { useLanguage } from "@/components/agent-cards/LanguageProvider";

export const Route = createFileRoute("/rules")({
  head: () => ({ meta: [
    { title: "FAGENT — 卡牌规则" },
    { name: "description", content: "FAGENT 的发行数量、铸造价格、税收分配、交易与兑换规则。" },
    { property: "og:title", content: "FAGENT — 卡牌规则" },
    { property: "og:description", content: "77 万张卡牌的铸造、持有、交易与兑换规则。" },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
  ], links: ["16x16", "32x32", "64x64"].map(sizes => ({ rel: "icon", type: "image/png", sizes, href: "/favicon-fagent-approved.png" })) }),
  component: CardRulesPage,
});

const sections = [
  { title: "Fair Mint 公平铸造", paragraphs: [
    "全系列共 77 批，每批 10,000 张：9,500 张公开铸造，500 张团队自留。公开铸造售满 9,500 张，即视为本批满额。",
    "每满一批，结算一次：自代币开始收税起累积的交易税，按卡等权分配。每张卡所得相同，持有几张，即得几份。",
    "铸造费的 80% 用于回购项目代币，回购所得按批次记账；本批售满结算时，剩余代币平均记入本批尚未销毁的卡牌名下。",
    "持续持有，即持续参与分红；若不再需要分红权，可销毁 NFT，换回记在卡上的代币，并一并领走未领分红。销毁后，该卡永久退出分配。",
  ] },
  { title: "铸造资格：币安 Agent 钱包专属", paragraphs: [
    `付费铸造仅面向持有 Agent ID 的币安 Agent 钱包。每张 ${CARD_RULES.mintPriceBnb} BNB，网络费用另计；每个地址终身最多付费铸造 7 张，转让或销毁均不恢复名额。`,
    "Agent ID 是钱包的链上身份，并非 SPACE ID 域名，也不等同于拥有币安账户。合约将核验发起地址是否持有指定的 Agent ID NFT；正式上线前，仍会核实该身份合约与币安 Agent 钱包的对应关系。市场交易不设此门槛。",
  ] },
  { title: "批次机制", paragraphs: [
    "77 万张为发行上限，分为 77 批。每批含 9,500 张付费卡与 500 张团队卡，共 10,000 份权益；团队卡包含在总量之内，并非额外增发。全系列合计 731,500 张付费卡、38,500 张团队卡。",
    "以第 1 批为例：付费卡铸至第 9,500 张时，本批自动结算，下一位铸造者即进入第 2 批。批次进度取决于销量，没有固定周期，也不会按日自动分红。",
  ] },
  { title: "团队权益", paragraphs: [
    "每批含 500 张团队自留卡，包含在 10,000 份总量之内；随付费铸造逐步激活，每铸造 19 张付费卡激活 1 份，与付费卡享有同等的分红与兑换权益。",
  ] },
  { title: "铸造费的去向", paragraphs: [
    "每张 0.002 BNB：其中 0.0016 BNB（80%）即时通过 Flap 买入项目代币，累计计入本批；0.0004 BNB（20%）为运营费用。买入随铸造逐笔发生，并非待批次数满后统一执行。实际购得的代币数量取决于逐笔成交价，不保证与投入等值。",
  ] },
  { title: "交易税的来源", paragraphs: [
    "项目代币的每笔交易收取 2% 交易税，进入卡牌金库，以 BNB 形式留存。通常在每批售满结算时，按卡等权分配给持卡人。",
    "若当前批次自第一张付费卡铸出起满 7 天仍未售满，累积税收即可在同步、领取分红、销毁兑换或市场成交时，分配给当时所有有效、未销毁的卡牌。之后的新税收也按此方式分配，直到下一批开始铸造，7 天计时重新开始。",
  ] },
  { title: "批次结算时发生什么", paragraphs: [
    "每批 9,500 张公开铸造售满时，合约自动完成结算：本批剩余的项目代币平均记入本批尚未销毁的卡牌名下，同时把尚未分配的交易税分给当时所有有效的卡牌。随后开放下一批。若没有提前销毁，本批代币仍按 10,000 份分配。",
    "结算不是只分给新的一批。在没有卡牌销毁的情况下，第一批售满时，税收由第一批的 10,000 份平分；第二批售满时，新累积的税收由前两批共 20,000 份平分，依此类推。已销毁的卡不再计入分配份数，越早持有的卡通常能参与更多次分配。",
    "分红记在卡上，需主动领取；不领取则持续累积。只有销毁卡牌兑换代币后，该卡才退出后续分配。",
  ] },
  { title: "卡上记录的两项权益", paragraphs: [
    "第一项是「可兑换项目代币数量」——不是 BNB 存款，也不是卡牌售价。例如一批实际购得 1,000,000 枚代币，且没有提前销毁，结算后每份记入 100 枚；销毁本批卡牌时即可领取。代币市值随价格波动，合约不承诺固定价值。",
    "第二项是「未领 BNB 分红」——已分配给该卡、但尚未提取的 BNB。例如卡上记有 100 枚代币份额与 0.001 BNB 分红：单独领取分红，仅取出 0.001 BNB，卡牌与代币兑换权均保留；销毁兑换，则一并取出 100 枚代币与全部未领分红，卡牌随之销毁，永久退出后续分配。",
    "因此，持有不销毁，即可持续参与后续税收分配；要取出代币，必须销毁卡牌。通常需等待本批售满；若本批自第一张付费卡铸出起满 7 天仍未售满，也可提前销毁，按当时的平均份额兑换。这个期限按批次计算，不是从个人买入或铸造时开始计算。市场中的挂牌价是卖家报价，与这两项权益相互独立。",
    "提前兑换的代币数量，按本批剩余代币除以本批当时有效的卡牌份数计算；份数包括已铸付费卡及已激活团队权益，并扣除已提前销毁的卡。提前销毁不会关闭本批，后续仍可继续铸造；本批最终售满时，剩余代币由剩余卡牌平分。销毁后不再参与分红，也不会恢复付费铸造名额。",
  ] },
  { title: "全部售完以后", paragraphs: [
    "全部 77 批售完（731,500 张付费卡，连团队自留共 770,000 份）后，不再发行新卡。后续税收无须等待批次结算，而是在同步等操作触发时，按当时仍有效的权益分配。",
    "分红仍需主动领取，销毁仍会减少分红份数。税收多寡取决于实际交易收入，不承诺固定回报。",
  ] },
  { title: "交易与转让中的分红归属", paragraphs: [
    "合约市场的成交手续费为 1%，与税币的交易税是两回事。成交时，该卡此前的未领分红先结算给卖家，买家自成交起参与后续分红；代币兑换权随卡转移。普通钱包转账则令未领分红随卡一并转移。",
    "求购资金由合约托管，未成交部分可撤单退回。购买卡牌不消耗付费铸造名额，也不要求 Agent ID。",
  ] },
  { title: "合约安全", paragraphs: [
    "合约已通过 Flap 官方审计，代码与规则全部公开在链上，资金安全。",
  ] },
];

function CardRulesPage() {
  const { t } = useLanguage();
  return <div className="ac-page">
    <header className="ac-header"><div className="ac-container flex h-20 items-center justify-between gap-4">
      <Link to="/" aria-label={t("FAGENT 首页")}><FagentLogo /></Link>
      <CardNavigation className="hidden items-center gap-5 lg:gap-7 md:flex" />
      <LanguageSwitch />
    </div></header>
    <main className="ac-container py-10 sm:py-14">
      <div className="mb-8 md:hidden"><CardNavigation className="ac-tabs" compact /></div>
      <Button asChild variant="ghost" className="mb-8 px-0 text-muted-foreground"><Link to="/"><ArrowLeft />{t("返回卡牌")}</Link></Button>
      <p className="mb-3 font-mono text-xs text-primary">FAGENT / RULES</p>
      <h1 className="text-4xl font-bold">{t("卡牌规则")}</h1>
      <p className="mt-4 max-w-2xl text-sm leading-7 text-muted-foreground">{t("依据本项目选定的卡牌金库合约。铸造进度、市场挂单与金库账本读取 BNB Chain；交易由币安 Agent 钱包确认后执行。")}</p>
      <div className="mt-10 max-w-3xl">{sections.map((section, i) => <section key={section.title} className="grid grid-cols-[32px_1fr] gap-4 border-t border-border py-7 sm:gap-8"><span className="font-mono text-xs text-primary">{String(i + 1).padStart(2, "0")}</span><div className="min-w-0"><h2 className="mb-3 text-xl">{t(section.title)}</h2><div className="space-y-3">{section.paragraphs.map(paragraph => <p key={paragraph} className="text-sm leading-7 text-muted-foreground">{t(paragraph)}</p>)}</div></div></section>)}</div>
      <Button asChild className="mt-6"><Link to="/">{t("返回铸造")}<ArrowUpRight /></Link></Button>
    </main>
  </div>;
}