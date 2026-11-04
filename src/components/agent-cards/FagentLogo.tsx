/** MINT.AI wordmark. `square` is kept for call-site compatibility; both variants render the same wordmark. */
export function FagentLogo({ className = "", square = true }: { className?: string; square?: boolean }) {
  return (
    <span className={`gx-wordmark ${square ? "" : "gx-wordmark-wide"} ${className}`} aria-label="MINT.AI" role="img">
      MINT<span className="gx-wordmark-seven">.AI</span>
    </span>
  );
}
