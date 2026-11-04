import { useLanguage } from "./LanguageProvider";
import { useEffect, useState } from "react";
import { formatBnb } from "@/lib/fagent/market";
import { Link } from "@tanstack/react-router";
import { ArrowUpRight, Copy } from "lucide-react";
import { Button } from "@/components/ui/button";
import type { Snapshot } from "@/lib/fagent/chain.server";
import { commandHead } from "@/lib/fagent/commands";
import { CommandDialog } from "./ChainTools";

const manageCommand = `${commandHead}
先读取我的地址持有的全部卡牌（逐张查询 ownerOf 或按铸造记录核对）。然后问我要做什么，按我的选择执行：
1. 领取分红：调用 claim(卡号)，取出已分配未领取的 BNB。
2. 提取卖卡收入：读取 proceedsOwed(我的地址)，大于 0 时调用 withdrawProceeds(我的地址)。
3. 下架挂单：调用 unlist([卡号])。
4. 销毁换代币：确认本批已售满或满 7 天后，调用 redeem(卡号)，不可撤销。
每步先展示交易预览，等我确认后再发送。`;

export function BatchClock({ data }: { data: Snapshot }) {
  const { t } = useLanguage();
  const [elapsed, setElapsed] = useState(0);
  useEffect(() => { setElapsed(0); const timer = setInterval(() => setElapsed(n => n + 1), 1000); return () => clearInterval(timer); }, [data.block]);
  if (data.paid === 731500) return <p className="text-primary">{t("全部售完 · 后续税收经同步等操作分配")}</p>;
  if (!data.openedAt || data.batchPaid === 0) return <p className="text-muted-foreground">{t("本批尚未开始，7 天计时从第一张付费卡铸出起计算。")}</p>;
  const remaining = Math.max(0, data.openedAt + data.releaseSeconds - data.chainTime - elapsed);
  const days = Math.floor(remaining / 86400);
  const hours = Math.floor(remaining % 86400 / 3600);
  const minutes = Math.floor(remaining % 3600 / 60);
  return <p className="font-mono text-xs text-primary">{remaining === 0 ? t("本批已满 7 天 · 可通过同步等操作提前分配与兑换") : t("本批提前分配倒计时 {0}天 {1}时 {2}分 {3}秒", days, hours, minutes, remaining % 60)}</p>;
}

export function VaultLedger({ data }: { data: Snapshot }) {
  const { t } = useLanguage();
  const [command, setCommand] = useState<string | null>(null);
  const rows = [
    [t("累计收到税收"), data.taxReceived],
    [t("NFT 待分配税收"), data.undistributed],
    [t("未领取分红"), data.dividendLiability],
    [t("已支付分红"), data.dividendsPaid],
  ];
  return (
    <>
      <div className="gx-bento">
        {rows.map(([label, value], i) => (
          <div key={label} className={`gx-tile ${i === 0 ? "gx-tile-hero" : ""}`}>
            <span className="gx-tile-no">0{i + 1}</span>
            <p className="text-xs text-muted-foreground">{label}</p>
            <p className="gx-tile-value">{formatBnb(value ?? "0")}<span>BNB</span></p>
          </div>
        ))}
        <div className="gx-tile">
          <span className="gx-tile-no">05</span>
          <p className="text-xs text-muted-foreground">{t("第")} {data.batch} {t("批还没领的代币")}</p>
          <p className="gx-tile-value">{Number(data.batchInventory).toLocaleString("en-US", { maximumFractionDigits: 0 })}<span>{t("枚")}</span></p>
        </div>
      </div>
      <div className="gx-flow-line mt-14" aria-hidden="true">{[t("交易税"), t("金库"), t("分红"), t("持卡人")].map((x, i) => <span key={x} style={{ animationDelay: `${i * 0.4}s` }}>{x}</span>)}</div>
      <div className="mt-14 grid gap-6 lg:grid-cols-[1.4fr_1fr]">
        <section className="gx-panel p-7">
          <p className="gx-kicker">DISTRIBUTION</p>
          <h3 className="mt-3 text-2xl font-bold">{t("税收先累积，批次售满再分配。")}</h3>
          <div className="mt-5 space-y-4 text-sm leading-7 text-muted-foreground">
            <p>{t("77 批全部售完之前，每次有一批售满，累积的 BNB 税收才会分配给当时所有有效、未销毁的卡牌。不是实时到账，也不是固定收益。")}</p>
            <p>{t("如果某一批从第一张付费卡铸出起 7 天还没卖满，攒着的税会分给当时有效的卡牌，不会一直锁在金库里。")}</p>
          </div>
          <Button asChild variant="link" className="mt-3 px-0 text-primary"><Link to="/rules">{t("查看完整规则")}<ArrowUpRight /></Link></Button>
        </section>
        <section className="gx-panel gx-panel-glow flex flex-col p-7">
          <p className="gx-kicker">MY CARDS</p>
          <h3 className="mt-3 text-2xl font-bold">{t("管理我的卡")}</h3>
          <p className="mt-4 flex-1 text-sm leading-7 text-muted-foreground">{t("铸造之后的事都用这一条：领分红、提取卖卡收入、下架、销毁换代币。Agent 会先读出你的卡，再问你要做什么。")}</p>
          <Button className="mt-6 w-full" onClick={() => setCommand(t(manageCommand))}><Copy />{t("复制管理指令")}</Button>
        </section>
      </div>
      <CommandDialog text={command} onClose={() => setCommand(null)} />
    </>
  );
}
