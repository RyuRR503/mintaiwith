/**
 * ANT.AI front mark: an atom orbit — three terracotta ellipses crossing
 * around a four-point spark — that sits in front of the wordmark.
 * Colour comes from `currentColor`, so call sites can tint it with a token.
 */
export function AntMark({ className = "" }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true" className={`gx-logo-mark ${className}`}>
      <g stroke="currentColor" strokeWidth="0.9">
        <ellipse cx="12" cy="12" rx="10" ry="4.1" />
        <ellipse cx="12" cy="12" rx="10" ry="4.1" transform="rotate(60 12 12)" />
        <ellipse cx="12" cy="12" rx="10" ry="4.1" transform="rotate(120 12 12)" />
      </g>
      <path
        d="M12 8.6L12.75 11.25L15.4 12L12.75 12.75L12 15.4L11.25 12.75L8.6 12L11.25 11.25L12 8.6Z"
        fill="currentColor"
      />
    </svg>
  );
}
