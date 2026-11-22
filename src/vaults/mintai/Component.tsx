"use client";

import { useEffect, useLayoutEffect, useRef, useState, type PointerEvent, type ReactNode, type UIEvent } from "react";
import { ArrowDownRight, Droplets, Flame, Gift, Shuffle } from "lucide-react";
import { encodeFunctionData, formatEther, isAddress, parseAbi, parseUnits } from "viem";
import { useFlapSdk } from "@/lib/flap-sdk";
import { CopyButton } from "@/components/flap/CopyButton";
import { AntWordmark } from "@/components/agent-cards/FagentLogo";
import { AntMark } from "@/components/agent-cards/AntMark";
import { ANTAGENT_EDITION, EDITION_COPY, EDITION_RULES } from "@/lib/fagent/antagent-edition";
import { EditionStatus, EditionSummary, EditionCalculator, EditionInner, RarityReference, TokenReference } from "@/components/agent-cards/EditionReference";

const TOTAL_POOL_CARDS = 777_777;
const PRESALE_CARDS = 20_000;
const CARD_GRANT = 8_440;
const MAX_MINT = 10;
const ROWS = 20;
const COMMANDS = [
  ["mint", "wallet"],
  ["mint", "mint"],
  ["mint", "refund"],
  ["buy", "buy"],
  ["buy", "bid"],
  ["buy", "cancel"],
  ["sell", "list"],
  ["sell", "sell"],
  ["sell", "unlist"],
  ["yield", "claim"],
  ["yield", "redeem"],
  ["yield", "withdraw"],
] as const;
const COMMAND_GROUPS = ["mint", "buy", "sell", "yield"] as const;
const VIEWS = ["home", "market", "commands", "vault", "tokenomics", "ladder", "duel", "rules", "rarity"] as const;
const POOL_QUOTE = 3675n * 10n ** 16n;
const POOL_TOKEN = 124_672_000n * 10n ** 18n;
const LADDER_BUDGET = 58_611_119n * 10n ** 18n;
const LADDER_BASE = LADDER_BUDGET / 3n;
const LADDER_SIZE = [LADDER_BASE, LADDER_BASE, LADDER_BUDGET - LADDER_BASE * 2n] as const;
const LADDER_MULTIPLE = [[3n, 2n], [2n, 1n], [3n, 1n]] as const;
function ladderPrice(rung: number) {
  const pair = LADDER_MULTIPLE[rung] ?? LADDER_MULTIPLE[0];
  const [num, den] = pair;
  return (POOL_QUOTE * 10n ** 18n * num) / (POOL_TOKEN * den);
}

function ladderCost(amount: bigint, price: bigint) {
  return (amount * price + 10n ** 18n - 1n) / 10n ** 18n;
}

function priceText(value: bigint) {
  const [head, tail = ""] = formatEther(value).split(".");
  const cut = tail.slice(0, 10).replace(/0+$/, "");
  return cut ? `${head}.${cut}` : head;
}
const PRESALE_WEI = 2450000000000000n;
const OPEN_WEI = 4900000000000000n;
const AGENT_ID = "0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F";

function encoded(signature: string, args: readonly unknown[] = []) {
  const abi = parseAbi([signature] as readonly string[]);
  const item = abi[0];
  if (!item || item.type !== "function") return "STOP_NEED_ARGS";
  return encodeFunctionData({ abi, functionName: item.name, args: args as never });
}
export type View = (typeof VIEWS)[number];
type Kind = "presale" | "open" | "team";

const ALLOC = [
  { key: "pool", amount: 124_672_000 },
  { key: "presale", amount: 168_800_000 },
  { key: "ladder", amount: 58_611_119 },
  { key: "burn", amount: 97_479_938 },
] as const;
const TEAM_TOKENS = 777_777_777 - ALLOC.reduce((sum, item) => sum + item.amount, 0);
const SLICES = [...ALLOC, { key: "team", amount: TEAM_TOKENS }] as const;
const SLICE_ALPHA = [1, 0.75, 0.55, 0.35, 0.2];
const FLOW = "#D4623F";
const INK = "#1C1916";
const PAPER = "#F4EFE6";
const SAND = "#C8B9A6";
const POSTER_EM = 1000;
const POSTER: Record<string, { w: number; d: string }> = {
  "M": { w: 538, d: "M41 200H198L268 701H270L340 200H497V900H393V370H391L311 900H219L139 370H137V900H41Z" },
  "I": { w: 192, d: "M41 200H151V900H41Z" },
  "N": { w: 427, d: "M41 200H179L286 619H288V200H386V900H273L141 389H139V900H41Z" },
  "T": { w: 364, d: "M127 300H12V200H352V300H237V900H127Z" },
  ".": { w: 188, d: "M41 794H147V900H41Z" },
  "A": { w: 401, d: "M126 200H275L389 900H279L259 761V763H134L114 900H12ZM246 668 197 322H195L147 668Z" },
  "B": { w: 404, d: "M41 200H207Q292 200 331 240Q370 279 370 361V389Q370 443 352 477Q335 511 299 526V528Q381 556 381 674V734Q381 815 338 858Q296 900 214 900H41ZM194 485Q227 485 244 468Q260 451 260 411V372Q260 334 246 317Q233 300 204 300H151V485ZM214 800Q243 800 257 784Q271 769 271 731V670Q271 622 254 604Q238 585 200 585H151V800Z" },
  "#": { w: 412, d: "M65 700H16L24 622H73L92 439H42L50 361H100L117 200H204L187 361H258L275 200H362L345 361H396L388 439H337L318 622H369L361 700H310L289 900H202L223 700H152L131 900H44ZM231 622 250 439H179L160 622Z" },
  "/": { w: 389, d: "M285 200H380L104 900H9Z" },
  ",": { w: 188, d: "M77 900H41V794H147V889L92 1020H41Z" },
  "0": { w: 400, d: "M33 734V366Q33 282 76 236Q119 190 200 190Q281 190 324 236Q367 282 367 366V734Q367 818 324 864Q281 910 200 910Q119 910 76 864Q33 818 33 734ZM257 741V359Q257 290 200 290Q143 290 143 359V741Q143 810 200 810Q257 810 257 741Z" },
  "1": { w: 400, d: "M195 366H80V288Q127 288 156 280Q184 272 201 254Q218 235 231 200H305V900H195Z" },
  "2": { w: 400, d: "M39 824Q39 749 63 696Q87 642 149 577Q210 512 234 466Q257 420 257 370Q257 325 242 308Q228 290 200 290Q143 290 143 359V434H39V366Q39 281 81 236Q123 190 203 190Q283 190 325 236Q367 281 367 366Q367 430 336 491Q306 552 231 631Q182 683 165 716Q148 748 148 785V800H357V900H39Z" },
  "3": { w: 400, d: "M33 736V679H137V741Q137 810 194 810Q222 810 236 792Q251 775 251 731V674Q251 626 234 606Q217 585 179 585H142V485H182Q215 485 232 468Q248 451 248 411V360Q248 324 233 307Q218 290 193 290Q140 290 140 355V401H36V364Q36 280 78 235Q119 190 197 190Q276 190 317 234Q358 279 358 363V388Q358 445 339 480Q320 514 280 529V531Q323 547 342 583Q361 619 361 675V737Q361 821 320 866Q278 910 197 910Q116 910 74 865Q33 820 33 736Z" },
  "4": { w: 400, d: "M225 773H15V673L215 200H335V673H387V773H335V900H225ZM225 673V400H223L115 673Z" },
  "5": { w: 400, d: "M38 734V679H142V742Q142 810 199 810Q256 810 256 742V585Q256 516 199 516Q142 516 142 585V591H38L58 200H348V300H156L147 467H149Q180 416 244 416Q304 416 335 457Q366 498 366 576V734Q366 819 324 864Q282 910 202 910Q122 910 80 864Q38 819 38 734Z" },
  "6": { w: 400, d: "M36 734V372Q36 190 204 190Q284 190 326 236Q368 281 368 366V379H264V359Q264 290 207 290Q176 290 161 309Q146 328 146 376V510H148Q177 449 248 449Q308 449 339 490Q370 531 370 609V734Q370 818 327 864Q284 910 203 910Q122 910 79 864Q36 818 36 734ZM260 742V618Q260 549 203 549Q146 549 146 618V742Q146 810 203 810Q260 810 260 742Z" },
  "7": { w: 400, d: "M256 300H34V200H364V296L192 900H80Z" },
  "8": { w: 400, d: "M28 737V675Q28 623 45 588Q62 552 100 532V530Q65 511 48 478Q32 444 32 392V363Q32 279 76 234Q119 190 200 190Q281 190 324 234Q368 279 368 363V392Q368 492 300 530V532Q338 552 355 588Q372 623 372 675V737Q372 821 328 866Q283 910 200 910Q117 910 72 866Q28 821 28 737ZM258 415V360Q258 290 200 290Q142 290 142 360V415Q142 485 200 485Q258 485 258 415ZM262 731V664Q262 585 200 585Q138 585 138 664V731Q138 810 200 810Q262 810 262 731Z" },
  "9": { w: 400, d: "M32 734V721H136V741Q136 810 193 810Q224 810 239 791Q254 772 254 724V590H252Q223 651 152 651Q92 651 61 610Q30 569 30 491V366Q30 282 73 236Q116 190 197 190Q278 190 321 236Q364 282 364 366V728Q364 910 196 910Q116 910 74 864Q32 819 32 734ZM254 482V358Q254 290 197 290Q140 290 140 358V482Q140 551 197 551Q254 551 254 482Z" },
  " ": { w: 160, d: "" },
  "%": { w: 589, d: "M35 477V302Q35 248 62 219Q89 190 141 190Q193 190 220 219Q247 248 247 302V477Q247 531 220 560Q193 589 141 589Q89 589 62 560Q35 531 35 477ZM395 200H465L194 900H124ZM177 482V297Q177 253 141 253Q105 253 105 297V482Q105 526 141 526Q177 526 177 482ZM342 798V623Q342 569 369 540Q396 511 448 511Q500 511 527 540Q554 569 554 623V798Q554 852 527 881Q500 910 448 910Q396 910 369 881Q342 852 342 798ZM484 803V618Q484 574 448 574Q412 574 412 618V803Q412 847 448 847Q484 847 484 803Z" },
};

function Poster({ text, className, em = 0.9, track = 0 }: { text: string; className?: string | undefined; em?: number; track?: number }) {
  const gap = track * POSTER_EM;
  let x = 0;
  const runs = [...text].map((ch, index) => {
    const glyph = POSTER[ch] ?? { w: 400, d: "" };
    const run = { index, d: glyph.d, x, w: glyph.w };
    x += glyph.w + (index === text.length - 1 ? 0 : gap);
    return run;
  });
  const width = Math.max(1, x);
  return (
    <svg className={className ? `gx-poster ${className}` : "gx-poster"} viewBox={`0 0 ${width} ${POSTER_EM}`} aria-hidden="true" style={{ height: `${em}em`, width: `${(width / POSTER_EM) * em}em` }}>
      {runs.map((run) => run.d ? <path key={run.index} d={run.d} transform={`translate(${run.x} 0)`} fill="currentColor" /> : null)}
    </svg>
  );
}

function paintPoster(ctx: CanvasRenderingContext2D, text: string, x: number, y: number, size: number, mode: "fill" | "stroke") {
  let units = 0;
  for (const ch of text) units += POSTER[ch]?.w ?? 0;
  const scale = size / POSTER_EM;
  ctx.save();
  ctx.translate(x - (units * scale) / 2, y - size / 2);
  ctx.scale(scale, scale);
  let pen = 0;
  for (const ch of text) {
    const glyph = POSTER[ch];
    if (!glyph) continue;
    if (glyph.d) {
      ctx.save();
      ctx.translate(pen, 0);
      const path = new Path2D(glyph.d);
      if (mode === "fill") ctx.fill(path);
      else ctx.stroke(path);
      ctx.restore();
    }
    pen += glyph.w;
  }
  ctx.restore();
}

function AntLogo({ size = "md" }: { size?: "sm" | "md" | "lg" }) {
  const textClass = size === "sm" ? "text-sm" : size === "lg" ? "text-3xl" : "text-xl";
  return (
    <span className={`gx-logo-lock ${textClass}`} role="img" aria-label="ANTAGENT">
      <AntMark />
      <AntWordmark />
    </span>
  );
}

let pendingSweep = false;

