import { useLanguage } from "./LanguageProvider";
import { Link } from "@tanstack/react-router";
import { Button } from "@/components/ui/button";

const pages = [
  { to: "/", label: "铸造卡牌" },
  { to: "/market", label: "卡牌市场" },
  { to: "/commands", label: "Agent 指令" },
  { to: "/vault", label: "金库账本" },
  { to: "/tokenomics", label: "代币经济" },
  { to: "/rules", label: "规则" },
] as const;

export function CardNavigation({ className, compact = false }: { className?: string; compact?: boolean }) {
  const { t } = useLanguage();
  return <nav className={className} aria-label={t("卡牌导航")}>{pages.map(item => <Button key={item.to} asChild variant="ghost" className={compact ? "ac-tab" : "h-10 rounded-none px-0"}><Link to={item.to} activeOptions={{ exact: true }} activeProps={{ className: compact ? "ac-tab-active text-primary" : "text-primary", "aria-current": "page" }} inactiveProps={{ className: "text-muted-foreground" }}>{t(item.label)}</Link></Button>)}</nav>;
}