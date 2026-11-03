/** 7AGENT wordmark. `square` is kept for call-site compatibility; both variants render the same wordmark. */
export function FagentLogo({ className = "", square = true }: { className?: string; square?: boolean }) {
  return (
    <span className={`gx-wordmark ${square ? "" : "gx-wordmark-wide"} ${className}`} aria-label="7AGENT" role="img">
      <span className="gx-wordmark-seven">7</span>AGENT
    </span>
  );
}