const LOOK = `
.gx-app {
  --background: oklch(0.955 0.014 82);
  --background-deep: oklch(0.918 0.018 78);
  --foreground: oklch(0.19 0.01 58);
  --card: oklch(0.985 0.008 82);
  --primary: oklch(0.60 0.145 38);
  --primary-foreground: oklch(0.985 0.008 82);
  --secondary: oklch(0.905 0.016 78);
  --muted: oklch(0.895 0.016 78);
  --muted-foreground: oklch(0.47 0.018 65);
  --border: oklch(0.22 0.014 60 / 14%);
  --gold: oklch(0.66 0.12 68);
  --font-display: "Fraunces", "Noto Serif SC", Georgia, serif;
  --font-sans: "DM Sans", "Noto Sans SC", ui-sans-serif, system-ui, sans-serif;
  --font-poster: "Fraunces", "Noto Serif SC", Georgia, serif;
  --font-mono: "IBM Plex Mono", ui-monospace, monospace;
  --ease-cine: cubic-bezier(0.16, 1, 0.3, 1);
  --shadow-pop: 0 28px 60px -28px oklch(0.2 0.02 55 / 0.24);
  position: relative; height: 100vh; overflow: hidden;
  background: var(--background); color: var(--foreground);
  font-family: var(--font-sans); letter-spacing: 0;
}
.gx-app button { font: inherit; color: inherit; background: none; border: 0; cursor: pointer; }
.gx-app button:disabled { cursor: not-allowed; opacity: .45; }
.gx-scroll { position: relative; z-index: 1; height: 100%; overflow: auto; }
.gx-pri { color: var(--primary); }
.gx-muted { color: var(--muted-foreground); }
.gx-mono { font-family: var(--font-mono); }
.gx-display { font-family: var(--font-display); font-weight: 600; letter-spacing: -0.02em; line-height: 1; }
.gx-poster { display: inline-block; overflow: visible; vertical-align: -0.06em; }
.gx-fill { background: var(--primary); color: var(--primary-foreground); }
.gx-soft { background: var(--muted); }
.gx-line { border-color: var(--border); }
.gx-header { position: sticky; top: 0; z-index: 30; border-bottom: 1px solid var(--border); background: color-mix(in oklab, var(--background) 88%, transparent); backdrop-filter: blur(14px); }
.gx-band { border-block: 1px solid var(--border); background: var(--background-deep); }
.gx-footer { border-top: 1px solid var(--border); background: var(--background); }
.gx-container { width: min(1160px, calc(100% - 72px)); margin-inline: auto; }

/* ANTAGENT wordmark artwork is rendered by .gx-logo in the global stylesheet. */

.gx-kicker { font: 500 11px/1 var(--font-mono); letter-spacing: .12em; text-transform: uppercase; color: var(--primary); }

/* Editorial Masthead + Specimen Workbench (Award-grade Architectural Layout) */
.ant-hero { position: relative; padding-block: 36px 56px; --hp: 0; }
.ant-masthead { display: grid; grid-template-columns: minmax(0, 1.35fr) minmax(260px, 0.65fr); gap: 36px; align-items: end; padding-bottom: 32px; border-bottom: 1px solid color-mix(in oklab, var(--foreground) 16%, transparent); }
.ant-hero-pill { display: inline-flex; align-items: center; gap: 8px; padding: 6px 12px; border-radius: 999px; border: 1px solid var(--border); background: var(--card); font: 500 11px/1 var(--font-mono); letter-spacing: .1em; color: var(--muted-foreground); }
.ant-hero-tagline { margin-top: 16px; font-family: var(--font-display); font-style: italic; font-size: 15px; letter-spacing: .02em; color: var(--primary); }
.ant-hero-headline { margin-top: 10px; font-family: var(--font-display); font-size: clamp(2.2rem, 3.9vw, 3.65rem); font-weight: 600; line-height: 1.12; letter-spacing: -0.026em; color: var(--foreground); }
.ant-hero-headline em { display: block; font-style: italic; font-weight: 500; color: var(--primary); }
.ant-masthead-side { display: flex; flex-direction: column; justify-content: flex-end; gap: 18px; padding-left: 28px; border-left: 1px solid var(--border); }
.ant-masthead-brand { display: flex; flex-wrap: wrap; align-items: baseline; justify-content: space-between; gap: 12px; }
.ant-masthead-word { font-family: var(--font-display); font-size: 1.85rem; font-weight: 600; letter-spacing: -0.03em; line-height: 1; }
.ant-masthead-word .gx-logo-lock { gap: .26em; }
.ant-hero-sub { font-size: 14px; line-height: 1.7; color: var(--muted-foreground); }
.ant-masthead-actions { display: flex; flex-wrap: wrap; gap: 10px; }

/* Specimen Workbench — Unified Warm Sand Gallery Stage */
.ant-workbench { margin-top: 32px; display: grid; grid-template-columns: minmax(320px, 1.02fr) minmax(0, 0.98fr); border: 1px solid var(--border); border-radius: 28px; background: var(--card); overflow: hidden; box-shadow: 0 26px 60px -42px oklch(0.2 0.03 50 / 0.24); }
.ant-stage-pane { position: relative; display: flex; flex-direction: column; justify-content: space-between; padding: 28px 32px 26px; background: radial-gradient(circle at 50% 42%, color-mix(in oklab, var(--primary) 10%, var(--background-deep)) 0%, var(--background-deep) 74%); border-right: 1px solid var(--border); }
.ant-stage-pane::before { content: ""; position: absolute; inset: 14px; border-radius: 18px; border: 1px dashed color-mix(in oklab, var(--foreground) 10%, transparent); pointer-events: none; }
.ant-stage-head { position: relative; z-index: 1; display: flex; align-items: center; justify-content: space-between; gap: 12px; }
.ant-stage-meta { position: relative; z-index: 1; margin-top: 18px; padding-top: 16px; border-top: 1px solid color-mix(in oklab, var(--foreground) 10%, transparent); }
.ant-stage-dial { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-top: 12px; }
.ant-stage-specs { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 12px; }
.ant-spec-pill { display: inline-flex; align-items: center; gap: 6px; padding: 4px 10px; border-radius: 999px; border: 1px solid var(--border); background: color-mix(in oklab, var(--card) 82%, transparent); font: 500 11px/1.2 var(--font-mono); color: var(--muted-foreground); }
.ant-spec-pill strong { color: var(--foreground); font-weight: 600; }

.ant-console-pane { display: flex; flex-direction: column; justify-content: flex-start; gap: 22px; padding: 30px 32px; background: var(--card); }
.ant-fair-facts { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 10px; padding: 14px 0; border-top: 1px solid var(--border); border-bottom: 1px solid var(--border); }
.ant-fair-fact dt { font: 500 10px/1.2 var(--font-mono); letter-spacing: .08em; text-transform: uppercase; color: var(--muted-foreground); }
.ant-fair-fact dd { margin-top: 6px; font-family: var(--font-display); font-size: 1.15rem; font-weight: 600; color: var(--foreground); }
.ant-fair-head { display: flex; align-items: baseline; justify-content: space-between; gap: 12px; padding-bottom: 14px; border-bottom: 1px solid var(--border); }
.ant-fair-title { font-family: var(--font-display); font-size: 22px; font-weight: 600; letter-spacing: -0.015em; }
.ant-fair-body { margin-top: 14px; font-size: 14px; line-height: 1.8; color: var(--muted-foreground); }
.ant-console-cmd { margin-top: auto; }
.ant-console-cmd .gx-term { background: var(--background); border-color: color-mix(in oklab, var(--foreground) 12%, transparent); }

/* Architectural Ledger Band */
.ant-ledger-shell { border: 1px solid var(--border); border-radius: 26px; background: var(--card); overflow: hidden; box-shadow: 0 18px 44px -34px oklch(0.2 0.03 50 / 0.18); }
.ant-ledger-top { display: grid; grid-template-columns: minmax(220px, 0.72fr) minmax(0, 1.28fr); border-bottom: 1px solid var(--border); }
.ant-ledger-hero { display: flex; flex-direction: column; justify-content: space-between; padding: 30px 32px; background: linear-gradient(155deg, color-mix(in oklab, var(--primary) 9%, var(--card)) 0%, var(--card) 72%); border-right: 1px solid var(--border); }
.ant-ledger-pct { font-family: var(--font-display); font-size: clamp(3.1rem, 5.2vw, 4.6rem); font-weight: 600; line-height: .98; letter-spacing: -0.035em; color: var(--primary); }
.ant-ruler-ticks { display: flex; justify-content: space-between; margin-top: 8px; font: 500 10px var(--font-mono); color: var(--muted-foreground); opacity: .75; }
.ant-ledger-cols { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); }
.ant-ledger-cell { padding: 24px 28px; border-bottom: 1px solid var(--border); border-right: 1px solid var(--border); transition: background .25s; }
.ant-ledger-cell:hover { background: color-mix(in oklab, var(--background-deep) 45%, transparent); }
.ant-ledger-cell:nth-child(2n) { border-right: 0; }
.ant-ledger-cell:nth-last-child(-n+2) { border-bottom: 0; }
.ant-ledger-num { margin-top: 10px; font-family: var(--font-display); font-size: clamp(1.7rem, 2.5vw, 2.25rem); font-weight: 600; letter-spacing: -0.02em; line-height: 1.08; color: var(--foreground); }
.ant-ledger-foot { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); background: var(--background-deep); }
.ant-ledger-metric { padding: 18px 24px; border-right: 1px solid var(--border); }
.ant-ledger-metric:last-child { border-right: 0; }
.ant-ledger-metric-val { margin-top: 8px; font-family: var(--font-display); font-size: 1.55rem; font-weight: 600; line-height: 1.1; color: var(--foreground); }
.ant-ledger-metric-val span { margin-left: 6px; font: 500 11px var(--font-mono); color: var(--muted-foreground); }

/* Horizontal Editorial Timeline Deck */
.ant-timeline-rail { margin-top: 28px; display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 10px; }
.gx-app .ant-step-tab { position: relative; display: flex; flex-direction: column; gap: 6px; padding: 16px 18px; border: 1px solid var(--border); border-radius: 16px; background: var(--card); text-align: left; color: var(--muted-foreground); cursor: pointer; transition: border-color .25s, transform .3s var(--ease-cine), box-shadow .3s, color .25s, background .25s; }
.gx-app .ant-step-tab:hover { color: var(--foreground); border-color: color-mix(in oklab, var(--primary) 50%, var(--border)); transform: translateY(-2px); }
.gx-app .ant-step-tab-active { color: var(--foreground); border-color: var(--primary); background: linear-gradient(160deg, color-mix(in oklab, var(--primary) 10%, var(--card)) 0%, var(--card) 80%); box-shadow: 0 12px 28px -20px oklch(0.2 0.04 45 / 0.26); }
.ant-step-tab-active::after { content: ""; position: absolute; left: 18px; right: 18px; bottom: 0; height: 2px; border-radius: 2px; background: var(--primary); }
.ant-timeline-stage { margin-top: 16px; display: grid; grid-template-columns: minmax(0, 1.25fr) minmax(240px, 0.75fr); gap: 36px; align-items: center; padding: 36px 40px; border: 1px solid var(--border); border-radius: 26px; background: var(--card); box-shadow: 0 20px 50px -38px oklch(0.2 0.03 50 / 0.22); }
.ant-stage-watermark { font-family: var(--font-display); font-size: clamp(3.4rem, 6vw, 5.2rem); font-weight: 600; line-height: .9; letter-spacing: -0.04em; color: color-mix(in oklab, var(--primary) 20%, transparent); }
.ant-stage-visual { position: relative; aspect-ratio: 4 / 3; border-radius: 18px; overflow: hidden; border: 1px solid var(--border); background: #1C1916; box-shadow: 0 18px 36px -24px oklch(0.2 0.03 50 / 0.32); }

/* Unified Specimen Calculator */
.ant-calc-shell { margin-top: 28px; display: grid; grid-template-columns: minmax(0, 0.96fr) minmax(0, 1.04fr); border: 1px solid var(--border); border-radius: 26px; background: var(--card); overflow: hidden; box-shadow: 0 20px 48px -36px oklch(0.2 0.03 50 / 0.2); }
.ant-calc-left { padding: 32px 34px; border-right: 1px solid var(--border); display: flex; flex-direction: column; justify-content: space-between; }
.ant-calc-right { padding: 32px 34px; background: linear-gradient(180deg, color-mix(in oklab, var(--background-deep) 55%, var(--card)) 0%, var(--card) 100%); display: flex; flex-direction: column; justify-content: space-between; }
.ant-quick-counts { display: flex; flex-wrap: wrap; gap: 6px; }
.ant-quick-counts button { height: 30px; min-width: 40px; padding: 0 11px; border: 1px solid var(--border); border-radius: 999px; background: var(--background); color: var(--muted-foreground); font: 600 12px var(--font-mono); cursor: pointer; transition: all .2s; }
.ant-quick-counts button[aria-pressed="true"] { border-color: var(--primary); background: var(--primary); color: var(--primary-foreground); }
.ant-curve-box { margin-top: 20px; padding: 18px 18px 10px; border: 1px solid var(--border); border-radius: 18px; background: var(--card); }

.gx-char { display: inline-block; opacity: 0; animation: gx-char-in .65s var(--ease-cine) forwards; }
@keyframes gx-char-in { from { opacity: 0; transform: translateY(.22em); } to { opacity: 1; transform: none; } }
.gx-parallax { transform: translateY(calc(var(--par, 0px) * -0.45)); }
.gx-rise { opacity: .2; transform: translateY(14px); transition: opacity .75s var(--ease-cine), transform .85s var(--ease-cine); }
.gx-rise.gx-in { opacity: 1; transform: none; }
.gx-chapter { padding-block: 68px; }
.gx-chapter-heading { position: relative; display: flex; flex-wrap: wrap; align-items: baseline; justify-content: space-between; gap: 16px; padding-bottom: 18px; border-bottom: 1px solid var(--border); }
.gx-chapter-heading h2 { font: 600 32px/1.2 var(--font-display); letter-spacing: -0.02em; }
.gx-chapter-note { font-size: 13px; color: var(--muted-foreground); }
.gx-exhibit-caption { display: flex; justify-content: space-between; padding: 14px 0; font: 10px var(--font-mono); color: var(--muted-foreground); border-bottom: 1px solid var(--border); }
.gx-mint-mark { border-radius: 6px; border: 1px solid var(--border); background: var(--background); transition: background .3s, border-color .3s, transform .35s var(--ease-cine); }
.gx-mint-mark-active { background: var(--primary); border-color: var(--primary); transform: translateY(-3px); }
.gx-swap { animation: gx-swap .45s var(--ease-cine); }
@keyframes gx-swap { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: none; } }
.gx-live-dot { width: 8px; height: 8px; border-radius: 999px; background: var(--primary); box-shadow: 0 0 0 0 color-mix(in oklab, var(--primary) 50%, transparent); animation: gx-live-pulse 2.2s ease-out infinite; }
@keyframes gx-live-pulse { to { box-shadow: 0 0 0 9px transparent; } }
.gx-live-bar { transform-origin: left; animation: gx-live-grow 1.2s var(--ease-cine) both; }
@keyframes gx-live-grow { from { transform: scaleX(0); } }

/* Navigation — same 8 tabs, warm editorial styling */
.gx-app .ac-tab { position: relative; height: 40px; padding: 0 2px; border: 0; background: transparent; color: var(--muted-foreground); font-size: 14px; font-weight: 500; white-space: nowrap; cursor: pointer; transition: color .2s; }
.gx-app .ac-tab:hover, .gx-app .ac-tab-active { color: var(--foreground); }
.ac-tab-active::after { content: ""; position: absolute; left: 50%; bottom: 3px; width: 18px; height: 2px; border-radius: 2px; background: var(--primary); transform: translateX(-50%); animation: ant-tab-pop .38s var(--ease-cine) both; }
@keyframes ant-tab-pop { from { transform: translateX(-50%) scaleX(0); opacity: 0; } to { transform: translateX(-50%) scaleX(1); opacity: 1; } }
.gx-x { display: inline-flex; align-items: center; justify-content: center; width: 38px; height: 38px; border-radius: 999px; border: 1px solid var(--border); background: var(--card); color: var(--foreground); transition: border-color .2s, color .2s, transform .2s; }
.gx-x svg { width: 15px; height: 15px; fill: currentColor; }
.gx-x:hover { color: var(--primary); border-color: var(--primary); transform: translateY(-1px); }
.gx-lang { display: inline-flex; align-items: center; height: 38px; padding: 3px; border-radius: 999px; border: 1px solid var(--border); background: var(--background-deep); }
.gx-lang button { height: 30px; min-width: 48px; padding: 0 12px; border: 0; border-radius: 999px; background: transparent; color: var(--muted-foreground); font: 600 13px/1 var(--font-sans); cursor: pointer; transition: background .2s, color .2s; }
.gx-lang button[aria-pressed="true"] { color: var(--primary-foreground); background: var(--foreground); }
.gx-menu { display: inline-flex; align-items: center; height: 34px; padding: 0 14px; border: 1px solid var(--border); border-radius: 999px; background: var(--card); color: var(--foreground); font: 500 11px var(--font-mono); letter-spacing: .12em; cursor: pointer; }
.gx-menu[aria-expanded="true"] { color: var(--primary); border-color: var(--primary); }
.gx-fold { border-top: 1px solid var(--border); background: var(--card); }
.gx-fold button { display: flex; align-items: center; gap: 16px; width: 100%; height: 48px; border: 0; border-bottom: 1px solid var(--border); background: transparent; color: var(--muted-foreground); text-align: left; cursor: pointer; }
.gx-fold button[aria-pressed="true"] { color: var(--foreground); }
.gx-fold-no { width: 1.6em; font: 11px var(--font-mono); color: var(--primary); }

/* Buttons & Inputs */
.gx-btn { display: inline-flex; align-items: center; justify-content: center; gap: 8px; height: 36px; padding: 0 14px; border-radius: 999px; font-weight: 600; transition: background .2s, border-color .2s, transform .2s; }
.gx-btn:active { transform: scale(.98); }
.gx-btn-lg { height: 42px; width: 100%; padding: 0 18px; justify-content: center; }
.gx-btn-split { justify-content: space-between; }
.gx-app input[type="range"] { width: 100%; height: 6px; border-radius: 999px; appearance: none; background: linear-gradient(90deg, var(--primary) var(--fill, 0%), color-mix(in oklab, var(--foreground) 14%, transparent) var(--fill, 0%)); accent-color: var(--primary); cursor: pointer; }
.gx-app input[type="range"]::-webkit-slider-thumb { appearance: none; width: 18px; height: 18px; border-radius: 999px; border: 2px solid var(--primary); background: var(--card); box-shadow: 0 2px 6px oklch(0.2 0.02 55 / 0.2); }
.gx-app input[type="range"]::-moz-range-thumb { width: 18px; height: 18px; border: 2px solid var(--primary); border-radius: 999px; background: var(--card); }
.gx-app .gx-btn-solid { background: var(--primary); color: var(--primary-foreground); border: 1px solid var(--primary); }
.gx-app .gx-btn-solid:hover { background: color-mix(in oklab, var(--primary) 88%, var(--foreground)); border-color: color-mix(in oklab, var(--primary) 88%, var(--foreground)); }
.gx-btn-outline { border: 1px solid var(--border); }
.gx-app .gx-btn-outline { border: 1px solid var(--border); background: var(--card); color: var(--foreground); }
.gx-app .gx-btn-outline:hover { border-color: var(--primary); color: var(--primary); }
.gx-app button.gx-pri { color: var(--primary); }
.gx-app .gx-btn-on { background: var(--primary); color: var(--primary-foreground); }
.gx-seg { display: inline-flex; gap: 4px; padding: 4px; border: 1px solid var(--border); border-radius: 999px; background: var(--background); }
.gx-app .gx-seg button { height: 36px; min-width: 88px; padding: 0 16px; border: 1px solid transparent; border-radius: 999px; background: transparent; color: var(--muted-foreground); font: 600 14px/1 var(--font-sans); }
.gx-app .gx-seg button[aria-pressed="true"] { background: var(--foreground); color: var(--card); }
.gx-count { display: grid; grid-template-columns: repeat(10, minmax(0, 1fr)); gap: 4px; }
.gx-count button { height: 32px; border: 1px solid var(--border); border-radius: 8px; background: var(--background); color: var(--muted-foreground); font: 600 12px var(--font-mono); cursor: pointer; }
.gx-count button[aria-pressed="true"] { color: var(--primary-foreground); border-color: var(--primary); background: var(--primary); }
.gx-chip { border: 1px solid var(--border); border-radius: 999px; background: var(--card); padding: 4px 10px; font: 500 11px var(--font-mono); color: var(--muted-foreground); }
.gx-track { height: 8px; overflow: hidden; border-radius: 999px; background: var(--muted); }
.gx-track > div { height: 100%; border-radius: 999px; background: var(--primary); }

/* Framed Collectible Card — Warm Parchment Mat + Charcoal Print */
.hc-stage { display: grid; place-items: center; padding: 1.25rem .5rem; background: transparent; }
.hc-scene { position: relative; perspective: 1100px; width: min(306px, 78vw); }
.hc-shadow { position: absolute; inset: 14% 10% -6%; border-radius: 26px; background: oklch(0.2 0.03 50 / 0.22); filter: blur(28px); opacity: .7; }
.hc-card { --rx: 0deg; --ry: 0deg; --mx: 50%; --my: 30%; position: relative; aspect-ratio: 5 / 7; border-radius: 22px; padding: 8px; background: var(--card); border: 1px solid color-mix(in oklab, var(--foreground) 14%, transparent); transform: rotateX(var(--rx)) rotateY(var(--ry)); transform-style: preserve-3d; transition: transform .55s var(--ease-cine); box-shadow: 0 22px 46px -22px oklch(0.2 0.03 50 / 0.28); animation: hc-float 7s ease-in-out infinite; }
.hc-card[data-active="true"] { transition: transform .08s linear; animation-play-state: paused; }
.hc-inner { position: relative; height: 100%; border-radius: 15px; background: var(--card); display: flex; flex-direction: column; overflow: hidden; border: 1px solid color-mix(in oklab, var(--foreground) 10%, transparent); }
.hc-head, .hc-foot { display: flex; justify-content: space-between; align-items: center; padding: .7rem .85rem; }
.hc-tier { font-family: var(--font-mono); font-size: .62rem; letter-spacing: .16em; color: var(--primary); border: 1px solid color-mix(in oklab, var(--primary) 45%, transparent); background: color-mix(in oklab, var(--primary) 8%, var(--card)); padding: .18rem .5rem; border-radius: 999px; }
.hc-art { position: relative; flex: 1; margin: 0 .65rem; border-radius: 11px; overflow: hidden; border: 1px solid color-mix(in oklab, var(--foreground) 14%, transparent); background: #1C1916; }
.hc-art canvas, .ant-story-art canvas, .gx-page-art canvas { display: block; width: 100%; height: 100%; }
.hc-label { font-family: var(--font-mono); font-size: .56rem; letter-spacing: .16em; color: var(--muted-foreground); }
.hc-serial { font-family: var(--font-display); font-size: 1.45rem; font-weight: 600; line-height: 1.05; color: var(--foreground); }
.hc-edition { font-family: var(--font-mono); font-size: .9rem; font-weight: 600; line-height: 1.2; color: var(--primary); text-align: right; }
.hc-foil, .hc-glare { position: absolute; inset: 0; border-radius: 22px; pointer-events: none; }
.hc-foil { opacity: .14; background: linear-gradient(120deg, transparent 25%, color-mix(in oklab, var(--primary) 26%, transparent) 46%, oklch(1 0 0 / 0.35) 52%, transparent 68%); background-size: 280% 280%; background-position: var(--mx) var(--my); animation: hc-foil 10s linear infinite; }
.hc-card[data-active="true"] .hc-foil { opacity: .24; animation: none; }
.hc-glare { background: radial-gradient(circle at var(--mx) var(--my), oklch(1 0 0 / 0.45), transparent 46%); opacity: 0; transition: opacity .35s; }
.hc-card[data-active="true"] .hc-glare { opacity: .35; }
@keyframes hc-float { 0%,100% { transform: rotateX(2.5deg) rotateY(-4deg) translateY(0); } 50% { transform: rotateX(-2deg) rotateY(4deg) translateY(-6px); } }
@keyframes hc-foil { to { background-position: 280% 0; } }

/* Inner Pages — Warm Paper Surfaces */
.gx-page-hero { display: grid; grid-template-columns: minmax(0, 1.45fr) minmax(0, 1fr); gap: 44px; align-items: end; padding-block: 48px 28px; }
.gx-page-title { font-family: var(--font-display); font-size: clamp(2.8rem, 5.2vw, 4.4rem); line-height: 1.02; font-weight: 600; letter-spacing: -0.02em; }
.gx-page-art { position: relative; aspect-ratio: 4 / 3; border: 1px solid var(--border); border-radius: 18px; overflow: hidden; background: #1C1916; }
.gx-page-index { position: absolute; right: 14px; bottom: 8px; font: 500 52px var(--font-mono); color: color-mix(in oklab, var(--primary) 85%, #F4EFE6); line-height: 1; }
.gx-app ::selection { background: var(--primary); color: var(--primary-foreground); }
.gx-panel, .gx-tiles > div, .gx-rule, .gx-term, .gx-alloc { position: relative; overflow: hidden; border: 1px solid var(--border); border-radius: 18px; background: var(--card); transition: border-color .3s, box-shadow .3s, transform .35s var(--ease-cine); }
.gx-panel:hover, .gx-rule:hover, .gx-term:hover, .gx-tiles > div:hover, .gx-alloc:hover { border-color: color-mix(in oklab, var(--primary) 60%, var(--border)); box-shadow: 0 14px 32px -22px oklch(0.2 0.03 50 / 0.18); }
.gx-tiles > div:hover, .gx-term:hover, .gx-panel:hover { transform: translateY(-2px); }
.gx-tiles > div > *, .gx-panel > * { position: relative; z-index: 1; }
.gx-tiles { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 14px; }
.gx-tiles > div { padding: 20px 22px; }
.gx-rule { position: relative; overflow: hidden; padding: 28px; }
.gx-rule-no { position: absolute; top: -12px; right: 16px; font-family: var(--font-display); font-size: 6rem; font-weight: 600; line-height: 1; color: color-mix(in oklab, var(--primary) 12%, transparent); pointer-events: none; }
.gx-term { position: relative; display: flex; flex-direction: column; padding: 40px 22px 22px; }
.gx-term::before { content: ""; position: absolute; top: 18px; left: 22px; width: 8px; height: 8px; border-radius: 50%; background: var(--primary); box-shadow: 14px 0 0 color-mix(in oklab, var(--foreground) 16%, transparent), 28px 0 0 color-mix(in oklab, var(--foreground) 16%, transparent); }
.gx-term-fn { margin-top: 10px; padding: 8px 12px; border-radius: 10px; border: 1px solid var(--border); background: var(--background); font-size: 11px; color: var(--primary); word-break: break-all; }
.gx-cmd-group { margin-bottom: 48px; }
.gx-cmd-label { display: flex; align-items: center; gap: 14px; margin-bottom: 18px; font-family: var(--font-display); font-size: 1.45rem; font-weight: 600; }
.gx-cmd-label::after { content: ""; flex: 1; height: 1px; background: linear-gradient(90deg, color-mix(in oklab, var(--primary) 55%, transparent), transparent); }
.gx-field { height: 40px; width: 100%; max-width: 32rem; border: 1px solid var(--border); border-radius: 10px; background: var(--background); padding: 0 12px; color: var(--foreground); font: 12px var(--font-mono); }
.gx-alert { color: oklch(0.54 0.18 25); }
.gx-alloc { display: flex; width: 100%; align-items: center; gap: 14px; padding: 14px 16px; color: inherit; font: inherit; text-align: left; cursor: pointer; transition: border-color .3s, transform .3s; }
.gx-alloc-active, .gx-alloc:hover { border-color: var(--primary); transform: translateX(6px); }
.gx-dot { width: 12px; height: 12px; flex: none; border-radius: 999px; background: var(--primary); }
.gx-chip-pri { border-color: color-mix(in oklab, var(--primary) 40%, transparent); background: color-mix(in oklab, var(--primary) 10%, var(--card)); color: var(--primary); border-radius: 999px; }
.gx-token-layout { display: grid; align-items: center; gap: 40px; }
.gx-donut-wrap { position: relative; width: 100%; max-width: 420px; margin-inline: auto; }
.gx-donut { width: 100%; display: block; transform: rotate(-90deg); }
.gx-donut-lock { position: absolute; z-index: 2; color: var(--primary); font-size: 12px; font-weight: 700; line-height: 1; pointer-events: none; transform: translate(-50%, -50%); }
.gx-donut-center { position: absolute; inset: 0; display: grid; place-content: center; text-align: center; pointer-events: none; }
.gx-callout { border-left: 3px solid var(--primary); border-radius: 0 12px 12px 0; background: color-mix(in oklab, var(--primary) 10%, var(--card)); padding: 12px 16px; color: var(--foreground); font-size: .875rem; font-weight: 500; line-height: 1.75rem; }
.gx-vest { flex: 1; min-width: 0; border-radius: 3px 3px 0 0; transition: height .45s, background-color .35s; }
.gx-vest-on { background: var(--primary); }
.gx-vest-off { background: var(--muted); }
@media (min-width: 760px) { .gx-token-layout { grid-template-columns: minmax(220px, 42%) minmax(0, 1fr); } }
.gx-reading-progress { position: absolute; bottom: -1px; left: 0; height: 2px; width: 100%; background: var(--primary); transform: scaleX(0); transform-origin: left; }

/* ANTAGENT route sweep — a single ink line draws, then tears open into the next page */
.ant-sweep { position: absolute; inset: 0; z-index: 70; pointer-events: none; overflow: hidden; animation: ant-sweep-gone 0s linear 1.22s forwards; }
.ant-sweep-panel { position: absolute; left: 0; right: 0; height: 50.2%; background: var(--background); }
.ant-sweep-panel::after { content: ""; position: absolute; left: 0; right: 0; height: 1px; background: linear-gradient(90deg, transparent, color-mix(in oklab, var(--primary) 70%, transparent) 20%, var(--primary) 50%, color-mix(in oklab, var(--primary) 70%, transparent) 80%, transparent); opacity: 0; animation: ant-seam-on .01s linear .5s forwards, ant-seam-off .5s ease .82s forwards; }
.ant-sweep-top { top: 0; animation: ant-tear-up .7s cubic-bezier(0.76, 0, 0.18, 1) .5s forwards; }
.ant-sweep-top::after { bottom: 0; }
.ant-sweep-bottom { bottom: 0; animation: ant-tear-down .7s cubic-bezier(0.76, 0, 0.18, 1) .5s forwards; }
.ant-sweep-bottom::after { top: 0; }
.ant-sweep-line { position: absolute; top: 50%; left: 10%; right: 10%; height: 1px; margin-top: -.5px; background: linear-gradient(90deg, transparent, var(--primary) 18%, var(--foreground) 50%, var(--primary) 82%, transparent); box-shadow: 0 0 14px color-mix(in oklab, var(--primary) 60%, transparent); transform: scaleX(0); animation: ant-line-draw .48s cubic-bezier(0.65, 0, 0.35, 1) forwards, ant-fade-out .14s linear .48s forwards; }
.ant-sweep-spark { position: absolute; top: 50%; left: 50%; width: 120px; height: 3px; margin: -1.5px 0 0 -60px; border-radius: 3px; background: radial-gradient(ellipse at center, var(--card) 0%, var(--primary) 40%, transparent 72%); filter: blur(.5px); animation: ant-spark .48s cubic-bezier(0.65, 0, 0.35, 1) forwards; }
.ant-sweep-brand { position: absolute; left: 50%; top: 50%; transform: translate(-50%, calc(-100% - 20px)); font-size: clamp(28px, 4.2vw, 48px); white-space: nowrap; opacity: 0; animation: ant-brand-in .4s var(--ease-cine) .06s forwards, ant-fade-out .18s ease .46s forwards; }
.ant-sweep-brand .gx-logo-lock { gap: .32em; }
@media (max-width: 479px) { .gx-header .gx-logo-lock { font-size: 16px; } .ant-sweep-brand { font-size: 28px; } }
.ant-sweep-brand .gx-logo-mark { animation: ant-orbit-spin .52s var(--ease-cine) .06s both; }
.ant-sweep-tag { position: absolute; left: 50%; top: 50%; transform: translate(-50%, 18px); font-family: var(--font-display); font-style: italic; font-size: clamp(13px, 1.5vw, 17px); letter-spacing: .03em; color: var(--primary); white-space: nowrap; opacity: 0; animation: ant-brand-in .4s var(--ease-cine) .12s forwards, ant-fade-out .18s ease .46s forwards; }
.gx-app .gx-menu, .gx-app .gx-lang button { white-space: nowrap; }
@media (max-width: 479px) { .gx-header .gx-container { gap: 10px; } .gx-header .gx-container > div { gap: 6px; } .gx-app .gx-x { width: 32px; height: 32px; } .gx-app .gx-menu { padding: 0 10px; } .gx-app .gx-lang button { padding-inline: 8px; } }
@keyframes ant-line-draw { to { transform: scaleX(1); } }
@keyframes ant-spark { 0% { transform: translateX(-42vw) scaleX(.4); opacity: 0; } 15% { opacity: 1; } 100% { transform: translateX(42vw) scaleX(1); opacity: 0; } }
@keyframes ant-brand-in { from { opacity: 0; filter: blur(10px); transform: translate(-50%, calc(-100% - 10px)) scale(.95); } to { opacity: 1; filter: blur(0); transform: translate(-50%, calc(-100% - 20px)) scale(1); } }
@keyframes ant-orbit-spin { from { transform: rotate(-42deg) scale(.88); } to { transform: rotate(0deg) scale(1); } }
@keyframes ant-fade-out { to { opacity: 0; } }
@keyframes ant-seam-on { to { opacity: 1; } }
@keyframes ant-seam-off { to { opacity: 0; } }
@keyframes ant-tear-up { to { transform: translateY(-101%); } }
@keyframes ant-tear-down { to { transform: translateY(101%); } }
@keyframes ant-sweep-gone { to { visibility: hidden; } }

.ant-view-stage { animation: ant-view-enter .38s cubic-bezier(0.22, 1, 0.36, 1) both; will-change: transform, opacity; }
.ant-swept .ant-view-stage { animation: ant-view-emerge .9s cubic-bezier(0.22, 1, 0.36, 1) .48s both; }
@keyframes ant-view-enter {
  from { opacity: 0; transform: translateY(12px); }
  to { opacity: 1; transform: none; }
}
@keyframes ant-view-emerge {
  from { opacity: .35; transform: scale(.985); filter: blur(3px); }
  to { opacity: 1; transform: none; filter: none; }
}
.ant-stagger-1 { animation: ant-stagger-up .36s cubic-bezier(0.22, 1, 0.36, 1) .02s both; }
.ant-stagger-2 { animation: ant-stagger-art .44s cubic-bezier(0.22, 1, 0.36, 1) .06s both; }
.ant-stagger-3 { animation: ant-stagger-up .42s cubic-bezier(0.22, 1, 0.36, 1) .1s both; }
@keyframes ant-stagger-up {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: none; }
}
@keyframes ant-stagger-art {
  from { opacity: 0; transform: translateY(10px) scale(0.975); }
  to { opacity: 1; transform: none; }
}

/* Homepage motion: masked headline lines, drawn ink underline, card spotlight */
.ant-mask { display: block; overflow: hidden; padding-bottom: .08em; margin-bottom: -.08em; }
.ant-mask > span { display: inline-block; transform: translateY(105%); animation: ant-mask-up .9s var(--ease-cine) forwards; }
.ant-mask:nth-child(2) > span { animation-delay: .12s; }
.ant-hero-headline em.ant-mask { padding-bottom: .28em; margin-bottom: -.2em; }
.ant-swept .ant-mask > span { animation-delay: .5s; }
.ant-swept .ant-mask:nth-child(2) > span { animation-delay: .62s; }
@keyframes ant-mask-up { to { transform: none; } }
.ant-ink { position: relative; display: inline-block; }
.ant-ink svg { position: absolute; left: -2%; bottom: -.16em; width: 104%; height: .32em; overflow: visible; color: var(--primary); }
.ant-ink path { fill: none; stroke: currentColor; stroke-width: 2.2; stroke-linecap: round; stroke-dasharray: 420; stroke-dashoffset: 420; animation: ant-ink-draw 1.1s cubic-bezier(0.65, 0, 0.35, 1) .7s forwards; }
.ant-swept .ant-ink path { animation-delay: 1.1s; }
@keyframes ant-ink-draw { to { stroke-dashoffset: 0; } }
.ant-spot { position: absolute; inset: 0; pointer-events: none; opacity: 0; transition: opacity .5s; background: radial-gradient(260px circle at var(--sx, 50%) var(--sy, 40%), color-mix(in oklab, var(--primary) 16%, transparent), transparent 70%); }
.ant-stage-pane:hover .ant-spot { opacity: 1; }
.gx-app .ant-step-tab { overflow: hidden; }
.gx-app .ant-step-tab::after { content: ""; position: absolute; inset: 0; background: linear-gradient(105deg, transparent 35%, color-mix(in oklab, var(--primary) 12%, transparent) 50%, transparent 65%); transform: translateX(-110%); transition: transform .7s var(--ease-cine); pointer-events: none; }
.gx-app .ant-step-tab:hover::after { transform: translateX(110%); }
.gx-grain { position: absolute; inset: -6%; z-index: 55; width: 112%; height: 112%; pointer-events: none; opacity: .028; mix-blend-mode: multiply; }

.gx-book-row { display: grid; grid-template-columns: 1.4fr 64px 80px 56px; gap: 8px; align-items: center; border-bottom: 1px solid var(--border); padding: 12px 0; font-family: var(--font-mono); font-size: 13px; }
.gx-book-row span:not(:first-child) { text-align: right; }
.gx-market { display: grid; gap: 32px; }
.gx-segment { display: inline-flex; align-items: center; height: 40px; padding: 3px; border-radius: 999px; border: 1px solid var(--border); background: var(--background-deep); }
.gx-segment button { height: 32px; padding: 0 16px; border: 0; border-radius: 999px; background: transparent; color: var(--muted-foreground); font: 600 14px/1 var(--font-sans); cursor: pointer; }
.gx-segment button[aria-pressed="true"] { color: var(--primary-foreground); background: var(--foreground); }
.gx-bento { display: grid; gap: 12px; grid-template-columns: 1fr 1fr; }
.gx-app .gx-tile-no { position: static; display: block; font-family: var(--font-mono); font-size: 12px; letter-spacing: .08em; color: var(--primary); }
.gx-bento .gx-tile-hero { background: linear-gradient(160deg, color-mix(in oklab, var(--primary) 14%, var(--card)) 0%, var(--card) 75%); border-color: color-mix(in oklab, var(--primary) 38%, var(--border)); }
.gx-tile-value { margin-top: 16px; font-family: var(--font-display); font-size: clamp(1.75rem, 2.4vw, 2.1rem); font-weight: 600; letter-spacing: -.02em; line-height: 1; color: var(--foreground); }
.gx-tile-value span { margin-left: 6px; font-size: 12px; font-weight: 400; letter-spacing: .04em; color: var(--muted-foreground); }
.gx-flow-line { position: relative; display: flex; justify-content: space-between; gap: 8px; margin-top: 48px; padding-top: 18px; border-top: 1px dashed color-mix(in oklab, var(--primary) 45%, var(--border)); }
.gx-flow-line::before { content: ""; position: absolute; top: -2px; left: 0; width: 12%; height: 3px; border-radius: 3px; background: var(--primary); animation: gx-flow 4.5s linear infinite; }
.gx-flow-line span { font-family: var(--font-mono); font-size: 12px; letter-spacing: .12em; color: var(--muted-foreground); }
@keyframes gx-flow { from { left: 0; } to { left: 88%; } }
.gx-toc { display: flex; flex-direction: column; gap: 2px; border-left: 1px solid var(--border); }
.gx-toc button { display: flex; gap: 12px; width: 100%; padding: 7px 14px; margin-left: -1px; border: 0; border-left: 2px solid transparent; background: transparent; color: var(--muted-foreground); font: inherit; font-size: 13px; text-align: left; cursor: pointer; }
.gx-toc button:hover { color: var(--foreground); border-left-color: var(--primary); }
.gx-toc span { font-family: var(--font-mono); color: var(--primary); }
.gx-rules { display: grid; gap: 40px; }
.gx-rungs { display: grid; gap: 16px; }
.gx-rung { width: 100%; padding: 22px; border: 1px solid var(--border); border-radius: 18px; background: var(--card); color: inherit; text-align: left; cursor: pointer; transition: border-color .2s; }
.gx-rung[aria-pressed="true"] { border-color: var(--primary); box-shadow: 0 0 0 1px var(--primary); }
@media (min-width: 900px) {
  .gx-rungs { grid-template-columns: repeat(3, minmax(0, 1fr)); }
  .gx-bento { grid-template-columns: 1.6fr 1fr 1fr; }
  .gx-bento .gx-tile-hero { grid-row: span 2; }
  .gx-bento .gx-tile-hero .gx-tile-value { margin-top: 56px; font-size: clamp(2.6rem, 4.4vw, 3.35rem); }
  .gx-market { grid-template-columns: minmax(0, 1fr) 300px; }
  .gx-rules { grid-template-columns: 220px minmax(0, 1fr); }
  .gx-toc { position: sticky; top: 12px; align-self: start; }
}
@media (min-width: 1024px) {
  .gx-menu, .gx-fold { display: none; }
}
@media (max-width: 1023px) {
  .gx-container { width: calc(100% - 40px); }
  .ant-masthead, .ant-workbench, .ant-ledger-top, .ant-timeline-stage, .ant-calc-shell, .gx-page-hero { grid-template-columns: minmax(0, 1fr); }
  .ant-masthead-side { padding-left: 0; border-left: 0; padding-top: 16px; border-top: 1px solid var(--border); }
  .ant-stage-pane, .ant-ledger-hero, .ant-calc-left { border-right: 0; border-bottom: 1px solid var(--border); }
  .ant-ledger-foot { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .ant-ledger-metric { border-bottom: 1px solid var(--border); }
  .ant-timeline-rail { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .gx-tiles { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}
@media (max-width: 639px) {
  .gx-container { width: calc(100% - 32px); }
  .ant-ledger-cols, .ant-ledger-foot, .ant-timeline-rail { grid-template-columns: minmax(0, 1fr); }
  .ant-ledger-cell, .ant-ledger-metric { border-right: 0; border-bottom: 1px solid var(--border); }
  .ant-ledger-cell:last-child, .ant-ledger-metric:last-child { border-bottom: 0; }
  .ant-stage-pane, .ant-console-pane, .ant-timeline-stage, .ant-calc-left, .ant-calc-right { padding: 22px 20px; }
}
@media (prefers-reduced-motion: reduce) {
  .ant-sweep { display: none; }
  .ant-swept .ant-view-stage { animation: none; }
  .ant-mask > span, .ant-ink path { animation: none; transform: none; stroke-dashoffset: 0; }
  .ant-view-stage, .ant-stagger-1, .ant-stagger-2, .ant-stagger-3, .ac-tab-active::after { animation: none; opacity: 1; transform: none; filter: none; }
  .gx-char { opacity: 1; animation: none; }
  .gx-rise { opacity: 1; transform: none; }
  .hc-card, .hc-foil, .gx-live-dot, .gx-flow-line::before { animation: none; }
}
`;

