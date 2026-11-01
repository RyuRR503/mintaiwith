import logo from "@/assets/fagent-logo-approved.png.asset.json";
import squareLogo from "@/assets/fagent-square-500-v2.png.asset.json";

export function FagentLogo({ className = "size-12", square = true }: { className?: string; square?: boolean }) {
  return <img src={square ? squareLogo.url : logo.url} alt="FAGENT" width={square ? 500 : 885} height={square ? 500 : 125} className={`${className} max-w-full object-contain`} />;
}