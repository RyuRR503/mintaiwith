/**
 * ANT.AI front mark: a four-point spark that sits in front of the wordmark.
 * Colour comes from `currentColor`, so call sites can tint it with a token.
 */
export function AntMark({ className = "" }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" aria-hidden="true" className={`gx-logo-mark ${className}`}>
      <path
        d="M12 2L13.15 9.85L19.5 4.5L14.15 10.85L22 12L14.15 13.15L19.5 19.5L13.15 14.15L12 22L10.85 14.15L4.5 19.5L9.85 13.15L2 12L9.85 10.85L4.5 4.5L10.85 9.85L12 2Z"
        fill="currentColor"
      />
    </svg>
  );
}