type Ask = { id: number; price: bigint };
type Bid = { id: number; price: bigint; remaining: number; bidder: string };

function fmtDeadline(seconds: number, language: "zh" | "en") {
  return new Intl.DateTimeFormat(language === "zh" ? "zh-CN" : "en-GB", {
    timeZone: "Asia/Shanghai",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).format(new Date(seconds * 1000));
}

function fmtInt(value: number) {
  return Math.round(value).toLocaleString("en-US");
}

function fmtNum(value: number, digits = 0) {
  return value.toLocaleString("en-US", { maximumFractionDigits: digits, minimumFractionDigits: digits });
}

function fmtBnb(value: bigint, digits = 4) {
  const text = formatEther(value);
  const [whole = "0", fraction = ""] = text.split(".");
  const trimmed = fraction.slice(0, digits).replace(/0+$/, "");
  const grouped = whole.replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  return trimmed ? `${grouped}.${trimmed}` : grouped;
}

const BOOK_SAMPLE = {
  symbol: "ANTAGENT",
  asks: [] as Ask[],
  bids: [] as Bid[],
  fees: 0n,
};

const VAULT_FACTORY = "0x798D1a41C4EfEa013b1d293ae1134339b8CA31b6" as const;
const LENS = "0x85b6CfD82a9B0589dc255cB47a1351181366Dba5" as const;
const LENS_ABI = parseAbi([
  "function getActiveListings(address,uint256,uint256) view returns ((uint256,address,uint96)[],uint256,uint256)",
  "function getActiveBids(address,uint256,uint256) view returns ((uint256,address,uint96,uint32)[],uint256,uint256)",
]);
const LAUNCH_BURN = 97_479_938n * 10n ** 18n;
const CARDS_ABI = parseAbi([
  "function paidMinted() view returns (uint256)",
  "function launched() view returns (bool)",
  "function totalDividendPaid() view returns (uint256)",
  "function dividendLiability() view returns (uint256)",
  "function streamRemaining() view returns (uint256)",
  "function sideStreamRemaining() view returns (uint256)",
  "function totalMarketFees() view returns (uint256)",
  "function bidEscrow() view returns (uint256)",
  "function launchedToken() view returns (address)",
  "function presaleDeadline() view returns (uint256)",
  "function presaleEscrow() view returns (uint256)",
]);
const VAULT_ABI = parseAbi([
  "function totalTaxRevenue() view returns (uint256)",
  "function totalDividendForwarded() view returns (uint256)",
  "function totalFloorForwarded() view returns (uint256)",
  "function totalMintBurned() view returns (uint256)",
  "function totalForfeitBurned() view returns (uint256)",
  "function totalFloorBurned() view returns (uint256)",
  "function ladderSold(uint256) view returns (uint256)",
  "function twapPrice() view returns (uint256)",
  "function duelFee() view returns (uint256)",
]);
const BUYERS_ABI = parseAbi(["function presaleBuyerCount() view returns (uint256)"]);
const ROOM_ABI = parseAbi(["function roomOf(uint256) view returns (address,uint256,uint256)"]);
const LADDER_BUY_ABI = parseAbi(["function buyLadder(uint256 rung, uint256 amount) payable returns (uint256)"]);

type Live = {
  cards: boolean;
  cardsAddress: string;
  vaultAddress: string;
  duelAddress: string;
  launched: boolean;
  paid: number;
  minters: number;
  presaleDeadline: number;
  presaleEscrow: bigint;
  tax: bigint;
  dividendFwd: bigint;
  floorFwd: bigint;
  mintBurned: bigint;
  forfeitBurned: bigint;
  floorBurned: bigint;
  dividendPaid: bigint;
  liability: bigint;
  asks: Ask[];
  bids: Bid[];
  stream: bigint;
  sideStream: bigint;
  fees: bigint;
  escrow: bigint;
  ladderSold: [bigint, bigint, bigint];
  twap: bigint | null;
  duelFee: bigint | null;
};
const EMPTY_LIVE: Live = {
  cards: false, cardsAddress: "", vaultAddress: "", duelAddress: "", launched: false, paid: 0, minters: 0, presaleDeadline: 0, presaleEscrow: 0n,
  tax: 0n, dividendFwd: 0n, floorFwd: 0n, mintBurned: 0n, forfeitBurned: 0n, floorBurned: 0n,
  dividendPaid: 0n, liability: 0n, stream: 0n, sideStream: 0n, fees: 0n, escrow: 0n, asks: [], bids: [],
  ladderSold: [0n, 0n, 0n], twap: null, duelFee: null,
};
type WaitingRoom = { id: number; player: string; card: number; deposit: bigint };

function rng(seed: number) {
  let s = (seed * 2654435761) >>> 0 || 1;
  return () => {
    s ^= s << 13;
    s ^= s >>> 17;
    s ^= s << 5;
    return ((s >>> 0) % 100000) / 100000;
  };
}

function Grain() {
  const ref = useRef<HTMLCanvasElement>(null);
  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    let raf = 0;
    let last = 0;
    const paint = () => {
      const tile = 160;
      const w = Math.max(tile, canvas.clientWidth || tile);
      const h = Math.max(tile, canvas.clientHeight || tile);
      canvas.width = w;
      canvas.height = h;
      const img = ctx.createImageData(tile, tile);
      for (let i = 0; i < img.data.length; i += 4) {
        const n = (Math.random() * 255) | 0;
        img.data[i] = n;
        img.data[i + 1] = n;
        img.data[i + 2] = n;
        img.data[i + 3] = 255;
      }
      for (let y = 0; y < h; y += tile) {
        for (let x = 0; x < w; x += tile) ctx.putImageData(img, x, y);
      }
    };
    const draw = (now: number) => {
      if (now - last > 160) {
        paint();
        last = now;
      }
      raf = requestAnimationFrame(draw);
    };
    raf = requestAnimationFrame(draw);
    return () => cancelAnimationFrame(raf);
  }, []);
  return <canvas ref={ref} className="gx-grain" aria-hidden="true" />;
}

