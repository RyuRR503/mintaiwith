import { FAGENT, explorer, deployedAddress } from "@/lib/fagent/config";
import { useLanguage } from "./LanguageProvider";
export function DeploymentContracts({ vault, token }: { vault?: string | null; token?: string | null }) {
  const { language } = useLanguage(); const en = language === "en";
  const rows = [
    [en ? "NFT cards · mint & trade" : "卡牌 · 预售、铸造与交易", FAGENT.cards],
    [en ? "Launcher factory · creates cards" : "启动器工厂 · 创建卡牌", FAGENT.launcherFactory],
    [en ? "Vault factory · creates vault at launch" : "金库工厂 · 开池时创建金库", FAGENT.factory],
    [en ? "Duel contract" : "卡牌对决", FAGENT.duel],
    [en ? "Orderbook · read-only, no funds" : "订单簿 · 只读，不存钱", FAGENT.orderbook],
    [en ? "Upgrade manager · supplied address needs correction" : "升级管理 · 地址格式待确认", FAGENT.upgradeManager],
  ];
  return <section className="mb-8 border-b border-border pb-8"><h3 className="mb-4 text-lg">{en ? "BNB Chain contracts" : "BNB Chain 合约"}</h3><dl className="grid gap-4 md:grid-cols-2">{rows.map(([label,address]) => <div key={address} className="min-w-0"><dt className="mb-1 text-xs text-muted-foreground">{label}</dt><dd>{address && deployedAddress(address) ? <a href={explorer(address)} target="_blank" rel="noreferrer" className="break-all font-mono text-xs text-primary">{address}</a> : <span className="break-all font-mono text-xs text-muted-foreground">{address}</span>}</dd></div>)}</dl><p className="mt-5 break-all text-sm text-muted-foreground">{en ? "Vault: " : "金库："}{vault ? <a href={explorer(vault)} target="_blank" rel="noreferrer" className="text-primary">{vault}</a> : en ? "Not created yet. Created through the vault factory once 20,000 presale cards sell out and launch succeeds." : "尚未创建。20,000 张预售卡售满并成功开池时，由金库工厂创建。"}</p>{token && <p className="mt-2 break-all text-xs text-muted-foreground">Token: <a href={explorer(token)} className="text-primary" target="_blank" rel="noreferrer">{token}</a></p>}</section>;
}
