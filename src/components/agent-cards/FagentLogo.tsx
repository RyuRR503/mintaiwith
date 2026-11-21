import wordmark from "@/assets/logos/ant-ai-wordmark.png";

/** ANT.AI wordmark: sculptural serif lettering with a terracotta arc across the A. */
export function FagentLogo({ className = "", square = true }: { className?: string; square?: boolean }) {
  return (
    <img
      src={wordmark}
      alt="ANT.AI"
      className={`gx-logo ${square ? "" : "gx-logo-wide"} ${className}`}
      draggable={false}
    />
  );
}