function GenerativeCard({ id, kind = "open", className }: { id: number; kind?: Kind; className?: string }) {
  const ref = useRef<HTMLCanvasElement>(null);
  const pointer = useRef({ x: 0.5, y: 0.5, active: false });
  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    const dpr = 2;
    let raf = 0;
    let visible = true;
    let last = 0;
    const rand = rng(id + 13);
    const petals = (kind === "team" ? 7 : 4) + Math.floor(rand() * 4);
    const rings = 4 + Math.floor(rand() * 3);
    const rays = 12 + Math.floor(rand() * 8);
    const tiltBase = rand() * Math.PI * 2;
    const eccentricity = 0.34 + rand() * 0.32;
    const sweepSpeed = 0.12 + rand() * 0.07;
    const nodes = Array.from({ length: 24 }, () => ({
      a: rand() * Math.PI * 2,
      r: 0.22 + rand() * 0.64,
      s: 1.0 + rand() * 1.9,
      sp: (rand() - 0.5) * 0.16,
    }));
    let t = rand() * 100;
    let ox = 0;
    let oy = 0;
    const resize = () => {
      canvas.width = Math.max(1, Math.round(canvas.clientWidth * dpr));
      canvas.height = Math.max(1, Math.round(canvas.clientHeight * dpr));
    };
    const paint = () => {
      const w = canvas.width;
      const h = canvas.height;
      ctx.clearRect(0, 0, w, h);
      ctx.fillStyle = INK;
      ctx.fillRect(0, 0, w, h);
      const p = pointer.current;
      const tx = p.active ? p.x - 0.5 : Math.sin(t * 0.28) * 0.14;
      const ty = p.active ? p.y - 0.5 : Math.cos(t * 0.22) * 0.1;
      ox += (tx - ox) * 0.07;
      oy += (ty - oy) * 0.07;
      const cx = w * 0.5 + ox * w * 0.045;
      const cy = h * 0.5 + oy * h * 0.038;
      const unit = Math.min(w, h) * 0.43;

      // Warm terracotta depth glow
      const wash = ctx.createRadialGradient(cx, cy, unit * 0.04, cx, cy, unit * 1.25);
      wash.addColorStop(0, "rgba(212, 98, 63, 0.30)");
      wash.addColorStop(0.48, "rgba(212, 98, 63, 0.08)");
      wash.addColorStop(1, "transparent");
      ctx.fillStyle = wash;
      ctx.fillRect(0, 0, w, h);

      // Fine horological degree ticks on outer bezel
      const bezelR = unit * 0.96;
      ctx.strokeStyle = SAND;
      for (let i = 0; i < 60; i += 1) {
        const a = (i / 60) * Math.PI * 2 + tiltBase * 0.15;
        const major = i % 5 === 0;
        const r0 = bezelR - (major ? dpr * 6 : dpr * 3);
        ctx.globalAlpha = major ? 0.32 : 0.14;
        ctx.lineWidth = major ? dpr * 1.0 : dpr * 0.6;
        ctx.beginPath();
        ctx.moveTo(cx + Math.cos(a) * r0, cy + Math.sin(a) * r0);
        ctx.lineTo(cx + Math.cos(a) * bezelR, cy + Math.sin(a) * bezelR);
        ctx.stroke();
      }

      // Concentric reference rings
      ctx.strokeStyle = SAND;
      ctx.lineWidth = dpr * 0.75;
      for (let i = 1; i <= rings; i += 1) {
        const rr = unit * (0.24 + (i / rings) * 0.66);
        ctx.globalAlpha = 0.1 + (i === rings ? 0.1 : 0);
        ctx.beginPath();
        ctx.arc(cx, cy, rr, 0, Math.PI * 2);
        ctx.stroke();
      }

      // Guilloché intertwined orbital ellipses (deterministic per card ID)
      for (let i = 0; i < petals; i += 1) {
        const rot = tiltBase + (i / petals) * Math.PI + t * sweepSpeed * 0.35;
        ctx.save();
        ctx.translate(cx, cy);
        ctx.rotate(rot);
        ctx.strokeStyle = i % 2 === 0 ? FLOW : PAPER;
        ctx.lineWidth = i % 2 === 0 ? dpr * 1.15 : dpr * 0.7;
        ctx.globalAlpha = i % 2 === 0 ? 0.62 : 0.22;
        ctx.beginPath();
        ctx.ellipse(0, 0, unit * 0.84, unit * eccentricity, 0, 0, Math.PI * 2);
        ctx.stroke();
        ctx.restore();
      }

      // Precision radial engraved rays
      for (let i = 0; i < rays; i += 1) {
        const angle = tiltBase + (i / rays) * Math.PI * 2 + Math.sin(t * sweepSpeed + i * 0.35) * 0.025;
        const len = unit * (0.42 + 0.44 * ((i * 7 + id) % 5) / 4);
        const inner = unit * 0.15;
        const isAccent = i % 2 === 0;
        ctx.strokeStyle = isAccent ? FLOW : PAPER;
        ctx.lineWidth = isAccent ? dpr * 1.4 : dpr * 0.8;
        ctx.globalAlpha = isAccent ? 0.72 : 0.24;
        ctx.beginPath();
        ctx.moveTo(cx + Math.cos(angle) * inner, cy + Math.sin(angle) * inner);
        ctx.lineTo(cx + Math.cos(angle) * len, cy + Math.sin(angle) * len);
        ctx.stroke();
      }

      // Orbiting fine starlight nodes
      for (const node of nodes) {
        const ang = node.a + t * node.sp;
        const nx = cx + Math.cos(ang) * unit * node.r;
        const ny = cy + Math.sin(ang) * unit * node.r;
        ctx.globalAlpha = 0.52;
        ctx.fillStyle = node.r > 0.55 ? PAPER : FLOW;
        ctx.beginPath();
        ctx.arc(nx, ny, node.s * dpr * 0.5, 0, Math.PI * 2);
        ctx.fill();
      }

      // Center engraved medallion core
      ctx.globalAlpha = 1;
      ctx.fillStyle = INK;
      ctx.beginPath();
      ctx.arc(cx, cy, unit * 0.14, 0, Math.PI * 2);
      ctx.fill();
      ctx.strokeStyle = FLOW;
      ctx.lineWidth = dpr * 1.4;
      ctx.stroke();
      ctx.fillStyle = FLOW;
      ctx.beginPath();
      ctx.arc(cx, cy, unit * 0.048, 0, Math.PI * 2);
      ctx.fill();

      ctx.globalAlpha = 0.48;
      ctx.fillStyle = PAPER;
      ctx.font = `500 ${Math.round(9 * dpr)}px "IBM Plex Mono", monospace`;
      ctx.textAlign = "center";
      ctx.fillText(`ANT // ${String(id).padStart(6, "0")}`, w * 0.5, h - 14 * dpr);
      ctx.globalAlpha = 1;
    };
    resize();
    const ro = new ResizeObserver(resize);
    ro.observe(canvas);
    const observer = new IntersectionObserver((entries) => {
      visible = entries.some((entry) => entry.isIntersecting);
    });
    observer.observe(canvas);
    const draw = (now: number) => {
      if (visible && now - last >= 1000 / 60) {
        t += 0.016;
        paint();
        last = now;
      }
      raf = requestAnimationFrame(draw);
    };
    raf = requestAnimationFrame(draw);
    return () => {
      cancelAnimationFrame(raf);
      ro.disconnect();
      observer.disconnect();
    };
  }, [id, kind]);
  return (
    <canvas
      ref={ref}
      className={className}
      role="img"
      aria-label={`ANTAGENT #${id}`}
      onPointerMove={(event) => {
        const r = event.currentTarget.getBoundingClientRect();
        pointer.current = { x: (event.clientX - r.left) / r.width, y: (event.clientY - r.top) / r.height, active: true };
      }}
      onPointerLeave={() => {
        pointer.current.active = false;
      }}
    />
  );
}

