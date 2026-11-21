import { useState } from "react";
import { Check, Copy } from "lucide-react";

type CopyButtonProps = {
  value: string;
  label?: string;
};

export function CopyButton({ value, label = "Copy" }: CopyButtonProps) {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(value);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1800);
    } catch {
      const textarea = document.createElement("textarea");
      textarea.value = value;
      textarea.style.position = "fixed";
      textarea.style.opacity = "0";
      document.body.appendChild(textarea);
      textarea.select();
      document.execCommand("copy");
      document.body.removeChild(textarea);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1800);
    }
  };

  return (
    <button
      type="button"
      className="gx-btn gx-btn-outline text-xs"
      onClick={() => void handleCopy()}
    >
      {copied ? <Check size={14} className="gx-pri" aria-hidden="true" /> : <Copy size={14} aria-hidden="true" />}
      <span>{copied ? "✓" : label}</span>
    </button>
  );
}