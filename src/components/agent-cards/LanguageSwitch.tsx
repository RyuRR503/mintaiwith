import { Languages } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useLanguage } from "./LanguageProvider";

export function LanguageSwitch() {
  const { language, setLanguage } = useLanguage();
  return <div className="flex h-10 shrink-0 items-center gap-1 border border-primary/40 px-2 text-primary" role="group" aria-label="Language / 语言">
    <Languages className="mr-1 size-4" aria-hidden="true" />
    <Button variant="ghost" size="sm" className={`h-8 px-2 ${language === "zh" ? "text-primary" : "text-muted-foreground"}`} aria-pressed={language === "zh"} onClick={() => setLanguage("zh")}>中文</Button>
    <span className="text-border" aria-hidden="true">/</span>
    <Button variant="ghost" size="sm" className={`h-8 px-2 ${language === "en" ? "text-primary" : "text-muted-foreground"}`} aria-pressed={language === "en"} onClick={() => setLanguage("en")}>EN</Button>
  </div>;
}