function HoloCard({ id, kind }: { id: number; kind: Kind }) {
  const ref = useRef<HTMLDivElement>(null);
  const serial = String(id).padStart(6, "0");
  const tier = kind === "presale" ? "PRESALE" : kind === "team" ? "TEAM" : "OPEN";
  const move = (event: PointerEvent<HTMLDivElement>) => {
    const el = ref.current;
    if (!el) return;
    const r = el.getBoundingClientRect();
    const x = (event.clientX - r.left) / r.width;
    const y = (event.clientY - r.top) / r.height;
    el.style.setProperty("--rx", `${(0.5 - y) * 22}deg`);
    el.style.setProperty("--ry", `${(x - 0.5) * 26}deg`);
    el.style.setProperty("--mx", `${x * 100}%`);
    el.style.setProperty("--my", `${y * 100}%`);
    el.dataset["active"] = "true";
  };
  const leave = () => {
    const el = ref.current;
    if (!el) return;
    el.style.setProperty("--rx", "0deg");
    el.style.setProperty("--ry", "0deg");
    el.dataset["active"] = "false";
  };
  return (
    <div className="hc-scene" onPointerMove={move} onPointerLeave={leave}>
      <div className="hc-shadow" aria-hidden="true" />
      <div ref={ref} className="hc-card" data-active="false">
        <div className="hc-inner">
          <header className="hc-head">
            <AntLogo size="sm" />
            <span className="hc-tier">{tier}</span>
          </header>
          <div className="hc-art">
            <GenerativeCard id={id} kind={kind} className="h-full w-full" />
          </div>
          <footer className="hc-foot">
            <div>
              <p className="hc-label">AGENT ID</p>
              <p className="hc-serial">#{serial}</p>
            </div>
            <div>
              <p className="hc-label">EDITION</p>
              <p className="hc-edition">1 / 1</p>
            </div>
          </footer>
        </div>
        <div className="hc-foil" aria-hidden="true" />
        <div className="hc-glare" aria-hidden="true" />
      </div>
    </div>
  );
}

