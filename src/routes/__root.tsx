import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Outlet, Link, createRootRouteWithContext, useRouter, HeadContent, Scripts, type ErrorComponentProps } from "@tanstack/react-router";
import { useEffect, type ReactNode } from "react";
import { Button } from "@/components/ui/button";
import { reportLovableError } from "@/lib/lovable-error-reporting";
import appCss from "../styles.css?url";
import { LanguageProvider, useLanguage } from "@/components/agent-cards/LanguageProvider";
import { LanguageMetadata } from "@/components/agent-cards/LanguageMetadata";

function NotFoundComponent() {
  const { t } = useLanguage();
  return <div className="flex min-h-screen items-center justify-center bg-background px-4"><div className="max-w-md text-center"><p className="font-mono text-xs text-primary">7AGENT / 404</p><h1 className="mt-4 text-4xl">{t("页面不存在")}</h1><Button asChild className="mt-6"><Link to="/">{t("返回首页")}</Link></Button></div></div>;
}

function ErrorComponent({ error, reset }: ErrorComponentProps) {
  const { t } = useLanguage();
  const router = useRouter();
  useEffect(() => { reportLovableError(error, { boundary: "tanstack_root_error_component" }); }, [error]);
  return <div className="flex min-h-screen items-center justify-center bg-background px-4"><div className="max-w-md text-center"><h1 className="text-xl">{t("这一页没能加载")}</h1><p className="mt-3 text-sm text-muted-foreground">{t("可以重试，或者回到 7AGENT 首页。")}</p><div className="mt-6 flex justify-center gap-3"><Button onClick={() => { void router.invalidate(); reset(); }}>{t("重试")}</Button><Button asChild variant="outline"><Link to="/">{t("返回首页")}</Link></Button></div></div></div>;
}

export const Route = createRootRouteWithContext<{ queryClient: QueryClient }>()({
  head: () => ({
    meta: [
      { charSet: "utf-8" },
      { name: "viewport", content: "width=device-width, initial-scale=1" },
      { name: "author", content: "7AGENT" },
      { name: "theme-color", content: "#060606" },
      { name: "color-scheme", content: "dark" },
    ],
    links: [
      { rel: "stylesheet", href: appCss },
      { rel: "icon", type: "image/png", href: "/favicon-fagent-approved.png" },
      { rel: "apple-touch-icon", href: "/favicon-fagent-approved.png" },
      { rel: "preconnect", href: "https://fonts.googleapis.com" },
      { rel: "preconnect", href: "https://fonts.gstatic.com", crossOrigin: "anonymous" },
      { rel: "stylesheet", href: "https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Barlow:wght@400;500;600;700&family=Noto+Sans+SC:wght@400;700;900&family=JetBrains+Mono:wght@500&display=swap" },
    ],
  }),
  shellComponent: RootShell,
  component: RootComponent,
  notFoundComponent: NotFoundComponent,
  errorComponent: ErrorComponent,
});

function RootShell({ children }: { children: ReactNode }) {
  return <html lang="zh-Hans"><head><HeadContent /></head><body><LanguageProvider>{children}</LanguageProvider><Scripts /></body></html>;
}

function RootComponent() {
  const { queryClient } = Route.useRouteContext();
  return <QueryClientProvider client={queryClient}><LanguageMetadata /><Outlet /></QueryClientProvider>;
}
