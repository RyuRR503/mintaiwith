import wordmark from "@/assets/logos/ant-ai-wordmark.png";
import { AntMark } from "./AntMark";

/** ANT.AI lockup: spark mark in front of the sculptural serif wordmark. */
export function FagentLogo({ className = "", square = true }: { className?: string; square?: boolean }) {
  return (
    <span className={`gx-logo-lock ${square ? "" : "gx-logo-lock-wide"} ${className}`} role="img" aria-label="ANT.AI">
      <AntMark />
      <img src={wordmark} alt="" className="gx-logo" draggable={false} />
    </span>
  );
}