function CountUp({ value, digits = 0, suffix = "", drawn = false }: { value: number; digits?: number; suffix?: string; drawn?: boolean }) {
  const [text, setText] = useState(() => fmtNum(0, digits) + suffix);
  useEffect(() => {
    let raf = 0;
    const t0 = performance.now();
    const tick = (now: number) => {
      const p = Math.min(1, (now - t0) / 1400);
      const eased = 1 - (1 - p) ** 4;
      setText(fmtNum(value * eased, digits) + suffix);
      if (p < 1) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [value, digits, suffix]);
  return drawn ? <Poster text={text} /> : <span>{text}</span>;
}

function compareAsk(a: { price: bigint; id: number }, b: { price: bigint; id: number }) {
  if (a.price < b.price) return -1;
  if (a.price > b.price) return 1;
  return a.id - b.id;
}

function compareBid(a: { price: bigint; id: number }, b: { price: bigint; id: number }) {
  if (a.price > b.price) return -1;
  if (a.price < b.price) return 1;
  return a.id - b.id;
}

function levelRows(rows: { price: bigint; count: number }[]) {
  const levels: { price: bigint; count: number; orders: number; total: number }[] = [];
  for (const row of rows) {
    const last = levels[levels.length - 1];
    if (last && last.price === row.price) {
      last.count += row.count;
      last.orders += 1;
    } else {
      levels.push({ price: row.price, count: row.count, orders: 1, total: 0 });
    }
  }
  let total = 0;
  for (const level of levels) {
    total += level.count;
    level.total = total;
  }
  return levels;
}

function Donut({ active, lockLabel, label }: { active: number; lockLabel: string; label: string }) {
  const radius = 80;
  const circumference = 2 * Math.PI * radius;
  let cursor = 0;
  const arcs = SLICES.map((slice, index) => {
    const length = (slice.amount / 777_777_777) * circumference;
    const arc = { slice, index, length, start: cursor };
    cursor += length;
    return arc;
  });
  const team = arcs[arcs.length - 1];
  if (!team) return null;
  const alpha = ((team.start + team.length / 2) / circumference) * Math.PI * 2;
  const dx = 58 * Math.cos(alpha);
  const dy = 58 * Math.sin(alpha);
  const dashes = 26;
  const step = team.length / dashes;
  const dash = step * 0.5;
  return (
    <>
      <svg viewBox="0 0 200 200" className="gx-donut" role="img" aria-label={label}>
        {arcs.map(({ slice, index, length, start }) => {
          if (slice.key === "team") {
            return (
              <g key={slice.key}>
                {Array.from({ length: dashes }, (_, mark) => (
                  <circle key={mark} cx="100" cy="100" r={radius} fill="none" stroke="var(--primary)" strokeOpacity={0.22} strokeWidth={active === index ? 30 : 22} strokeDasharray={`${dash} ${circumference - dash}`} strokeDashoffset={-(start + mark * step)} />
                ))}
              </g>
            );
          }
          return <circle key={slice.key} cx="100" cy="100" r={radius} fill="none" stroke="var(--primary)" strokeOpacity={SLICE_ALPHA[index]} strokeWidth={active === index ? 30 : 22} strokeDasharray={`${length - 2} ${circumference - length + 2}`} strokeDashoffset={-start} />;
        })}
      </svg>
      <span className="gx-donut-lock" style={{ left: `${(100 + dy) / 2}%`, top: `${(100 - dx) / 2}%` }}>{lockLabel}</span>
    </>
  );
}

const VIEW_PATHS: Record<View, string> = {
  home: "/",
  market: "/market",
  commands: "/commands",
  vault: "/vault",
  tokenomics: "/tokenomics",
  ladder: "/ladder",
  duel: "/duel",
  rules: "/rules",
  rarity: "/rarity",
};

export default function Component({ initialView = "home" }: { initialView?: View }) {
  const sdk = useFlapSdk({ chainId: 56 });
  const [live, setLive] = useState<Live>(EMPTY_LIVE);
  const [rooms, setRooms] = useState<WaitingRoom[]>([]);
  const [roomsReady, setRoomsReady] = useState(false);
  const [emptyRoomId, setEmptyRoomId] = useState<number | null>(null);
  const [chainTick, setChainTick] = useState(0);
  useEffect(() => {
    if (!ANTAGENT_EDITION.deploymentConfirmed) return;
    let stop = false;
    async function load() {
      const next: Live = { ...EMPTY_LIVE };
      try {
        const duel = await sdk.resolveContract("duel", []);
        next.duelAddress = duel.address;
      } catch { /* Duel is created with the factory. Leave it blank until that read succeeds. */ }
      try {
        const cards = await sdk.resolveContract("cards", []);
        const readCard = <T,>(functionName: string) => sdk.readContract<T>({ contract: cards, abi: CARDS_ABI, functionName });
        const [paid, launched, dividendPaid, liability, stream, sideStream, fees, escrow, minters, deadline, presaleEscrow] = await Promise.all([
          readCard<bigint>("paidMinted"),
          readCard<boolean>("launched"),
          readCard<bigint>("totalDividendPaid"),
          readCard<bigint>("dividendLiability"),
          readCard<bigint>("streamRemaining"),
          readCard<bigint>("sideStreamRemaining"),
          readCard<bigint>("totalMarketFees"),
          readCard<bigint>("bidEscrow"),
          sdk.readContract<bigint>({ address: VAULT_FACTORY, abi: BUYERS_ABI, functionName: "presaleBuyerCount" }),
          readCard<bigint>("presaleDeadline"),
          readCard<bigint>("presaleEscrow"),
        ]);
        Object.assign(next, {
          cards: true, cardsAddress: cards.address, launched, paid: Number(paid), minters: Number(minters),
          presaleDeadline: Number(deadline), presaleEscrow,
          dividendPaid, liability, stream, sideStream, fees, escrow,
        });
        try {
          if (launched) {
            const token = await readCard<string>("launchedToken");
            if (isAddress(token) && BigInt(token) !== 0n) {
              const vault = await sdk.resolveContract("vault", [token]);
              next.vaultAddress = vault.address;
              const readVault = <T,>(functionName: string, args?: unknown[]) => sdk.readContract<T>({ contract: vault, abi: VAULT_ABI, functionName, args });
              const [tax, dividendFwd, floorFwd, mintBurned, forfeitBurned, floorBurned, sold0, sold1, sold2, duelFee] = await Promise.all([
                readVault<bigint>("totalTaxRevenue"),
                readVault<bigint>("totalDividendForwarded"),
                readVault<bigint>("totalFloorForwarded"),
                readVault<bigint>("totalMintBurned"),
                readVault<bigint>("totalForfeitBurned"),
                readVault<bigint>("totalFloorBurned"),
                readVault<bigint>("ladderSold", [0n]),
                readVault<bigint>("ladderSold", [1n]),
                readVault<bigint>("ladderSold", [2n]),
                readVault<bigint>("duelFee"),
              ]);
              let twap: bigint | null = null;
              try { twap = await readVault<bigint>("twapPrice"); } catch { twap = null; }
              Object.assign(next, { tax, dividendFwd, floorFwd, mintBurned, forfeitBurned, floorBurned, ladderSold: [sold0, sold1, sold2], twap, duelFee });
            }
          }
        } catch { /* The vault address appears when the pool is open. */ }
        try {
          const readPage = (functionName: "getActiveListings" | "getActiveBids", cursor: bigint) => sdk.readContract<readonly [readonly (readonly [bigint, string, bigint, bigint])[], bigint, bigint]>({
            address: LENS, abi: LENS_ABI, functionName, args: [cards.address, cursor, 500n],
          });
          const asks: Ask[] = [];
          const bids: Bid[] = [];
          let askCursor = 0n;
          let bidCursor = 0n;
          for (let page = 0; page < 8; page += 1) {
            const [askRows, askNext, askEnd] = await readPage("getActiveListings", askCursor);
            for (const row of askRows) asks.push({ id: Number(row[0]), price: row[2] });
            const [bidRows, bidNext, bidEnd] = await readPage("getActiveBids", bidCursor);
            for (const row of bidRows) bids.push({ id: Number(row[0]), price: row[2], remaining: Number(row[3]), bidder: row[1] });
            const askDone = askNext >= askEnd || askNext === askCursor;
            const bidDone = bidNext >= bidEnd || bidNext === bidCursor;
            if (askDone && bidDone) break;
            askCursor = askDone ? askEnd : askNext;
            bidCursor = bidDone ? bidEnd : bidNext;
          }
          next.asks = asks;
          next.bids = bids;
        } catch { /* Leave the book empty until the lens read succeeds. */ }
      } catch { /* cards() is still empty. Keep the duel address and the empty totals. */ }
      if (!stop) setLive(next);
    }
    void load();
    const timer = setInterval(() => void load(), 20000);
    return () => { stop = true; clearInterval(timer); };
  }, [sdk, chainTick]);
  const hostT = sdk.i18n.t;
  const [language, setLanguage] = useState<"zh" | "en">("zh");
  const [menuOpen, setMenuOpen] = useState(false);
  const t = (key: string, fallback?: string, params?: Record<string, string | number>) => {
    let copy = EDITION_COPY[key]?.[language === "zh" ? 0 : 1];
    if (copy === undefined) return hostT(`l.${language}.${key}`, fallback, params);
    for (const [name, value] of Object.entries(params ?? {})) copy = copy.replaceAll(`{${name}}`, String(value));
    return copy;
  };
  const [view, setView] = useState<View>(initialView);
  useEffect(() => {
    setView(initialView);
  }, [initialView]);
  useEffect(() => {
    if (view !== "duel" || !live.launched) { setRooms([]); setRoomsReady(false); setEmptyRoomId(null); return; }
    let stop = false;
    async function loadRooms() {
      try {
        const duel = await sdk.resolveContract("duel", []);
        const rows = await Promise.all(Array.from({ length: 100 }, (_, index) => sdk.readContract<readonly [string, bigint, bigint]>({
          contract: duel, abi: ROOM_ABI, functionName: "roomOf", args: [BigInt(index + 1)],
        })));
        if (stop) return;
        const seated = rows.flatMap((row, index) => BigInt(row[0]) === 0n ? [] : [{ id: index + 1, player: row[0], card: Number(row[1]), deposit: row[2] }]);
        setRooms(seated);
        setEmptyRoomId((current) => {
          if (seated.length > 0) return null;
          if (current != null) return current;
          return 1 + Math.floor(Math.random() * 100);
        });
        setRoomsReady(true);
      } catch {
        if (!stop) { setRooms([]); setRoomsReady(false); setEmptyRoomId(null); }
      }
    }
    void loadRooms();
    const timer = setInterval(() => void loadRooms(), 20000);
    return () => { stop = true; clearInterval(timer); };
  }, [sdk, view, live.launched]);
  const [intro, setIntro] = useState(0);
  // Each route mounts its own instance; carry the page sweep across that remount.
  useLayoutEffect(() => {
    if (pendingSweep) { pendingSweep = false; setIntro((n) => n + 1); }
  }, []);
  const [cardId, setCardId] = useState(7777);
  const [phase, setPhase] = useState(0);
  const [mintPhase, setMintPhase] = useState<"presale" | "open">("presale");
  const [count, setCount] = useState(3);
  const [day, setDay] = useState(2);
  const [slice, setSlice] = useState(0);
  const [bookSide, setBookSide] = useState<"ask" | "bid">("ask");
  const [marketTab, setMarketTab] = useState<"book" | "mine">("book");
  const [bidder, setBidder] = useState("");
  const [commandStyle, setCommandStyle] = useState<"text" | "short">("short");
  const [ladderRung, setLadderRung] = useState(0);
  const [ladderQty, setLadderQty] = useState("1000");
  const [ladderBuying, setLadderBuying] = useState(false);
  const ruleRefs = useRef<Record<number, HTMLElement | null>>({});
  const [shown, setShown] = useState(false);
  const book = { ...BOOK_SAMPLE, fees: live.fees, asks: live.asks, bids: live.bids };
  const rankedAsks = [...book.asks].sort(compareAsk);
  const rankedBids = [...book.bids].sort(compareBid);
  const shownAsks = rankedAsks.slice(0, ROWS);
  const shownBids = rankedBids.slice(0, ROWS);
  const askLevels = levelRows(shownAsks.map((ask) => ({ price: ask.price, count: 1 })));
  const bidLevels = levelRows(shownBids.map((bid) => ({ price: bid.price, count: bid.remaining })));
  const bookEscrow = live.escrow;
  const ladderLive = { launched: live.launched, sold: live.ladderSold, twap: live.twap };
  const [nowSeconds, setNowSeconds] = useState(0);
  useEffect(() => {
    setNowSeconds(Math.floor(Date.now() / 1000));
    const tick = window.setInterval(() => setNowSeconds(Math.floor(Date.now() / 1000)), 15000);
    return () => window.clearInterval(tick);
  }, []);
  const refunding = live.cards && !live.launched && live.presaleDeadline > 0 && nowSeconds > live.presaleDeadline && live.paid < PRESALE_CARDS;
  const salePhase = live.launched ? "open" : refunding ? "refund" : "presale";
  const tokenBurned = live.launched ? LAUNCH_BURN + live.mintBurned + live.forfeitBurned : 0n;
  const floorCards = live.floorBurned.toString();
  const progress = useRef<HTMLDivElement>(null);
  const scroller = useRef<HTMLDivElement>(null);
  const hero = useRef<HTMLElement>(null);
  const stage = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const timer = window.setTimeout(() => setShown(true), 80);
    return () => window.clearTimeout(timer);
  }, [view]);

  const phases = [
    { title: t("phase.1.title"), body: t("phase.1.body") },
    { title: t("phase.2.title"), body: t("phase.2.body") },
    { title: t("phase.3.title"), body: t("phase.3.body") },
    { title: t("phase.4.title"), body: t("phase.4.body") },
    { title: t("phase.5.title"), body: t("phase.5.body") },
  ];
  const groupLabel = {
    mint: t("cmd.group.mint"),
    buy: t("cmd.group.buy"),
    sell: t("cmd.group.sell"),
    yield: t("cmd.group.yield"),
  };
  const commandCopy = {
    wallet: { title: t("cmd.wallet.title"), fn: t("cmd.wallet.fn"), desc: t("cmd.wallet.desc"), text: t("cmd.wallet.text"), short: t("cmd.wallet.short") },
    mint: { title: t("cmd.mint.title"), fn: t("cmd.mint.fn"), desc: t("cmd.mint.desc"), text: t("cmd.mint.text"), short: t("cmd.mint.short") },
    refund: { title: t("cmd.refund.title"), fn: t("cmd.refund.fn"), desc: t("cmd.refund.desc"), text: t("cmd.refund.text"), short: t("cmd.refund.short") },
    buy: { title: t("cmd.buy.title"), fn: t("cmd.buy.fn"), desc: t("cmd.buy.desc"), text: t("cmd.buy.text"), short: t("cmd.buy.short") },
    bid: { title: t("cmd.bid.title"), fn: t("cmd.bid.fn"), desc: t("cmd.bid.desc"), text: t("cmd.bid.text"), short: t("cmd.bid.short") },
    cancel: { title: t("cmd.cancel.title"), fn: t("cmd.cancel.fn"), desc: t("cmd.cancel.desc"), text: t("cmd.cancel.text"), short: t("cmd.cancel.short") },
    list: { title: t("cmd.list.title"), fn: t("cmd.list.fn"), desc: t("cmd.list.desc"), text: t("cmd.list.text"), short: t("cmd.list.short") },
    sell: { title: t("cmd.sell.title"), fn: t("cmd.sell.fn"), desc: t("cmd.sell.desc"), text: t("cmd.sell.text"), short: t("cmd.sell.short") },
    unlist: { title: t("cmd.unlist.title"), fn: t("cmd.unlist.fn"), desc: t("cmd.unlist.desc"), text: t("cmd.unlist.text"), short: t("cmd.unlist.short") },
    claim: { title: t("cmd.claim.title"), fn: t("cmd.claim.fn"), desc: t("cmd.claim.desc"), text: t("cmd.claim.text"), short: t("cmd.claim.short") },
    redeem: { title: t("cmd.redeem.title"), fn: t("cmd.redeem.fn"), desc: t("cmd.redeem.desc"), text: t("cmd.redeem.text"), short: t("cmd.redeem.short") },
    withdraw: { title: t("cmd.withdraw.title"), fn: t("cmd.withdraw.fn"), desc: t("cmd.withdraw.desc"), text: t("cmd.withdraw.text"), short: t("cmd.withdraw.short") },
  };
  const commandDeck = (ids: readonly (keyof typeof commandCopy)[]) => (
    <section className="mt-16">
      <div className="mb-6 flex flex-wrap items-end justify-between gap-4">
        <h2 className="text-2xl font-bold">{t("commands.title")}</h2>
        <div className="gx-segment" role="group" aria-label={t("commands.title")}>
          <button type="button" aria-pressed={commandStyle === "text"} onClick={() => setCommandStyle("text")}>{t("commands.styleGeneral")}</button>
          <button type="button" aria-pressed={commandStyle === "short"} onClick={() => setCommandStyle("short")}>{t("commands.styleBinance")}</button>
        </div>
      </div>
      <p className="gx-muted mb-8 text-sm">{t("commands.note")}</p>
      <div className="grid gap-4 md:grid-cols-2">
        {ids.map((id) => commandCard(id))}
      </div>
    </section>
  );
  const rules = EDITION_RULES.map(entry => {
    const [title, body] = language === "zh" ? entry.zh : entry.en;
    return { title, body };
  });
  const duelRules = [
    { title: t("duel.1.title"), body: t("duel.1.body") },
    { title: t("duel.2.title"), body: t("duel.2.body") },
    { title: t("duel.3.title"), body: t("duel.3.body") },
    { title: t("duel.4.title"), body: t("duel.4.body") },
  ];
  const allocCopy = {
    pool: { name: t("alloc.pool"), note: t("alloc.poolNote") },
    presale: { name: t("alloc.presale"), note: t("alloc.presaleNote") },
    ladder: { name: t("alloc.ladder"), note: t("alloc.ladderNote") },
    burn: { name: t("alloc.burn"), note: t("alloc.burnNote") },
    team: { name: t("alloc.team"), note: t("alloc.teamNote") },
  };
  const flows = [
    { icon: Gift, title: t("flow.dividend"), body: t("flow.dividendBody") },
    { icon: Flame, title: t("flow.burn"), body: t("flow.burnBody") },
    { icon: Droplets, title: t("flow.pool"), body: t("flow.poolBody") },
  ];
  const quoteBnb = mintPhase === "presale" ? count * 0.00245 : count * 0.0049;
  const saleBnb = count * (salePhase === "presale" ? 0.00245 : 0.0049);
  const cheapestAsk = live.asks.reduce<Ask | null>((best, ask) => (!best || ask.price < best.price ? ask : best), null);
  const highestBid = live.bids.reduce<Bid | null>((best, bid) => (!best || bid.price > best.price ? bid : best), null);
  const waitingRoom = [...rooms].sort((a, b) => a.id - b.id)[0];
  const duelFeeNow = live.duelFee;
  const duelTarget = duelFeeNow !== null && roomsReady && !(waitingRoom && waitingRoom.deposit > duelFeeNow)
    ? waitingRoom
      ? { roomId: waitingRoom.id, due: duelFeeNow - waitingRoom.deposit }
      : emptyRoomId != null
        ? { roomId: emptyRoomId, due: duelFeeNow / 2n }
        : null
    : null;
  const fillCommand = (raw: string, id: string) => {
    const open = salePhase === "open";
    const mintValue = (open ? OPEN_WEI : PRESALE_WEI) * BigInt(count);
    const mintData = encoded("function mint(uint256 count, uint256 minTokens) payable returns (uint256)", [
      BigInt(count),
      open ? 1n : 0n,
    ]);
    const ladderData = ladderAmount === 0n
      ? "STOP_NEED_AMOUNT"
      : encoded("function buyLadder(uint256 rung, uint256 amount) payable returns (uint256)", [BigInt(ladderRung), ladderAmount]);
    const claimData = encoded("function claimTokens(uint256 from, uint256 count) returns (uint256)", [0n, 0n]);
    const buyData = cheapestAsk
      ? encoded("function buy(uint256[] tokenIds, uint256[] maxPrices) payable returns (uint256)", [[BigInt(cheapestAsk.id)], [cheapestAsk.price]])
      : "STOP_NO_ASK";
    const bidData = highestBid
      ? encoded("function placeBid(uint256 price, uint256 quantity) payable returns (uint256)", [highestBid.price, 1n])
      : "STOP_NO_BID";
    const launchedData = encoded("function launched() view returns (bool)");
    const paidData = encoded("function paidMinted() view returns (uint256)");
    const deadlineData = encoded("function presaleDeadline() view returns (uint256)");
    const feeData = encoded("function duelFee() view returns (uint256)");
    const value = id === "mint" ? mintValue.toString()
      : id === "ladder" ? ladderPay.toString()
      : id === "buy" ? (cheapestAsk ? cheapestAsk.price.toString() : "STOP_NO_ASK")
      : id === "bid" ? (highestBid ? highestBid.price.toString() : "STOP_NO_BID")
      : id === "duel" ? (duelTarget ? duelTarget.due.toString() : "STOP_NO_FEE")
      : "0";
    const data = id === "mint" ? mintData
      : id === "ladder" ? ladderData
      : id === "redeem" ? claimData
      : id === "buy" ? buyData
      : id === "bid" ? bidData
      : "STOP_NEED_ARGS";
    return raw
      .replaceAll("{cards}", live.cardsAddress || "MISSING")
      .replaceAll("{vault}", live.vaultAddress || "MISSING")
      .replaceAll("{duel}", live.duelAddress || "MISSING")
      .replaceAll("{agent}", AGENT_ID)
      .replaceAll("{count}", String(count))
      .replaceAll("{askId}", cheapestAsk ? String(cheapestAsk.id) : "STOP_NO_ASK")
      .replaceAll("{bidPrice}", highestBid ? highestBid.price.toString() : "STOP_NO_BID")
      .replaceAll("{roomId}", duelTarget ? String(duelTarget.roomId) : "STOP_NO_FEE")
      .replaceAll("{rung}", String(ladderRung))
      .replaceAll("{qty}", ladderQty || "STOP_NEED_AMOUNT")
      .replaceAll("{value}", value)
      .replaceAll("{dataLaunched}", launchedData)
      .replaceAll("{dataPaid}", paidData)
      .replaceAll("{dataDeadline}", deadlineData)
      .replaceAll("{dataFee}", feeData)
      .replaceAll("{data}", data);
  };
  const commandCard = (id: keyof typeof commandCopy) => {
    const copy = commandCopy[id];
    const raw = commandStyle === "short" ? copy.short : copy.text;
    const mintRaw = salePhase === "open"
      ? (commandStyle === "short" ? t("cmd.mint.short.open") : t("cmd.mint.text.open"))
      : (commandStyle === "short" ? t("cmd.mint.short.presale") : t("cmd.mint.text.presale"));
    const text = fillCommand(id === "mint" ? mintRaw : raw, id);
    const fn = id === "mint" ? `mint(${count}, ${salePhase === "open" ? "1" : "0"})`
      : id === "buy" && cheapestAsk ? `buy([${cheapestAsk.id}], [${cheapestAsk.price}])`
      : id === "bid" && highestBid ? `placeBid(${highestBid.price}, 1)`
      : copy.fn;
    const node = (
      <article key={id} className="gx-term">
        <h3 className="text-lg font-bold">{copy.title}</h3>
        <code className="gx-term-fn">{"> "}{fn}</code>
        <p className="gx-muted mt-2 flex-1 text-xs leading-6">{copy.desc}</p>
        {id === "refund" && salePhase === "refund" && <p className="mt-4 text-sm font-semibold">{t("mint.phaseRefund")}</p>}
        {id === "mint" && (
          <div className="mt-4">
            <p className="text-sm font-semibold">{t(salePhase === "open" ? "mint.phaseOpen" : salePhase === "refund" ? "mint.phaseRefund" : "mint.phasePresale")}</p>
            <div className="mt-4 flex items-end justify-between">
              <span className="gx-muted text-xs">{t("mint.count")}</span>
              <span className="gx-display text-3xl"><Poster text={String(count)} /></span>
            </div>
            <div className="gx-count mt-3" role="group" aria-label={t("mint.count")}>
              {Array.from({ length: MAX_MINT }, (_, index) => {
                const next = index + 1;
                const button = <button key={next} type="button" aria-pressed={count === next} onClick={() => setCount(next)}>{next}</button>;
                return button;
              })}
            </div>
            <p className="gx-mono gx-pri mt-3 text-sm">{saleBnb.toFixed(5)} BNB</p>
          </div>
        )}
        <div className="mt-4"><CopyButton value={text} label={t("commands.copy")} /></div>
      </article>
    );
    return node;
  };
  const quoteTokens = count * CARD_GRANT;
  const grant = mintPhase === "presale" ? quoteTokens : CARD_GRANT * count;
  const upfront = Math.floor(grant / 5);
  const vested = upfront + Math.floor((grant - upfront) * day / 5);
  const releasedShare = 0.2 + (day / 5) * 0.8;
  const mintedLive = live.paid;
  const presaleLeft = Math.max(0, PRESALE_CARDS - mintedLive);
  const presalePct = Math.min(100, (mintedLive / PRESALE_CARDS) * 100);
  const raisedBnb = mintedLive * 0.00245;
  const raisedDigits = raisedBnb > 0 && raisedBnb < 1 ? 5 : 2;
  const paidWei = BigInt(mintedLive) * PRESALE_WEI;
  const refundedWei = paidWei > live.presaleEscrow ? paidWei - live.presaleEscrow : 0n;
  const refundedCards = Number(refundedWei / PRESALE_WEI);
  const escrowBnb = Number(formatEther(live.presaleEscrow));
  const refundedBnb = Number(formatEther(refundedWei));
  const refundPct = mintedLive > 0 ? (refundedCards / mintedLive) * 100 : 0;
  const progressDigits = (salePhase === "refund" ? refundPct : presalePct) > 0 && (salePhase === "refund" ? refundPct : presalePct) < 1 ? 3 : 1;
  const kind: Kind = cardId <= PRESALE_CARDS ? "presale" : "open";
  const rise = shown ? "gx-rise gx-in" : "gx-rise";
  const ladderAmount = /^\d+$/.test(ladderQty) ? parseUnits(ladderQty, 18) : 0n;
  const ladderBandPrice = ladderPrice(ladderRung);
  const ladderPay = ladderAmount > 0n ? ladderCost(ladderAmount, ladderBandPrice) : 0n;
  const ladderLeft = (LADDER_SIZE[ladderRung] ?? 0n) - (ladderLive.sold[ladderRung] ?? 0n);
  const ladderOpen = ladderLive.launched && ladderLive.twap !== null && ladderLive.twap >= ladderBandPrice && ladderLeft > 0n;
  const ladderStatus = (index: number) => {
    const price = ladderPrice(index);
    const left = (LADDER_SIZE[index] ?? 0n) - (ladderLive.sold[index] ?? 0n);
    if (!ladderLive.launched) return "ladder.offline";
    if (left <= 0n) return "ladder.soldout";
    if (ladderLive.twap === null) return "ladder.closed";
    return ladderLive.twap >= price ? "ladder.open" : "ladder.closed";
  };
  const buyLadder = async () => {
    if (!sdk.wallet.isConnected) { sdk.wallet.connect(); return; }
    if (sdk.wallet.isWrongNetwork) { await sdk.wallet.switchChain(); return; }
    if (!ladderOpen || ladderAmount === 0n || ladderAmount > ladderLeft || ladderBuying) return;
    setLadderBuying(true);
    try {
      const cards = await sdk.resolveContract("cards", []);
      const token = await sdk.readContract<string>({ contract: cards, abi: CARDS_ABI, functionName: "launchedToken" });
      if (!isAddress(token) || BigInt(token) === 0n) return;
      const vault = await sdk.resolveContract("vault", [token]);
      const prepared = await sdk.simulateContract({
        contract: vault, abi: LADDER_BUY_ABI, functionName: "buyLadder", args: [BigInt(ladderRung), ladderAmount], value: ladderPay,
      });
      const hash = await sdk.writeContract(prepared.request);
      const receipt = await sdk.waitForTx(hash);
      if (receipt.status !== "success") throw new Error("reverted");
      sdk.notify.success(t("ladder.done"));
      setChainTick((n) => n + 1);
    } catch {
      sdk.notify.error(t("ladder.fail"));
    } finally {
      setLadderBuying(false);
    }
  };
  const nav = [
    ["home", "nav.home"],
    ["rarity", "nav.rarity"],
    ["market", "nav.market"],
    ["commands", "nav.commands"],
    ["vault", "nav.vault"],
    ["tokenomics", "nav.tokenomics"],
    ["ladder", "nav.ladder"],
    ["duel", "nav.duel"],
    ["rules", "nav.rules"],
  ] as const;
  const pageMeta = {
    market: ["02", "MARKET", "market.title", "market.lead", 202],
    commands: ["03", "COMMANDS", "commands.title", "commands.lead", 303],
    vault: ["04", "VAULT", "vault.title", "vault.lead", 404],
    rules: ["05", "RULES", "rules.title", "rules.lead", 505],
    tokenomics: ["06", "TOKENOMICS", "token.title", "token.lead", 606],
    ladder: ["07", "LADDER", "ladder.title", "ladder.lead", 707],
    duel: ["08", "DUEL", "duel.title", "duel.lead", 808],
    rarity: ["09", "RARITY", "rarity.title", "rarity.lead", 909],
  } as const;
  const page = view === "home" ? null : pageMeta[view];

  const openView = (next: View) => {
    setMenuOpen(false);
    if (next === view) return;
    pendingSweep = true;
    window.setTimeout(() => { pendingSweep = false; }, 400);
    setView(next);
    setIntro((n) => n + 1);
    if (typeof window !== "undefined") {
      const targetPath = VIEW_PATHS[next];
      if (window.location.pathname !== targetPath) {
        window.history.replaceState(null, "", targetPath);
      }
    }
    if (scroller.current) scroller.current.scrollTop = 0;
    if (progress.current) progress.current.style.transform = "scaleX(0)";
  };

  const onScroll = (event: UIEvent<HTMLDivElement>) => {
    const el = event.currentTarget;
    const height = el.scrollHeight - el.clientHeight;
    if (progress.current) progress.current.style.transform = `scaleX(${height > 0 ? el.scrollTop / height : 0})`;
    const heroEl = hero.current;
    if (heroEl) {
      const hp = Math.min(1, Math.max(0, el.scrollTop / Math.max(1, heroEl.offsetHeight)));
      heroEl.style.setProperty("--hp", hp.toFixed(3));
    }
    if (stage.current) stage.current.style.setProperty("--par", `${Math.min(60, el.scrollTop * 0.08)}px`);
  };

  const magnet = (event: PointerEvent<HTMLButtonElement>) => {
    const el = event.currentTarget;
    const r = el.getBoundingClientRect();
    const x = (event.clientX - r.left) / r.width - 0.5;
    const y = (event.clientY - r.top) / r.height - 0.5;
    el.style.transform = `translate(${x * 7}px, ${y * 7}px)`;
  };

  return (
    <div className="gx-app min-h-screen">
      <style>{LOOK}</style>
      {intro > 0 && (
        <div key={intro} className="ant-sweep" aria-hidden="true">
          <span className="ant-sweep-panel ant-sweep-top" />
          <span className="ant-sweep-panel ant-sweep-bottom" />
          <span className="ant-sweep-line" />
          <span className="ant-sweep-spark" />
          <span className="ant-sweep-brand">
            <span className="gx-logo-lock">
              <AntMark />
              <AntWordmark />
            </span>
          </span>
          <span className="ant-sweep-tag">Many ants, one card, shared yield.</span>
        </div>
      )}
      <Grain />
      <div ref={scroller} className={`gx-scroll ${intro > 0 ? "ant-swept" : ""}`} onScroll={onScroll}>
        <header className="gx-header">
          <div className="gx-container flex items-center justify-between gap-5 py-3">
            <button type="button" onClick={() => openView("home")} aria-label={t("brand")}><AntLogo size="md" /></button>
            <nav className="hidden gap-4 lg:flex" aria-label={t("brand")}>
              {nav.map(([key, label]) => (
                <button key={key} type="button" className={`ac-tab ${view === key ? "ac-tab-active" : ""}`} aria-pressed={view === key} onClick={() => openView(key)}>{t(label)}</button>
              ))}
            </nav>
            <div className="flex items-center gap-3">
              <a className="gx-x" href="https://x.com/MINTAI_BSC" target="_blank" rel="noopener noreferrer" aria-label={t("nav.x")}>
                <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-4.714-6.231-5.401 6.231H2.744l7.727-8.835L1.254 2.25H8.08l4.253 5.622L18.244 2.25zm-1.161 17.52h1.833L7.084 4.126H5.117z" /></svg>
              </a>
              <button type="button" className="gx-menu" aria-expanded={menuOpen} aria-controls="gx-fold" onClick={() => setMenuOpen((open) => !open)}>{t(menuOpen ? "nav.close" : "nav.menu")}</button>
              <div className="gx-lang" role="group" aria-label={t("lang.label")}>
                <button type="button" aria-pressed={language === "zh"} onClick={() => setLanguage("zh")}>{t("lang.zh")}</button>
                <button type="button" aria-pressed={language === "en"} onClick={() => setLanguage("en")}>{t("lang.en")}</button>
              </div>
            </div>
          </div>
          <nav id="gx-fold" className="gx-fold" aria-label={t("brand")} hidden={!menuOpen}>
            <div className="gx-container">
              {nav.map(([key, label], index) => (
                <button key={key} type="button" aria-pressed={view === key} onClick={() => openView(key)}>
                  <span className="gx-fold-no">{String(index + 1).padStart(2, "0")}</span>
                  {t(label)}
                </button>
              ))}
            </div>
          </nav>
          <div ref={progress} className="gx-reading-progress" aria-hidden="true" />
        </header>

        {view === "home" && (
          <main key="home" className="ant-view-stage">
            <section ref={hero} className="gx-container ant-hero">
              <div className={`${rise} ant-masthead ant-stagger-1`}>
                <div className="min-w-0">
                  <span className="ant-hero-pill">
                    <span className="gx-live-dot" />
                    <span>{t("hero.kicker")}</span>
                  </span>
                  <p className="ant-hero-tagline">{t("hero.tagline")}</p>
                  <h1 className="ant-hero-headline">
                    <span className="ant-mask"><span>{t("hero.line1")}</span></span>
                    <em className="ant-mask"><span className="ant-ink">{t("hero.line2")}<svg viewBox="0 0 400 20" preserveAspectRatio="none" aria-hidden="true"><path d="M4 14 C 80 4, 160 18, 240 9 S 360 6, 396 11" /></svg></span></em>
                  </h1>
                </div>
                <div className="ant-masthead-side">
                  <div className="ant-masthead-brand">
                    <span className="ant-masthead-word"><span className="gx-logo-lock"><AntMark /><AntWordmark /></span></span>
                    <span className="gx-mono gx-muted text-[11px]">BNB CHAIN · 1 / 777,777</span>
                  </div>
                  <p className="ant-hero-sub">{t("hero.sub")}</p>
                  <div className="ant-masthead-actions">
                    <button type="button" className="gx-btn gx-btn-solid text-xs" onPointerMove={magnet} onPointerLeave={(event) => { event.currentTarget.style.transform = ""; }} onClick={() => openView("commands")}>
                      <span>{t("nav.commands")}</span>
                      <ArrowDownRight size={14} />
                    </button>
                    <button type="button" className="gx-btn gx-btn-outline text-xs" onClick={() => openView("rules")}>
                      <span>{t("nav.rules")}</span>
                    </button>
                  </div>
                </div>
              </div>

              <div className={`${rise} ant-workbench ant-stagger-2`}>
                <div className="ant-stage-pane" onPointerMove={(event) => { const r = event.currentTarget.getBoundingClientRect(); event.currentTarget.style.setProperty("--sx", `${event.clientX - r.left}px`); event.currentTarget.style.setProperty("--sy", `${event.clientY - r.top}px`); }}>
                  <span className="ant-spot" aria-hidden="true" />
                  <div className="ant-stage-head">
                    <p className="gx-kicker">{t("card.kicker")}</p>
                    <span className="gx-mono gx-muted text-xs">SPECIMEN #{String(cardId).padStart(6, "0")}</span>
                  </div>
                  <div className="hc-stage">
                    <div ref={stage} className="gx-parallax"><HoloCard id={cardId} kind={kind} /></div>
                  </div>
                  <div className="ant-stage-meta">
                    <div className="flex flex-wrap items-baseline justify-between gap-2">
                      <p className="text-base font-semibold">{t("card.title1")} · {t("card.title2")}</p>
                      <span className="gx-mono gx-muted text-xs">{fmtInt(cardId)} / {fmtInt(TOTAL_POOL_CARDS)}</span>
                    </div>
                    <p className="gx-muted mt-1 text-xs leading-6">{t("card.body")}</p>
                    <input className="mt-3" type="range" min={1} max={TOTAL_POOL_CARDS} value={cardId} aria-label={t("card.id")} style={{ ["--fill" as string]: `${((cardId - 1) / (TOTAL_POOL_CARDS - 1)) * 100}%` }} onChange={(event) => setCardId(Number(event.target.value))} />
                    <div className="ant-stage-dial">
                      <span className="gx-mono gx-muted text-[11px]">{t("card.caption")}</span>
                      <button type="button" className="gx-btn gx-btn-outline text-xs" onClick={() => setCardId(1 + Math.floor(Math.random() * TOTAL_POOL_CARDS))}>
                        <span>{t("card.random")}</span>
                        <Shuffle size={14} />
                      </button>
                    </div>

                  </div>
                </div>

                <div className="ant-console-pane">
                  <div>
                    <div className="ant-fair-head">
                      <p className="ant-fair-title">{t("hero.fairLabel")}</p>
                      <span className="gx-kicker">Fair Mint</span>
                    </div>
                    <p className="ant-fair-body">{t("hero.fair")}</p>
                  </div>
                  <dl className="ant-fair-facts">
                    <div className="ant-fair-fact">
                      <dt>{t("mint.presale")}</dt>
                      <dd>0.016 ANTB</dd>
                    </div>
                    <div className="ant-fair-fact">
                      <dt>{t("mint.open")}</dt>
                      <dd>≤ 0.16 ANTB</dd>
                    </div>
                    <div className="ant-fair-fact">
                      <dt>{t("vest.title")}</dt>
                      <dd>20% + 5D</dd>
                    </div>
                  </dl>
                  <div className="ant-console-cmd">
                    <EditionStatus language={language} />
                  </div>
                </div>
              </div>
            </section>

            <section className="gx-band"><div className="gx-container py-10"><EditionSummary language={language} /></div></section>

            <section className="gx-container gx-chapter">
              <div className={`${rise} gx-chapter-heading`}>
                <div>
                  <p className="gx-kicker">{t("life.kicker")}</p>
                  <h2 className="mt-2">{t("life.title")}</h2>
                </div>
                <span className="gx-chapter-note">{t("life.note")}</span>
              </div>
              <div className="ant-timeline-rail" role="tablist" aria-label={t("life.title")}>
                {[1, 2, 3, 4, 5].map((item) => (
                  <button key={item} type="button" role="tab" aria-selected={phase === item - 1} aria-pressed={phase === item - 1} className={`ant-step-tab ${phase === item - 1 ? "ant-step-tab-active" : ""}`} onClick={() => setPhase(item - 1)}>
                    <span className="gx-mono gx-pri text-[11px]">STEP 0{item}</span>
                    <span className="text-base font-semibold">{phases[item - 1]?.title}</span>
                  </button>
                ))}
              </div>
              <div key={phase} className="gx-swap ant-timeline-stage">
                <div>
                  <div className="flex items-baseline gap-4">
                    <span className="ant-stage-watermark" aria-hidden="true">0{phase + 1}</span>
                    <p className="gx-kicker">STAGE 0{phase + 1} / 05</p>
                  </div>
                  <h3 className="mt-3 text-3xl font-semibold" style={{ fontFamily: "var(--font-display)" }}>{phases[phase]?.title}</h3>
                  <p className="gx-muted mt-4 max-w-xl text-base leading-8">{phases[phase]?.body}</p>
                </div>
                <div className="ant-stage-visual"><GenerativeCard id={phase * 131071 + 19} kind={phase === 0 ? "presale" : "open"} className="h-full w-full" /></div>
              </div>
            </section>

            <section className="gx-container pb-16">
              <div className={`${rise} gx-chapter-heading`}>
                <div>
                  <p className="gx-kicker">{t("calc.kicker")}</p>
                  <h2 className="mt-2">{t("calc.title")}</h2>
                </div>
                <span className="gx-chapter-note">{t("calc.note")}</span>
              </div>
              <EditionCalculator language={language} />
            </section>
            <footer className="gx-footer gx-mono gx-muted px-6 py-8 text-center text-xs">{t("footer.risk")}</footer>
          </main>
        )}

        {page && (
          <Shell
            key={view}
            rise={rise}
            index={page[0]}
            code={page[1]}
            title={t(page[2])}
            lead={t(page[3])}
            seed={page[4]}
            foot={t("footer.risk")}
          >
            {view === "market" && <EditionInner language={language} view="market" />}
            {view === "commands" && <EditionInner language={language} view="commands" />}
            {view === "vault" && <EditionInner language={language} view="vault" />}
            {view === "duel" && <EditionInner language={language} view="duel" />}
            {view === "rules" && (
              <div><EditionStatus language={language} /><div className="gx-rules mt-8">
                <nav className="gx-toc" aria-label={t("rules.toc")}>
                  {rules.map((_, index) => index + 1).map((item) => (
                    <button key={item} type="button" onClick={() => {
                      const target = ruleRefs.current[item];
                      const box = scroller.current;
                      if (!target || !box) return;
                      box.scrollTop += target.getBoundingClientRect().top - box.getBoundingClientRect().top - 12;
                    }}>
                      <span>{String(item).padStart(2, "0")}</span>{rules[item - 1]?.title}
                    </button>
                  ))}
                </nav>
                <div className="space-y-5">
                  {rules.map((_, index) => index + 1).map((item) => (
                    <section key={item} className="gx-rule" ref={(node) => { ruleRefs.current[item] = node; }}>
                      <span className="gx-rule-no" aria-hidden="true">{String(item).padStart(2, "0")}</span>
                      <p className="gx-mono gx-pri text-xs">{String(item).padStart(2, "0")}</p>
                      <h2 className="mt-2 text-2xl font-bold">{rules[item - 1]?.title}</h2>
                      <div className="mt-4 space-y-3">
                        {(rules[item - 1]?.body ?? "").split("\n").filter(Boolean).map((line) => line.startsWith("!")
                          ? <p key={line} className="gx-callout">{line.slice(1)}</p>
                          : <p key={line} className="gx-muted text-sm leading-7">{line}</p>)}
                      </div>
                    </section>
                  ))}
                </div>
              </div></div>
            )}
            {view === "ladder" && <EditionInner language={language} view="ladder" />}
            {view === "tokenomics" && <TokenReference language={language} />}
            {view === "rarity" && <><EditionStatus language={language} /><div className="mt-8"><RarityReference language={language} /></div></>}
          </Shell>
        )}
      </div>
    </div>
  );
}

