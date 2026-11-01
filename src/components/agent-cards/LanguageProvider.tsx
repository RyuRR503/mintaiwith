import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { normalizeLanguage, translate, type Language } from "@/lib/fagent/i18n";

const LanguageContext = createContext({ language: "zh" as Language, setLanguage: (_language: Language) => {} });
export function LanguageProvider({ children }: { children: ReactNode }) {
  const [language, setLanguage] = useState<Language>("zh");
  const [restored, setRestored] = useState(false);
  useEffect(() => {
    try { setLanguage(normalizeLanguage(localStorage.getItem("fagent-language"))); } catch { /* Storage may be disabled. */ }
    setRestored(true);
  }, []);
  useEffect(() => {
    document.documentElement.lang = language === "en" ? "en" : "zh-Hans";
    if (restored) { try { localStorage.setItem("fagent-language", language); } catch { /* Keep the switch usable without storage. */ } }
  }, [language, restored]);
  return <LanguageContext.Provider value={{ language, setLanguage }}>{children}</LanguageContext.Provider>;
}
export function useLanguage() {
  const context = useContext(LanguageContext);
  return { ...context, t: (text: string, ...values: unknown[]) => translate(context.language, text, ...values) };
}