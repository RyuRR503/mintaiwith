import { AntMark } from "./AntMark";

/** Shared live-text wordmark for navigation, cards and page transitions. */
export function AntWordmark() {
  return <span className="gx-logo gx-logo-type">ANT<span className="gx-logo-agent">AGENT</span></span>;
}
export function FagentLogo({ className = "", square = true }: { className?: string; square?: boolean }) {
  return (
    <span className={`gx-logo-lock ${square ? "" : "gx-logo-lock-wide"} ${className}`} role="img" aria-label="ANTAGENT">
      <AntMark />
      <AntWordmark />
    </span>
  );
}
