import { english } from "./translations";

export type Language = "zh" | "en";
export function normalizeLanguage(value: unknown): Language {
  return value === "en" ? "en" : "zh";
}
export function translate(language: Language, text: string, ...values: unknown[]): string {
  const template = language === "en" ? english[text] ?? text : text;
  const resolve = (value: unknown) => typeof value === "string" && language === "en" && /\p{Script=Han}/u.test(value) ? translate(language, value) : String(value);
  // A few contract-backed rule paragraphs are assembled before rendering.
  if (language === "en" && template === text && /\p{Script=Han}/u.test(text)) {
    for (const [source, target] of Object.entries(english)) {
      if (!/\{\d+\}/.test(source)) continue;
      const indices: number[] = [];
      const pattern = source.split(/(\{\d+\})/).map(part => {
        if (/^\{\d+\}$/.test(part)) { indices.push(Number(part.slice(1, -1))); return "([\\s\\S]*?)"; }
        return part.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      }).join("");
      const match = text.match(new RegExp(`^${pattern}$`));
      if (!match) continue;
      const resolved: unknown[] = [];
      indices.forEach((index, position) => { resolved[index] = match[position + 1]; });
      return target.replace(/\{(\d+)\}/g, (placeholder, index: string) => resolve(resolved[Number(index)] ?? placeholder));
    }
  }
  return template.replace(/\{(\d+)\}/g, (placeholder, index: string) => resolve(values[Number(index)] ?? placeholder));
}