function Shell({ rise, index, code, title, lead, seed, foot, children }: { rise: string; index: string; code: string; title: string; lead: string; seed: number; foot: string; children: ReactNode }) {
  return (
    <main className="ant-view-stage">
      <section className="gx-container gx-page-hero">
        <div className={`${rise} ant-stagger-1 min-w-0`}>
          <p className="gx-kicker">{index} / {code}</p>
          <h1 className="gx-page-title mt-4">{title}<span className="gx-pri">.</span></h1>
          <p className="gx-muted mt-5 max-w-xl text-base leading-8">{lead}</p>
        </div>
        <div className={`${rise} ant-stagger-2 gx-page-art`} aria-hidden="true">
          <GenerativeCard id={seed} kind="open" className="h-full w-full" />
          <span className="gx-page-index">{index}</span>
        </div>
      </section>
      <div className="gx-container gx-exhibit-caption"><span>ANTAGENT / {code}</span><ArrowDownRight className="gx-pri" size={16} aria-hidden="true" /></div>
      <div className={`${rise} ant-stagger-3 gx-container py-12`}>{children}</div>
      <footer className="gx-footer gx-mono gx-muted px-6 py-8 text-center text-xs">{foot}</footer>
    </main>
  );
}

function Book({ title, hint, columns, rows, empty }: { title: string; hint: string; columns: string[]; rows: string[][]; empty: string }) {
  return (
    <section className="gx-panel mt-8 p-5">
      <h2 className="text-2xl font-bold">{title}</h2>
      <p className="gx-muted mt-1 text-xs">{hint}</p>
      <div className="gx-book-row gx-muted mt-4 text-xs">{columns.map((column) => <span key={column}>{column}</span>)}</div>
      {rows.map((cells) => (
        <div key={cells.join("-")} className="gx-book-row">
          {cells.map((cell, index) => <span key={`${cells[0]}-${index}`} className={index === 0 ? "gx-pri" : ""}>{cell}</span>)}
        </div>
      ))}
      {rows.length === 0 && <p className="gx-muted py-8 text-sm">{empty}</p>}
    </section>
  );
}
