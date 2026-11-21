"use client";

import { useEffect, useRef, useState, type PointerEvent, type ReactNode, type UIEvent } from "react";
import { ArrowDownRight, Droplets, Flame, Gift, Shuffle } from "lucide-react";
import { encodeFunctionData, formatEther, isAddress, parseAbi, parseUnits } from "viem";
import { useFlapSdk } from "@/lib/flap-sdk";
import { CopyButton } from "@/components/flap/CopyButton";

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
const VIEWS = ["home", "market", "commands", "vault", "tokenomics", "ladder", "duel", "rules"] as const;
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
const FLOW = "oklch(0.62 0.24 285)";
const INK = "#000000";
const PAPER = "oklch(0.985 0 0)";
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

const LOOK = `
.gx-app {
  --background: oklch(0.12 0 0);
  --background-deep: oklch(0.09 0 0);
  --foreground: oklch(0.985 0 0);
  --card: oklch(0.18 0.002 88);
  --primary: oklch(0.62 0.24 285);
  --primary-foreground: oklch(0.97 0.02 285);
  --secondary: oklch(0.24 0.003 88);
  --muted: oklch(0.25 0.005 250);
  --muted-foreground: oklch(0.74 0.008 88);
  --border: oklch(1 0 0 / 12%);
  --gold: oklch(0.804 0.135 84);
  --font-display: "Bebas Neue", "Noto Sans SC", ui-sans-serif, system-ui, sans-serif;
  --font-sans: "Barlow", "Noto Sans SC", ui-sans-serif, system-ui, sans-serif;
  --font-poster: "Bebas Neue", "Noto Sans SC", sans-serif;
  --font-mono: "JetBrains Mono", ui-monospace, monospace;
  --ease-cine: cubic-bezier(0.16, 1, 0.3, 1);
  --shadow-pop: 0 30px 60px -30px oklch(0 0 0 / 0.85);
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
.gx-display { font-family: var(--font-display); font-weight: 400; letter-spacing: 0; line-height: .9; }
.gx-poster { display: inline-block; overflow: visible; vertical-align: -0.06em; }
.gx-fill { background: var(--primary); color: var(--primary-foreground); }
.gx-soft { background: var(--muted); }
.gx-line { border-color: var(--border); }
.gx-header { position: sticky; top: 0; z-index: 30; border-bottom: 1px solid color-mix(in oklab, var(--foreground) 12%, transparent); background: color-mix(in oklab, var(--background) 82%, transparent); backdrop-filter: blur(16px); }
.gx-band { border-block: 1px solid color-mix(in oklab, var(--foreground) 12%, transparent); }
.gx-footer { border-top: 1px solid color-mix(in oklab, var(--foreground) 12%, transparent); }
.gx-container { width: min(1120px, calc(100% - 80px)); margin-inline: auto; }
.gx-wordmark { display: inline-flex; align-items: baseline; font-family: var(--font-display); font-weight: 700; letter-spacing: .04em; line-height: 1; color: var(--foreground); white-space: nowrap; }
.gx-wordmark-seven { color: var(--primary); margin-left: .02em; text-shadow: 0 0 18px color-mix(in oklab, var(--primary) 60%, transparent); }
.gx-kicker { font: 10px var(--font-mono); color: var(--primary); }
.gx-heading { font-size: 112px; line-height: .9; letter-spacing: 0; font-weight: 400; font-family: var(--font-display); }
.gx-heading-seven { color: var(--primary); text-shadow: 0 0 28px color-mix(in oklab, var(--primary) 55%, transparent); }
.gx-char { display: inline-block; opacity: 0; animation: gx-char-in .9s var(--ease-cine) forwards; }
@keyframes gx-char-in { from { opacity: 0; transform: translateY(.35em); filter: blur(10px); } to { opacity: 1; transform: none; filter: none; } }
.gx-intro { position: relative; padding-block: 30px 0; --hp: 0; }
.gx-ambient { position: absolute; inset: -10% -20%; z-index: 0; pointer-events: none; background: radial-gradient(42% 38% at var(--ax, 30%) var(--ay, 20%), color-mix(in oklab, var(--primary) 13%, transparent), transparent 70%); animation: gx-breathe 7s ease-in-out infinite; }
@keyframes gx-breathe { 0%, 100% { opacity: .7; } 50% { opacity: 1; } }
.gx-title-row { display: grid; grid-template-columns: 1.6fr 1fr; align-items: end; gap: 48px; padding-bottom: 26px; position: relative; z-index: 1; transform: translateY(calc(var(--hp) * -40px)) scale(calc(1 - var(--hp) * .06)); opacity: calc(1 - var(--hp) * .7); filter: blur(calc(var(--hp) * 4px)); transform-origin: 0 100%; }
.gx-manifesto { position: relative; z-index: 1; }
.gx-fair { padding: 22px 0 30px; border-top: 1px solid var(--border); }
.gx-fair-title { font: 650 28px/1.25 var(--font-sans); letter-spacing: -0.02em; }
.gx-fair-title span { margin-left: 14px; color: var(--primary); font-weight: 560; }
.gx-fair-body { max-width: 48rem; margin-top: 12px; font-size: 17px; line-height: 1.75; }
.gx-exhibit { display: grid; grid-template-columns: minmax(0, 1fr) 240px; border-block: 1px solid var(--border); position: relative; z-index: 1; transform: scale(calc(1 - var(--hp) * .04)); transform-origin: 50% 0; }
.gx-art-stage { position: relative; min-height: 310px; overflow: hidden; background: #000; }
.gx-exhibit-rail { display: flex; flex-direction: column; justify-content: space-between; gap: 22px; padding: 22px 0 22px 28px; border-left: 1px solid var(--border); }
.gx-exhibit-caption { display: flex; justify-content: space-between; padding: 14px 0; font: 9px var(--font-mono); color: var(--muted-foreground); position: relative; z-index: 1; }
.gx-parallax { transform: translateY(calc(var(--par, 0px) * -1)); }
.gx-rise { opacity: .15; transform: translateY(18px); transition: opacity 1s var(--ease-cine), transform 1.2s var(--ease-cine); }
.gx-rise.gx-in { opacity: 1; transform: none; }
.gx-metrics { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); }
.gx-metrics > div { padding: 24px; border-left: 1px solid var(--border); }
.gx-metrics > div:first-child { padding-left: 0; border-left: 0; }
.gx-chapter { padding-block: 60px; }
.gx-chapter-heading { position: relative; display: grid; grid-template-columns: 160px minmax(0, 1fr) auto; align-items: center; gap: 24px; padding-bottom: 22px; border-bottom: 1px solid var(--border); }
.gx-chapter-heading h2 { font: 700 32px var(--font-sans); line-height: 1.3; }
.gx-chapter-note { font-size: 12px; color: var(--muted-foreground); }
.gx-chapter-heading::after { content: ""; position: absolute; left: 0; bottom: -1px; height: 1px; width: 100%; background: linear-gradient(90deg, transparent, var(--primary), transparent); transform: scaleX(0); transform-origin: left; }
.gx-chapter-heading.gx-in::after { animation: gx-underline 1.6s var(--ease-cine) .25s forwards; }
@keyframes gx-underline { 0% { transform: scaleX(0); opacity: 1; } 70% { transform: scaleX(1); opacity: 1; } 100% { transform: scaleX(1); opacity: .25; } }
.gx-phase-nav { display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); border-bottom: 1px solid var(--border); }
.gx-phase-button { position: relative; width: 100%; height: 58px; display: flex; align-items: center; justify-content: flex-start; gap: 14px; padding: 0 12px; color: var(--muted-foreground); }
.gx-phase-button::after { content: ""; position: absolute; bottom: -1px; left: 12px; right: 12px; height: 2px; background: var(--primary); transform: scaleX(0); transform-origin: left; transition: transform .5s var(--ease-cine); }
.gx-phase-active { color: var(--primary); }
.gx-phase-active::after { transform: scaleX(1); }
.gx-phase-detail { display: grid; grid-template-columns: 160px minmax(0, 1fr) 190px; gap: 32px; align-items: center; min-height: 260px; padding-top: 28px; }
.gx-phase-number { font: 150px var(--font-display); color: color-mix(in oklab, var(--primary) 28%, var(--background)); line-height: 1; }
.gx-phase-art { height: 190px; overflow: hidden; }
.gx-workspace { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); padding-bottom: 64px; }
.gx-mint-tool { min-width: 0; padding: 32px 40px 32px 0; }
.gx-vesting-tool { min-width: 0; padding: 32px 0 32px 40px; border-left: 1px solid var(--border); }
.gx-mint-mark { border: 1px solid var(--border); transition: background .4s, border-color .4s, transform .5s var(--ease-cine); }
.gx-mint-mark-active { background: color-mix(in oklab, var(--primary) 18%, var(--background)); border-color: var(--primary); transform: translateY(-3px); }
.gx-swap { animation: gx-swap .55s cubic-bezier(.2,.7,.2,1); }
@keyframes gx-swap { from { opacity: 0; transform: translateY(12px); } to { opacity: 1; transform: none; } }
.gx-live-dot { width: 8px; height: 8px; border-radius: 999px; background: var(--primary); box-shadow: 0 0 0 0 color-mix(in oklab, var(--primary) 60%, transparent); animation: gx-live-pulse 1.8s ease-out infinite; }
@keyframes gx-live-pulse { to { box-shadow: 0 0 0 10px transparent; } }
.gx-live-bar { transform-origin: left; animation: gx-live-grow 1.4s cubic-bezier(.2,.8,.2,1) both; }
@keyframes gx-live-grow { from { transform: scaleX(0); } }
.gx-app .ac-tab { position: relative; height: 40px; padding: 0 2px; border: 0; background: transparent; color: var(--muted-foreground); white-space: nowrap; cursor: pointer; }
.gx-app .ac-tab:hover, .gx-app .ac-tab-active { color: var(--foreground); }
.ac-tab-active::after { content: ""; position: absolute; left: 50%; bottom: 3px; width: 18px; height: 2px; border-radius: 2px; background: var(--primary); box-shadow: 0 0 10px var(--primary); transform: translateX(-50%); }
.gx-x { display: inline-flex; align-items: center; justify-content: center; width: 40px; height: 40px; border-radius: 999px; border: 1px solid color-mix(in oklab, var(--primary) 34%, transparent); background: linear-gradient(180deg, color-mix(in oklab, white 8%, transparent), transparent 46%), color-mix(in oklab, var(--card) 62%, black); color: var(--foreground); }
.gx-x svg { width: 15px; height: 15px; fill: currentColor; }
.gx-x:hover { color: white; border-color: var(--primary); }
.gx-lang { display: inline-flex; align-items: center; height: 40px; padding: 3px; border-radius: 999px; border: 1px solid color-mix(in oklab, var(--primary) 34%, transparent); background: linear-gradient(180deg, color-mix(in oklab, white 8%, transparent), transparent 46%), color-mix(in oklab, var(--card) 62%, black); box-shadow: inset 0 1px 0 color-mix(in oklab, white 14%, transparent), 0 10px 24px color-mix(in oklab, black 40%, transparent); }
.gx-lang button { height: 32px; min-width: 52px; padding: 0 14px; border: 0; border-radius: 999px; background: transparent; color: color-mix(in oklab, var(--foreground) 88%, transparent); font: 600 14px/1 var(--font-sans); letter-spacing: 0; cursor: pointer; }
.gx-lang button[aria-pressed="true"] { color: white; background: linear-gradient(180deg, color-mix(in oklab, white 22%, var(--primary)), var(--primary)); box-shadow: 0 0 0 1px color-mix(in oklab, white 28%, var(--primary)), 0 0 16px color-mix(in oklab, var(--primary) 58%, transparent); }
.gx-menu { display: inline-flex; align-items: center; height: 34px; padding: 0 14px; border: 1px solid color-mix(in oklab, var(--foreground) 18%, transparent); border-radius: 999px; background: transparent; color: var(--foreground); font: 500 11px var(--font-mono); letter-spacing: .16em; cursor: pointer; }
.gx-menu[aria-expanded="true"] { color: var(--primary); border-color: color-mix(in oklab, var(--primary) 55%, transparent); }
.gx-fold { border-top: 1px solid color-mix(in oklab, var(--foreground) 12%, transparent); }
.gx-fold button { display: flex; align-items: center; gap: 16px; width: 100%; height: 48px; border: 0; border-bottom: 1px solid color-mix(in oklab, var(--foreground) 8%, transparent); background: transparent; color: var(--muted-foreground); text-align: left; cursor: pointer; }
.gx-fold button[aria-pressed="true"] { color: var(--foreground); }
.gx-fold-no { width: 1.6em; font: 11px var(--font-mono); color: var(--primary); }
.gx-btn { display: inline-flex; align-items: center; justify-content: center; gap: 8px; height: 36px; padding: 0 12px; border-radius: 6px; font-weight: 600; }
.gx-btn-lg { height: 44px; width: 100%; padding: 0 16px; justify-content: center; }
.gx-btn-split { justify-content: space-between; }
.gx-app input[type="range"] { width: 100%; height: 6px; border-radius: 999px; appearance: none; background: linear-gradient(90deg, var(--primary) var(--fill, 0%), color-mix(in oklab, var(--primary) 20%, transparent) var(--fill, 0%)); accent-color: var(--primary); cursor: pointer; }
.gx-app input[type="range"]::-webkit-slider-thumb { appearance: none; width: 16px; height: 16px; border-radius: 999px; border: 1px solid color-mix(in oklab, var(--primary) 50%, transparent); background: var(--background); }
.gx-app input[type="range"]::-moz-range-thumb { width: 16px; height: 16px; border: 1px solid color-mix(in oklab, var(--primary) 50%, transparent); border-radius: 999px; background: var(--background); }
.gx-btn-solid { background: var(--primary); color: var(--primary-foreground); }
.gx-btn-outline { border: 1px solid var(--border); }
.gx-app .gx-btn-outline { border: 1px solid var(--border); background: transparent; color: var(--foreground); }
.gx-app button.gx-pri { color: var(--primary); }
.gx-app .gx-btn-on { background: var(--primary); color: white; }
.gx-seg { display: inline-flex; gap: 4px; padding: 4px; border: 1px solid var(--border); border-radius: 10px; }
.gx-app .gx-seg button { height: 40px; min-width: 96px; padding: 0 18px; border: 1px solid transparent; border-radius: 8px; background: transparent; color: color-mix(in oklab, var(--foreground) 58%, transparent); font: 600 15px/1 var(--font-sans); }
.gx-app .gx-seg button[aria-pressed="true"] { border-color: transparent; background: var(--primary); color: white; box-shadow: 0 0 0 1px color-mix(in oklab, white 30%, var(--primary)), 0 0 20px color-mix(in oklab, var(--primary) 62%, transparent); }
.gx-count { display: grid; grid-template-columns: repeat(10, minmax(0, 1fr)); gap: 4px; }
.gx-count button { height: 32px; border: 1px solid var(--border); border-radius: 6px; background: transparent; color: var(--muted-foreground); font: 600 12px var(--font-mono); cursor: pointer; }
.gx-count button[aria-pressed="true"] { color: white; border-color: var(--primary); background: color-mix(in oklab, var(--primary) 28%, transparent); }
.gx-chip { border: 1px solid var(--border); padding: 4px 8px; font: 11px var(--font-mono); color: var(--muted-foreground); }
.gx-track { height: 8px; overflow: hidden; border-radius: 999px; background: var(--muted); }
.gx-track > div { height: 100%; background: var(--primary); }
.hc-stage { display: grid; place-items: center; padding: 3rem 1rem; background: #000; }
.hc-scene { position: relative; perspective: 1100px; width: min(300px, 72vw); }
.hc-shadow { position: absolute; inset: 12% 8% -6%; border-radius: 24px; background: transparent; }
.hc-card { --rx: 0deg; --ry: 0deg; --mx: 50%; --my: 30%; position: relative; aspect-ratio: 5 / 7; border-radius: 20px; padding: 6px; background: linear-gradient(140deg, color-mix(in oklab, var(--primary) 90%, var(--foreground)), color-mix(in oklab, var(--primary) 35%, var(--background)) 40%, var(--primary) 70%, color-mix(in oklab, var(--primary) 30%, var(--background))); transform: rotateX(var(--rx)) rotateY(var(--ry)); transform-style: preserve-3d; transition: transform .6s var(--ease-cine); box-shadow: var(--shadow-pop); animation: hc-float 6s ease-in-out infinite; }
.hc-card[data-active="true"] { transition: transform .08s linear; animation-play-state: paused; }
.hc-inner { position: relative; height: 100%; border-radius: 15px; background: #000; display: flex; flex-direction: column; overflow: hidden; border: 1px solid color-mix(in oklab, var(--primary) 30%, transparent); }
.hc-head, .hc-foot { display: flex; justify-content: space-between; align-items: center; padding: .7rem .9rem; }
.hc-tier { font-family: var(--font-mono); font-size: .62rem; letter-spacing: .18em; color: var(--primary); border: 1px solid color-mix(in oklab, var(--primary) 50%, transparent); padding: .15rem .45rem; border-radius: 999px; }
.hc-art { position: relative; flex: 1; margin: 0 .6rem; border-radius: 10px; overflow: hidden; border: 1px solid color-mix(in oklab, var(--primary) 25%, transparent); }
.hc-art canvas, .gx-phase-art canvas, .gx-page-art canvas { display: block; width: 100%; height: 100%; }
.hc-label { font-family: var(--font-mono); font-size: .55rem; letter-spacing: .2em; color: var(--muted-foreground); }
.hc-serial { font-family: var(--font-display); font-size: 1.7rem; line-height: 1; }
.hc-edition { font-family: var(--font-display); font-size: 1.2rem; line-height: 1; color: var(--primary); text-align: right; }
.hc-foil, .hc-glare { position: absolute; inset: 0; border-radius: 20px; pointer-events: none; }
.hc-foil { opacity: .1; background: linear-gradient(115deg, transparent 25%, color-mix(in oklab, var(--primary) 35%, transparent) 45%, color-mix(in oklab, var(--foreground) 20%, transparent) 50%, transparent 65%); background-size: 300% 300%; background-position: var(--mx) var(--my); animation: hc-foil 9s linear infinite; }
.hc-card[data-active="true"] .hc-foil { opacity: .18; animation: none; }
.hc-glare { background: radial-gradient(circle at var(--mx) var(--my), color-mix(in oklab, var(--foreground) 35%, transparent), transparent 45%); mix-blend-mode: overlay; opacity: 0; }
.hc-card[data-active="true"] .hc-glare { opacity: .4; }
@keyframes hc-float { 0%,100% { transform: rotateX(4deg) rotateY(-8deg) translateY(0); } 50% { transform: rotateX(-3deg) rotateY(8deg) translateY(-10px); } }
@keyframes hc-foil { to { background-position: 300% 0; } }
@keyframes hc-pulse { 50% { opacity: .7; transform: scale(1.05); } }
.gx-page-hero { display: grid; grid-template-columns: minmax(0, 1.5fr) minmax(0, 1fr); gap: 48px; align-items: end; padding-block: 56px 28px; }
.gx-page-title { font-family: var(--font-display); font-size: 76px; line-height: 1; font-weight: 700; }
.gx-page-art { position: relative; aspect-ratio: 4 / 3; border: 1px solid color-mix(in oklab, var(--foreground) 12%, transparent); border-radius: 18px; overflow: hidden; background: #000; }
.gx-page-index { position: absolute; right: 14px; bottom: 6px; font: 400 64px var(--font-mono); color: color-mix(in oklab, var(--primary) 70%, transparent); line-height: 1; }
.gx-app ::selection { background: var(--primary); color: var(--primary-foreground); }
.gx-panel, .gx-tiles > div, .gx-rule, .gx-term, .gx-alloc { position: relative; overflow: hidden; border: 1px solid color-mix(in oklab, var(--foreground) 12%, transparent); border-radius: 18px; background: color-mix(in oklab, var(--card) 86%, black); transition: border-color .35s, box-shadow .35s, transform .4s var(--ease-cine); }
.gx-panel:hover, .gx-rule:hover, .gx-term:hover, .gx-tiles > div:hover, .gx-alloc:hover { border-color: var(--primary); box-shadow: 0 0 0 1px color-mix(in oklab, var(--primary) 55%, transparent), 0 18px 42px -28px color-mix(in oklab, var(--primary) 80%, transparent); }
.gx-tiles > div:hover, .gx-term:hover, .gx-panel:hover { transform: translateY(-4px); }
.gx-tiles > div::after, .gx-panel::after { content: ""; position: absolute; z-index: 0; inset: auto -30% -60% auto; width: 70%; aspect-ratio: 1; border-radius: 50%; background: radial-gradient(circle, color-mix(in oklab, var(--primary) 28%, transparent), transparent 70%); pointer-events: none; }
.gx-tiles > div > *, .gx-panel > * { position: relative; z-index: 1; }
.gx-tiles { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 12px; }
.gx-tiles > div { padding: 22px; }
.gx-rule { position: relative; overflow: hidden; padding: 28px; }
.gx-rule-no { position: absolute; top: -18px; right: 14px; font-size: 7rem; font-weight: 800; line-height: 1; color: color-mix(in oklab, var(--primary) 12%, transparent); }
.gx-term { position: relative; display: flex; flex-direction: column; padding: 46px 22px 22px; }
.gx-term::before { content: ""; position: absolute; top: 18px; left: 22px; width: 8px; height: 8px; border-radius: 50%; background: var(--primary); box-shadow: 14px 0 0 var(--border), 28px 0 0 var(--border); }
.gx-term-fn { margin-top: 10px; padding: 8px 10px; border-radius: 8px; background: var(--background); font-size: 11px; color: var(--primary); word-break: break-all; }
.gx-cmd-group { margin-bottom: 48px; }
.gx-cmd-label { display: flex; align-items: center; gap: 14px; margin-bottom: 18px; font-size: 1.4rem; font-weight: 700; }
.gx-cmd-label::after { content: ""; flex: 1; height: 1px; background: linear-gradient(90deg, var(--primary), transparent); }
.gx-field { height: 40px; width: 100%; max-width: 32rem; border: 1px solid var(--border); border-radius: 8px; background: var(--background); padding: 0 12px; color: var(--foreground); font: 12px var(--font-mono); }
.gx-alert { color: oklch(0.72 0.17 25); }
.gx-alloc { display: flex; width: 100%; align-items: center; gap: 14px; padding: 14px 16px; color: inherit; font: inherit; text-align: left; cursor: pointer; transition: border-color .3s, transform .3s; }
.gx-alloc-active, .gx-alloc:hover { border-color: var(--primary); transform: translateX(6px); }
.gx-dot { width: 12px; height: 12px; flex: none; border-radius: 999px; background: var(--primary); }
.gx-chip-pri { border-color: color-mix(in oklab, var(--primary) 40%, transparent); background: color-mix(in oklab, var(--primary) 12%, transparent); color: var(--primary); border-radius: 999px; }
.gx-token-layout { display: grid; align-items: center; gap: 40px; }
.gx-donut-wrap { position: relative; width: 100%; max-width: 420px; margin-inline: auto; }
.gx-donut { width: 100%; display: block; transform: rotate(-90deg); filter: drop-shadow(0 0 30px color-mix(in oklab, var(--primary) 35%, transparent)); }
.gx-donut-lock { position: absolute; z-index: 2; color: var(--primary); font-size: 12px; font-weight: 700; line-height: 1; pointer-events: none; transform: translate(-50%, -50%); }
.gx-donut-center { position: absolute; inset: 0; display: grid; place-content: center; text-align: center; pointer-events: none; }
.gx-callout { border-left: 3px solid var(--primary); border-radius: 0 10px 10px 0; background: color-mix(in oklab, var(--primary) 16%, transparent); padding: 12px 16px; color: var(--foreground); font-size: .875rem; font-weight: 500; line-height: 1.75rem; }
.gx-vest { flex: 1; min-width: 0; border-radius: 2px 2px 0 0; transition: height .5s, background-color .5s; }
.gx-vest-on { background: var(--primary); }
.gx-vest-off { background: var(--muted); }
@media (min-width: 760px) { .gx-token-layout { grid-template-columns: minmax(220px, 42%) minmax(0, 1fr); } }
.gx-reading-progress { position: absolute; bottom: -1px; left: 0; height: 1px; width: 100%; background: var(--primary); transform: scaleX(0); transform-origin: left; }
.gx-opening { position: absolute; inset: 0; z-index: 60; pointer-events: none; display: grid; place-items: center; background: var(--background); animation: gx-open-fade .9s var(--ease-cine) 1.55s forwards; }
.gx-opening-bar { position: absolute; left: 0; right: 0; height: 50%; background: var(--background); }
.gx-opening-bar-top { top: 0; animation: gx-open-up 1.1s var(--ease-cine) 1.35s forwards; }
.gx-opening-bar-bottom { bottom: 0; animation: gx-open-down 1.1s var(--ease-cine) 1.35s forwards; }
.gx-opening-line { position: absolute; top: 50%; left: 15%; width: 70%; height: 1px; background: linear-gradient(90deg, transparent, var(--primary), var(--foreground), var(--primary), transparent); box-shadow: 0 0 24px var(--primary), 0 0 80px var(--primary); transform: scaleX(0); animation: gx-open-line 1.2s var(--ease-cine) .15s forwards, gx-open-fade .5s ease 1.3s forwards; }
.gx-opening-mark { position: relative; font: 700 clamp(28px, 4vw, 52px) var(--font-display); letter-spacing: .5em; padding-left: .5em; opacity: 0; filter: blur(12px); animation: gx-open-mark 1s var(--ease-cine) .45s forwards, gx-open-fade .45s ease 1.25s forwards; }
@keyframes gx-open-line { to { transform: scaleX(1); } }
@keyframes gx-open-mark { to { opacity: 1; filter: blur(0); letter-spacing: .28em; } }
@keyframes gx-open-up { to { transform: translateY(-100%); } }
@keyframes gx-open-down { to { transform: translateY(100%); } }
@keyframes gx-open-fade { to { opacity: 0; visibility: hidden; } }
.gx-grain { position: absolute; inset: 0; z-index: 55; width: 100%; height: 100%; pointer-events: none; opacity: .045; mix-blend-mode: overlay; }
.gx-vignette { position: absolute; inset: 0; z-index: 54; pointer-events: none; background: radial-gradient(ellipse at 50% 45%, transparent 55%, color-mix(in oklab, var(--background) 70%, transparent) 100%); }
.gx-streak { position: absolute; left: -20%; right: -20%; top: 42%; height: 2px; z-index: 8; pointer-events: none; background: linear-gradient(90deg, transparent, color-mix(in oklab, var(--primary) 70%, transparent) 40%, var(--foreground) 50%, color-mix(in oklab, var(--primary) 70%, transparent) 60%, transparent); filter: blur(1px); box-shadow: 0 0 30px var(--primary), 0 0 80px var(--primary); opacity: 0; transform: translateX(-60%) scaleY(.6); animation: gx-streak 9s var(--ease-cine) 2.4s infinite; }
@keyframes gx-streak { 0% { opacity: 0; transform: translateX(-60%) scaleY(.6); } 8% { opacity: .8; } 22% { opacity: 0; transform: translateX(60%) scaleY(1.4); } 100% { opacity: 0; transform: translateX(60%); } }
.gx-book-row { display: grid; grid-template-columns: 1.4fr 64px 80px 56px; gap: 8px; align-items: center; border-bottom: 1px solid var(--border); padding: 12px 0; font-family: var(--font-mono); font-size: 13px; }
.gx-book-row span:not(:first-child) { text-align: right; }
.gx-market { display: grid; gap: 32px; }
.gx-segment { display: inline-flex; align-items: center; height: 40px; padding: 3px; border-radius: 999px; border: 1px solid color-mix(in oklab, var(--primary) 34%, transparent); background: linear-gradient(180deg, color-mix(in oklab, white 8%, transparent), transparent 46%), color-mix(in oklab, var(--card) 62%, black); box-shadow: inset 0 1px 0 color-mix(in oklab, white 14%, transparent); }
.gx-segment button { height: 32px; padding: 0 16px; border: 0; border-radius: 999px; background: transparent; color: color-mix(in oklab, var(--foreground) 88%, transparent); font: 600 14px/1 var(--font-sans); letter-spacing: 0; cursor: pointer; }
.gx-segment button[aria-pressed="true"] { color: white; background: linear-gradient(180deg, color-mix(in oklab, white 22%, var(--primary)), var(--primary)); box-shadow: 0 0 0 1px color-mix(in oklab, white 28%, var(--primary)), 0 0 16px color-mix(in oklab, var(--primary) 58%, transparent); }
.gx-bento { display: grid; gap: 12px; grid-template-columns: 1fr 1fr; }
.gx-tile-no { font-family: var(--font-mono); font-size: 12px; letter-spacing: .08em; color: var(--primary); }
.gx-bento .gx-tile-hero { background: linear-gradient(165deg, color-mix(in oklab, var(--primary) 46%, var(--card)) 0%, color-mix(in oklab, var(--primary) 18%, black) 46%, color-mix(in oklab, var(--card) 40%, black) 100%); border-color: color-mix(in oklab, var(--primary) 34%, transparent); }
.gx-tile-value { margin-top: 18px; font-family: var(--font-mono); font-size: clamp(1.85rem, 2.6vw, 2.15rem); font-weight: 500; letter-spacing: -.04em; line-height: 1; color: var(--foreground); }
.gx-tile-value span { margin-left: 6px; font-size: 12px; font-weight: 400; letter-spacing: .04em; color: var(--muted-foreground); }
.gx-flow-line { position: relative; display: flex; justify-content: space-between; gap: 8px; margin-top: 56px; padding-top: 18px; border-top: 1px dashed color-mix(in oklab, var(--primary) 40%, var(--border)); }
.gx-flow-line::before { content: ""; position: absolute; top: -2px; left: 0; width: 12%; height: 3px; border-radius: 3px; background: var(--primary); box-shadow: 0 0 16px var(--primary); animation: gx-flow 4s linear infinite; }
.gx-flow-line span { font-family: var(--font-mono); font-size: 12px; letter-spacing: .12em; color: var(--muted-foreground); animation: gx-blink 1.6s ease-in-out infinite alternate; }
@keyframes gx-blink { to { color: var(--primary); } }
@keyframes gx-flow { from { left: 0; } to { left: 88%; } }
.gx-toc { display: flex; flex-direction: column; gap: 2px; border-left: 1px solid var(--border); }
.gx-toc button { display: flex; gap: 12px; width: 100%; padding: 7px 14px; margin-left: -1px; border: 0; border-left: 2px solid transparent; background: transparent; color: var(--muted-foreground); font: inherit; font-size: 13px; text-align: left; cursor: pointer; }
.gx-toc button:hover { color: var(--foreground); border-left-color: var(--primary); }
.gx-toc span { font-family: var(--font-mono); color: var(--primary); }
.gx-rules { display: grid; gap: 40px; }
.gx-rungs { display: grid; gap: 16px; }
.gx-rung { width: 100%; padding: 22px; border: 1px solid var(--border); background: color-mix(in oklab, var(--card) 72%, transparent); color: inherit; text-align: left; cursor: pointer; }
.gx-rung[aria-pressed="true"] { border-color: var(--primary); }
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
  .gx-container { width: calc(100% - 48px); }
  .gx-heading { font-size: 86px; }
  .gx-title-row, .gx-exhibit, .gx-page-hero, .gx-workspace, .gx-phase-detail { grid-template-columns: minmax(0, 1fr); }
  .gx-exhibit-rail, .gx-vesting-tool { border-left: 0; padding-left: 0; }
  .gx-vesting-tool { border-top: 1px solid var(--border); padding-top: 28px; }
  .gx-tiles, .gx-metrics { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .gx-phase-nav { display: flex; overflow-x: auto; overflow-y: hidden; scrollbar-width: none; }
  .gx-phase-nav::-webkit-scrollbar { display: none; }
  .gx-phase-nav > li { flex: none; }
  .gx-phase-button { width: auto; }
  .gx-phase-art, .gx-chapter-note { display: none; }
  .gx-fair-title { font-size: 24px; }
}
@media (prefers-reduced-motion: reduce) {
  .gx-opening { display: none; }
  .gx-char { opacity: 1; animation: none; }
  .gx-rise { opacity: 1; transform: none; }
  .gx-streak, .hc-card, .hc-foil, .hc-shadow, .gx-ambient, .gx-live-dot, .gx-flow-line::before { animation: none; }
  .gx-title-row, .gx-exhibit { transform: none; opacity: 1; filter: none; }
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
  symbol: "MINT.AI",
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
    const rand = rng(id + 7);
    const echoes = (kind === "team" ? 5 : 3) + Math.floor(rand() * 3);
    const sweepSpeed = 0.22 + rand() * 0.12;
    const sweepAngle = 0.5 + rand() * 0.6;
    const sparks = Array.from({ length: 30 }, () => ({ x: rand(), ph: rand(), sp: 0.08 + rand() * 0.12 }));
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
      const tx = p.active ? p.x - 0.5 : Math.sin(t * 0.4) * 0.25;
      const ty = p.active ? p.y - 0.5 : Math.cos(t * 0.3) * 0.15;
      ox += (tx - ox) * 0.08;
      oy += (ty - oy) * 0.08;
      let fs = Math.min(h * 0.72, w * 1.2);
      const cx = w / 2;
      const cy = h * 0.53;
      const aiUnits = (POSTER["A"]?.w ?? 401) + (POSTER["I"]?.w ?? 192);
      let glyphWidth = aiUnits * (fs / POSTER_EM);
      if (glyphWidth > w * 0.5) {
        fs *= (w * 0.5) / glyphWidth;
        glyphWidth = w * 0.5;
      }
      const glow = ctx.createRadialGradient(cx, cy, fs * 0.2, cx, cy, fs * 0.55);
      glow.addColorStop(0, FLOW);
      glow.addColorStop(1, "transparent");
      ctx.globalAlpha = 0.16;
      ctx.fillStyle = glow;
      ctx.fillRect(0, 0, w, h);
      ctx.strokeStyle = FLOW;
      ctx.lineWidth = dpr * 1.2;
      for (let echo = echoes; echo >= 1; echo -= 1) {
        ctx.globalAlpha = (0.08 + 0.16 * (1 - echo / (echoes + 1))) * (0.7 + 0.3 * Math.sin(t * 1.3 - echo * 0.7));
        paintPoster(ctx, "AI", cx - ox * echo * w * 0.035, cy - oy * echo * h * 0.03, fs, "stroke");
      }
      const fx = cx + ox * w * 0.02;
      const fy = cy + oy * h * 0.015;
      ctx.globalAlpha = 1;
      ctx.shadowColor = FLOW;
      ctx.shadowBlur = fs * 0.08;
      ctx.fillStyle = FLOW;
      paintPoster(ctx, "AI", fx, fy, fs, "fill");
      ctx.shadowBlur = 0;
      const pos = ((t * sweepSpeed) % 1.6) - 0.3;
      const dx = Math.cos(sweepAngle) * w;
      const dy = Math.sin(sweepAngle) * h;
      const band = ctx.createLinearGradient(cx - dx / 2, cy - dy / 2, cx + dx / 2, cy + dy / 2);
      const clamp = (v: number) => Math.min(1, Math.max(0, v));
      band.addColorStop(0, "transparent");
      band.addColorStop(clamp(pos - 0.12), "transparent");
      band.addColorStop(clamp(pos), PAPER);
      band.addColorStop(clamp(pos + 0.12), "transparent");
      band.addColorStop(1, "transparent");
      ctx.globalCompositeOperation = "lighter";
      ctx.globalAlpha = 0.75;
      ctx.fillStyle = band;
      paintPoster(ctx, "AI", fx, fy, fs, "fill");
      ctx.globalAlpha = 0.35;
      ctx.strokeStyle = PAPER;
      ctx.lineWidth = dpr;
      paintPoster(ctx, "AI", fx, fy, fs, "stroke");
      const dot = fs * 0.04;
      const dotX = fx - glyphWidth / 2 - dot * 2.2;
      const dotY = fy + fs * 0.35 - dot;
      ctx.globalCompositeOperation = "source-over";
      ctx.globalAlpha = 1;
      ctx.shadowColor = FLOW;
      ctx.shadowBlur = dot * 3 * (0.8 + 0.4 * Math.sin(t * 2));
      ctx.fillStyle = FLOW;
      ctx.fillRect(dotX - dot, dotY - dot, dot * 2, dot * 2);
      ctx.shadowBlur = 0;
      ctx.globalCompositeOperation = "lighter";
      ctx.globalAlpha = 0.25 + 0.25 * Math.sin(t * 2);
      ctx.fillStyle = PAPER;
      ctx.fillRect(dotX - dot, dotY - dot, dot * 2, dot * 2);
      ctx.fillStyle = PAPER;
      for (const spark of sparks) {
        const life = (t * spark.sp + spark.ph) % 1;
        ctx.globalAlpha = Math.sin(life * Math.PI) * 0.5;
        ctx.fillRect(spark.x * w, h * (1 - life), dpr * 1.2, dpr * 1.2);
      }
      ctx.globalCompositeOperation = "source-over";
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
      aria-label={`MINT.AI #${id}`}
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
            <span className="gx-wordmark"><Poster text="MINT" em={1} track={0.04} /><Poster text=".AI" em={1} track={0.04} className="gx-wordmark-seven" /></span>
            <span className="hc-tier">{tier}</span>
          </header>
          <div className="hc-art">
            <GenerativeCard id={id} kind={kind} className="h-full w-full" />
          </div>
          <footer className="hc-foot">
            <div>
              <p className="hc-label">AGENT ID</p>
              <p className="hc-serial"><Poster text={`#${serial}`} em={1} /></p>
            </div>
            <div>
              <p className="hc-label">EDITION</p>
              <p className="hc-edition"><Poster text="1 / 1" em={1} /></p>
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
};

export default function Component({ initialView = "home" }: { initialView?: View }) {
  const sdk = useFlapSdk({ chainId: 56 });
  const [live, setLive] = useState<Live>(EMPTY_LIVE);
  const [rooms, setRooms] = useState<WaitingRoom[]>([]);
  const [roomsReady, setRoomsReady] = useState(false);
  const [emptyRoomId, setEmptyRoomId] = useState<number | null>(null);
  const [chainTick, setChainTick] = useState(0);
  useEffect(() => {
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
  const t = (key: string, fallback?: string, params?: Record<string, string | number>) => hostT(`l.${language}.${key}`, fallback, params);
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
  const rules = [
    { title: t("rules.1.title"), body: t("rules.1.body") },
    { title: t("rules.2.title"), body: t("rules.2.body") },
    { title: t("rules.3.title"), body: t("rules.3.body") },
    { title: t("rules.4.title"), body: t("rules.4.body") },
    { title: t("rules.5.title"), body: t("rules.5.body") },
    { title: t("rules.6.title"), body: t("rules.6.body") },
    { title: t("rules.7.title"), body: t("rules.7.body") },
    { title: t("rules.8.title"), body: t("rules.8.body") },
    { title: t("rules.9.title"), body: t("rules.9.body") },
    { title: t("rules.10.title"), body: t("rules.10.body") },
    { title: t("rules.11.title"), body: t("rules.11.body") },
  ];
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
  } as const;
  const page = view === "home" ? null : pageMeta[view];

  const openView = (next: View) => {
    setMenuOpen(false);
    setView(next);
    setIntro((n) => n + 1);
    if (typeof window !== "undefined") {
      const targetPath = VIEW_PATHS[next];
      if (window.location.pathname !== targetPath) {
        window.history.pushState(null, "", targetPath);
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
      <div key={intro} className="gx-opening" aria-hidden="true">
        <span className="gx-opening-bar gx-opening-bar-top" />
        <span className="gx-opening-bar gx-opening-bar-bottom" />
        <span className="gx-opening-line" />
        <span className="gx-opening-mark"><Poster text="MINT" em={1} track={0.5} /><Poster text=".AI" em={1} track={0.5} className="gx-pri" /></span>
      </div>
      <Grain />
      <div className="gx-vignette" aria-hidden="true" />
      <div className="gx-streak" aria-hidden="true" />
      <div ref={scroller} className="gx-scroll" onScroll={onScroll}>
        <header className="gx-header">
          <div className="gx-container flex items-center justify-between gap-5 py-3">
            <button type="button" onClick={() => openView("home")} aria-label={t("brand")}><span className="gx-wordmark text-xl"><Poster text="MINT" em={1} track={0.04} /><Poster text=".AI" em={1} track={0.04} className="gx-wordmark-seven" /></span></button>
            <nav className="hidden gap-6 lg:flex" aria-label={t("brand")}>
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
          <main>
            <section
              ref={hero}
              className="gx-container gx-intro"
              onPointerMove={(event) => {
                const r = event.currentTarget.getBoundingClientRect();
                event.currentTarget.style.setProperty("--ax", `${((event.clientX - r.left) / r.width) * 100}%`);
                event.currentTarget.style.setProperty("--ay", `${((event.clientY - r.top) / r.height) * 100}%`);
              }}
            >
              <div className="gx-ambient" aria-hidden="true" />
              <div className="gx-title-row">
                <div className={`${rise} min-w-0`}>
                  <p className="gx-kicker">{t("hero.kicker")}</p>
                  <h1 className="gx-heading mt-3" aria-label="MINT.AI">
                    {"MINT.AI".split("").map((ch, index) => (
                      <span key={`${ch}-${index}`} aria-hidden="true" className="gx-char" style={{ animationDelay: `${0.15 + index * 0.07}s` }}><Poster text={ch} className={index >= 4 ? "gx-heading-seven" : undefined} /></span>
                    ))}
                  </h1>
                </div>
                <div className={`${rise} gx-manifesto`}>
                  <p className="text-2xl font-semibold leading-relaxed">{t("hero.line1")}<br className="hidden md:block" />{t("hero.line2")}</p>
                  <p className="gx-muted mt-3 text-sm">{t("hero.sub")}</p>
                </div>
              </div>
              <div className="gx-exhibit">
                <div className={`${rise} gx-art-stage hc-stage`}>
                  <div ref={stage} className="gx-parallax"><HoloCard id={cardId} kind={kind} /></div>
                </div>
                <aside className={`${rise} gx-exhibit-rail`}>
                  <div>
                    <p className="gx-kicker">{t("card.kicker")}</p>
                    <p className="mt-4 text-xl font-medium">{t("card.title1")}<br />{t("card.title2")}</p>
                    <p className="gx-muted mt-3 text-sm">{t("card.body")}</p>
                  </div>
                  <div>
                    <label className="gx-mono gx-muted mb-4 flex justify-between text-xs"><span>{t("card.id")}</span><span>{fmtInt(cardId)}</span></label>
                    <input type="range" min={1} max={TOTAL_POOL_CARDS} value={cardId} aria-label={t("card.id")} style={{ ["--fill" as string]: `${((cardId - 1) / (TOTAL_POOL_CARDS - 1)) * 100}%` }} onChange={(event) => setCardId(Number(event.target.value))} />
                    <button type="button" className="gx-btn gx-btn-lg gx-btn-outline gx-btn-split mt-5" onClick={() => setCardId(1 + Math.floor(Math.random() * TOTAL_POOL_CARDS))}>{t("card.random")}<Shuffle size={16} /></button>
                  </div>
                </aside>
              </div>
              <div className="gx-exhibit-caption"><span>{t("card.caption")}</span><ArrowDownRight className="gx-pri" size={16} aria-hidden="true" /></div>
              <div className="gx-fair">
                <p className="gx-fair-title">{t("hero.fairLabel")}<span>Fair Mint</span></p>
                <p className="gx-fair-body">{t("hero.fair")}</p>
                <div className="mt-6 max-w-3xl">{commandCard(salePhase === "refund" ? "refund" : "mint")}</div>
              </div>
            </section>

            <section className="gx-band">
              <div className="gx-container py-8">
                <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
                  <p className="gx-mono gx-pri flex items-center gap-2 text-xs"><span className="gx-live-dot" />{t(!live.cards ? "cards.pending" : salePhase === "open" ? "demo.launched" : salePhase === "refund" ? "demo.refund" : "demo.presale")}</p>
                  {!live.launched && live.presaleDeadline > 0 && (
                    <p className="gx-mono text-xs">{t("metric.deadline")}<span className="gx-pri ml-2">{fmtDeadline(live.presaleDeadline, language)} UTC+8</span>{salePhase === "refund" ? <span className="gx-pri ml-2">{t("metric.deadlinePassed")}</span> : null}</p>
                  )}
                </div>
                <dl className="gx-metrics">
                  {(salePhase === "refund" ? [
                    [mintedLive, 0, "", t("metric.minted"), t("metric.mintedRefundNote")],
                    [escrowBnb, 5, " BNB", t("metric.escrow"), t("metric.escrowNote")],
                    [refundedCards, 0, "", t("metric.refunded"), t("metric.refundedNote")],
                    [refundedBnb, 5, " BNB", t("metric.refundedBnb"), t("metric.refundedBnbNote")],
                  ] : [
                    [mintedLive, 0, "", t("metric.minted"), t("metric.mintedNote", undefined, { n: fmtInt(TOTAL_POOL_CARDS) })],
                    [raisedBnb, raisedDigits, " BNB", t("metric.raised"), t("metric.raisedNote")],
                    [live.minters, 0, "", t("metric.minters"), t("metric.mintersNote", undefined, { n: MAX_MINT })],
                    [presaleLeft, 0, "", t("metric.left"), t("metric.leftNote", undefined, { n: fmtInt(PRESALE_CARDS) })],
                  ]).map(([value, digits, suffix, label, note]) => (
                    <div key={String(label)}>
                      <dt className="gx-muted text-xs">{label}</dt>
                      <dd className="gx-display mt-2 text-4xl"><CountUp value={Number(value)} digits={Number(digits)} suffix={String(suffix)} drawn /></dd>
                      <dd className="gx-muted mt-2 text-xs">{note}</dd>
                    </div>
                  ))}
                </dl>
                <div className="mt-6">
                  <div className="gx-mono gx-muted mb-2 flex justify-between text-xs"><span>{t(salePhase === "refund" ? "metric.refundProgress" : "progress")}</span><span className="gx-pri"><CountUp value={salePhase === "refund" ? refundPct : presalePct} digits={progressDigits} suffix="%" /></span></div>
                  <div className="gx-track"><div className="gx-live-bar" style={{ width: `${salePhase === "refund" ? refundPct : presalePct}%` }} /></div>
                </div>
                <div className="mt-10">
                  <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
                    <p className="gx-mono gx-pri text-xs">{t("pool.kicker")}</p>
                    <span className="gx-chip">{t(salePhase === "open" ? "pool.live" : salePhase === "refund" ? "pool.refund" : "pool.presale")}</span>
                  </div>
                  <dl className="gx-tiles">
                    {[
                      [fmtBnb(tokenBurned, 0), t("pool.burnedTokens"), t("unit.token")],
                      [floorCards, t("pool.burnedCards"), t("unit.card")],
                      [fmtBnb(live.dividendFwd), t("pool.dividend"), "BNB"],
                      [fmtBnb(live.floorFwd), t("pool.floor"), "BNB"],
                    ].map(([value, label, unit]) => (
                      <div key={label}>
                        <dt className="gx-muted text-xs">{label}</dt>
                        <dd className="gx-tile-value">{value}<span>{unit}</span></dd>
                      </div>
                    ))}
                  </dl>
                </div>
              </div>
            </section>

            <section className="gx-container gx-chapter">
              <div className={`${rise} gx-chapter-heading`}>
                <p className="gx-kicker">{t("life.kicker")}</p>
                <h2>{t("life.title")}</h2>
                <span className="gx-chapter-note">{t("life.note")}</span>
              </div>
              <div className="mt-8">
                <ol className="gx-phase-nav">
                  {[1, 2, 3, 4, 5].map((item) => (
                    <li key={item}>
                      <button type="button" aria-pressed={phase === item - 1} className={`gx-phase-button ${phase === item - 1 ? "gx-phase-active" : ""}`} onClick={() => setPhase(item - 1)}>
                        <span className="gx-mono text-xs">0{item}</span>
                        <span className="whitespace-nowrap text-base font-semibold">{phases[item - 1]?.title}</span>
                      </button>
                    </li>
                  ))}
                </ol>
                <div key={phase} className="gx-swap gx-phase-detail">
                  <span className="gx-phase-number" aria-hidden="true"><Poster text={`0${phase + 1}`} em={1} /></span>
                  <div>
                    <p className="gx-mono gx-pri text-xs">0{phase + 1} / 05</p>
                    <h3 className="mt-4 text-2xl font-bold">{phases[phase]?.title}</h3>
                    <p className="gx-muted mt-4 max-w-lg text-base">{phases[phase]?.body}</p>
                  </div>
                  <div className="gx-phase-art"><GenerativeCard id={phase * 131071 + 19} kind={phase === 0 ? "presale" : "open"} className="h-full w-full" /></div>
                </div>
              </div>
            </section>

            <section className="gx-container gx-workspace">
              <div className={`${rise} gx-chapter-heading lg:col-span-2`}>
                <p className="gx-kicker">{t("calc.kicker")}</p>
                <h2>{t("calc.title")}</h2>
                <span className="gx-chapter-note">{t("calc.note")}</span>
              </div>
              <div className={`${rise} gx-mint-tool`}>
                <p className="gx-kicker">A / MINT</p>
                <h3 className="mt-2 text-3xl font-bold">{t("mint.title")}</h3>
                <div className="gx-seg mt-5">
                  {(["presale", "open"] as const).map((item) => (
                    <button key={item} type="button" aria-pressed={mintPhase === item} onClick={() => setMintPhase(item)}>{t(item === "presale" ? "mint.presale" : "mint.open")}</button>
                  ))}
                </div>
                <div className="mt-6 flex items-end justify-between"><span className="gx-muted">{t("mint.count")}</span><span className="gx-display text-5xl"><Poster text={String(count)} /></span></div>
                <input className="mt-3" type="range" min={1} max={MAX_MINT} value={count} aria-label={t("mint.count")} style={{ ["--fill" as string]: `${((count - 1) / (MAX_MINT - 1)) * 100}%` }} onChange={(event) => setCount(Number(event.target.value))} />
                <div className="mt-6 grid h-12 grid-cols-10 gap-1.5" aria-hidden="true">
                  {Array.from({ length: MAX_MINT }, (_, index) => <div key={index} className={`gx-mint-mark ${index < count ? "gx-mint-mark-active" : ""}`} />)}
                </div>
                <dl className="gx-mono mt-6 grid grid-cols-2 gap-4 text-sm">
                  <div><dt className="gx-muted">{t("mint.pay")}</dt><dd className="text-2xl">{quoteBnb.toFixed(5)} BNB</dd></div>
                  {mintPhase === "presale" ? (
                    <div><dt className="gx-muted">{t("mint.tokens")}</dt><dd className="gx-pri text-2xl">{fmtInt(quoteTokens)}</dd></div>
                  ) : (
                    <>
                      <div><dt className="gx-muted">{t("mint.ops")}</dt><dd className="text-2xl">{(quoteBnb * 0.25).toFixed(5)}</dd></div>
                      <div className="col-span-2"><dt className="gx-muted">{t("mint.swap")}</dt><dd className="gx-pri text-2xl">{(quoteBnb * 0.75).toFixed(5)} BNB · {t("mint.swapNote")}</dd></div>
                    </>
                  )}
                </dl>
                {mintPhase === "open" && <p className="gx-muted mt-3 text-xs">{t("mint.openNote")}</p>}
              </div>
              <div className={`${rise} gx-vesting-tool`}>
                <p className="gx-kicker">B / VESTING</p>
                <h3 className="mt-2 text-3xl font-bold">{t("vest.title")}</h3>
                <p className="gx-muted mt-2">{t("vest.example", undefined, { n: count, tokens: fmtInt(grant) })}</p>
                <div className="mt-8 flex h-40 items-end gap-1">
                  {Array.from({ length: 40 }, (_, index) => {
                    const on = index / 40 < releasedShare;
                    return <div key={index} className={`gx-vest ${on ? "gx-vest-on" : "gx-vest-off"}`} style={{ height: `${20 + (index / 40) * 80}%`, transitionDelay: `${index * 8}ms` }} />;
                  })}
                </div>
                <div className="mt-6 flex items-end justify-between"><span className="gx-muted">{t("vest.day", undefined, { n: day.toFixed(1) })}</span><span className="gx-display gx-pri text-5xl"><Poster text={fmtInt(vested)} /></span></div>
                <input className="mt-3" type="range" min={0} max={5} step={0.1} value={day} aria-label={t("vest.title")} style={{ ["--fill" as string]: `${releasedShare * 100}%` }} onChange={(event) => setDay(Number(event.target.value))} />
              </div>
            </section>
            <section className="gx-container pb-8">{commandDeck(["wallet", "refund"])}</section>
            <footer className="gx-footer gx-mono gx-muted px-6 py-8 text-center text-xs">{t("footer.risk")}</footer>
          </main>
        )}

        {page && (
          <Shell
            rise={rise}
            index={page[0]}
            code={page[1]}
            title={t(page[2])}
            lead={t(page[3])}
            seed={page[4]}
            foot={t("footer.risk")}
          >
            {view === "market" && (
              <>
                <div className="mb-8 flex flex-wrap items-center justify-between gap-4">
                  <div className="gx-segment" role="tablist" aria-label={t("market.title")}>
                    <button type="button" aria-pressed={marketTab === "book"} onClick={() => setMarketTab("book")}>{t("market.tab.book")}</button>
                    <button type="button" aria-pressed={marketTab === "mine"} onClick={() => setMarketTab("mine")}>{t("market.tab.mine")}</button>
                  </div>
                  <p className="gx-mono gx-pri text-xs">{book.symbol}</p>
                </div>
                {marketTab === "book" && (
                  <>
                    <div className="mb-6 flex justify-end">
                      <div className="gx-segment" role="group" aria-label={t("market.title")}>
                        <button type="button" aria-pressed={bookSide === "ask"} onClick={() => setBookSide("ask")}>{t("market.sideAsk")}</button>
                        <button type="button" aria-pressed={bookSide === "bid"} onClick={() => setBookSide("bid")}>{t("market.sideBid")}</button>
                      </div>
                    </div>
                    <dl className="gx-tiles">
                      {[
                        [t("market.low"), rankedAsks[0] ? fmtBnb(rankedAsks[0].price, 6) : "—"],
                        [t("market.high"), rankedBids[0] ? fmtBnb(rankedBids[0].price, 6) : "—"],
                        [t("market.volume"), fmtBnb(book.fees * 100n)],
                        [t("market.escrow"), fmtBnb(bookEscrow)],
                      ].map(([label, value], index) => (
                        <div key={label}>
                          <span className="gx-tile-no">0{index + 1}</span>
                          <dt className="gx-muted mt-3 text-xs">{label}</dt>
                          <dd className="gx-tile-value">{value}<span>BNB</span></dd>
                        </div>
                      ))}
                    </dl>
                    <p className="gx-muted mt-3 text-xs">{t("market.volumeNote")}</p>
                    <div className="gx-market mt-8">
                      <Book
                        title={t(bookSide === "ask" ? "market.asks" : "market.bids")}
                        hint={t(bookSide === "ask" ? "market.askHint" : "market.bidHint", undefined, { n: bookSide === "ask" ? book.asks.length : book.bids.length })}
                        columns={[t("market.col.price"), t("market.col.qty"), t("market.col.total"), t("market.col.orders")]}
                        empty={t("market.empty")}
                        rows={(bookSide === "ask" ? askLevels : bidLevels).map((level, index) => [index === 0 ? `${fmtBnb(level.price, 6)}  ${t(bookSide === "ask" ? "market.bestAsk" : "market.bestBid")}` : fmtBnb(level.price, 6), String(level.count), String(level.total), String(level.orders)])}
                      />
                      <aside className="gx-panel h-fit p-5">
                        <h2 className="text-lg font-bold">{t(bookSide === "ask" ? "market.quickBuy" : "market.quickSell")}</h2>
                        <p className="gx-muted mt-2 text-xs">{t(bookSide === "ask" ? "market.quickBuyNote" : "market.quickSellNote")}</p>
                        <p className="gx-mono gx-pri mt-6 break-all text-3xl">{bookSide === "ask" ? (shownAsks.length ? fmtBnb(shownAsks.reduce((sum, ask) => sum + ask.price, 0n), 4) : "—") : (rankedBids[0] ? fmtBnb(rankedBids[0].price, 6) : "—")}<span className="gx-muted ml-2 text-sm">BNB</span></p>
                        <dl className="mt-5 space-y-3 text-sm">
                          <div className="flex justify-between gap-3"><dt className="gx-muted">{t("market.cards")}</dt><dd>{bookSide === "ask" ? shownAsks.length : rankedBids[0]?.remaining ?? 0}</dd></div>
                          <div className="flex justify-between gap-3"><dt className="gx-muted">{t("market.fee")}</dt><dd>1%</dd></div>
                        </dl>
                      </aside>
                    </div>
                  </>
                )}
                {marketTab === "mine" && (
                  <section className="space-y-4">
                    <label className="gx-muted block text-xs" htmlFor="bidder">{t("market.bidAddress")}</label>
                    <input id="bidder" className="gx-field" value={bidder} placeholder={t("market.bidPlaceholder")} aria-label={t("market.bidAddress")} onChange={(event) => setBidder(event.target.value.trim())} />
                    {!isAddress(bidder) && <p className="gx-muted text-sm">{t("market.bidNeed")}</p>}
                    {isAddress(bidder) && book.bids.filter((bid) => bid.bidder.toLowerCase() === bidder.toLowerCase()).map((bid) => (
                      <div key={bid.id} className="flex flex-wrap items-center justify-between gap-3 border-b border-[var(--border)] py-4 text-sm">
                        <span>{t("market.myBid", undefined, { id: bid.id, price: fmtBnb(bid.price, 6), n: bid.remaining })}</span>
                        <CopyButton value={fillCommand(t(commandStyle === "short" ? "cmd.cancel.short" : "cmd.cancel.text"), "cancel")} label={t("cmd.cancel.title")} />
                      </div>
                    ))}
                    {isAddress(bidder) && book.bids.every((bid) => bid.bidder.toLowerCase() !== bidder.toLowerCase()) && <p className="gx-muted text-sm">{t("market.bidEmpty")}</p>}
                  </section>
                )}
                {commandDeck(["buy", "bid", "cancel", "list", "sell", "unlist"])}
              </>
            )}
            {view === "commands" && (
              <>
                <div className="gx-panel mb-10 p-6">
                  <p className="gx-muted text-sm">{t("commands.note")}</p>
                  <div className="mt-4 flex flex-wrap items-center gap-3">
                    <div className="gx-segment" role="group" aria-label={t("commands.title")}>
                      <button type="button" aria-pressed={commandStyle === "text"} onClick={() => setCommandStyle("text")}>{t("commands.styleGeneral")}</button>
                      <button type="button" aria-pressed={commandStyle === "short"} onClick={() => setCommandStyle("short")}>{t("commands.styleBinance")}</button>
                    </div>
                    <p className="gx-muted text-xs">{t(commandStyle === "short" ? "commands.styleNoteBinance" : "commands.styleNoteGeneral")}</p>
                  </div>
                </div>
                {COMMAND_GROUPS.map((group) => (
                  <section key={group} className="gx-cmd-group">
                    <p className="gx-cmd-label">{groupLabel[group]}</p>
                    <div className="grid gap-4 md:grid-cols-2">
                      {COMMANDS.filter((item) => item[0] === group).map(([, id]) => commandCard(id))}
                    </div>
                  </section>
                ))}
              </>
            )}
            {view === "vault" && (
              <>
                <div className="gx-bento">
                  {[
                    [t("vault.tax"), fmtBnb(live.tax), "BNB"],
                    [t("vault.dividend"), fmtBnb(live.dividendFwd), "BNB"],
                    [t("vault.floorIn"), fmtBnb(live.floorFwd), "BNB"],
                    [t("vault.burned"), floorCards, t("vault.burnedUnit")],
                    [t("vault.tokenBurned"), fmtBnb(tokenBurned), t("vault.tokenUnit")],
                    [t("vault.paid"), fmtBnb(live.dividendPaid), "BNB"],
                    [t("vault.liability"), fmtBnb(live.liability), "BNB"],
                    [t("vault.stream"), fmtBnb(live.stream + live.sideStream), "BNB"],
                  ].map(([label, value, unit], index) => (
                    <div key={label} className={`gx-panel p-6 ${index === 0 ? "gx-tile-hero" : ""}`}>
                      <span className="gx-tile-no">0{index + 1}</span>
                      <p className="gx-muted mt-3 text-xs">{label}</p>
                      <p className="gx-tile-value">{value}<span>{unit}</span></p>
                    </div>
                  ))}
                </div>
                <div className="gx-flow-line" aria-hidden="true">
                  <span>{t("vault.flowTax")}</span>
                  <span>{t("vault.flowVault")}</span>
                  <span>{t("vault.flowDiv")}</span>
                  <span>{t("vault.flowHolder")}</span>
                </div>
                <div className="mt-14">
                  <section className="gx-panel p-7">
                    <p className="gx-kicker">MY CARDS</p>
                    <h3 className="mt-3 text-2xl font-bold">{t("vault.manageTitle")}</h3>
                    <p className="gx-muted mt-4 text-sm leading-7">{t("vault.manageBody")}</p>
                    <div className="mt-6"><CopyButton value={fillCommand(t(commandStyle === "short" ? "cmd.claim.short" : "cmd.claim.text"), "claim")} label={t("commands.copy")} /></div>
                  </section>
                </div>
                {commandDeck(["claim", "redeem", "withdraw"])}
              </>
            )}
            {view === "duel" && (
              <>
                <section className="gx-panel mb-8 p-6">
                  <p className="gx-kicker">ROOMS</p>
                  <h2 className="mt-3 text-2xl font-bold">{t("duel.roomsTitle")}</h2>
                  <ul className="mt-6 space-y-3">
                    {rooms.map((room) => (
                      <li key={room.id} className="grid grid-cols-2 gap-4 border-b border-white/10 pb-4 sm:grid-cols-4">
                        <div><p className="gx-muted text-xs">{t("duel.colRoom")}</p><p className="gx-mono gx-pri mt-1">{String(room.id).padStart(2, "0")}</p></div>
                        <div><p className="gx-muted text-xs">{t("duel.colCard")}</p><p className="gx-mono mt-1">#{room.card}</p></div>
                        <div><p className="gx-muted text-xs">{t("duel.colDeposit")}</p><p className="gx-mono mt-1">{fmtBnb(room.deposit, 6)} BNB</p></div>
                        <div><p className="gx-muted text-xs">{t("duel.colWaiting")}</p><p className="gx-mono gx-pri mt-1">{`${room.player.slice(0, 6)}...${room.player.slice(-4)}`}</p></div>
                      </li>
                    ))}
                  </ul>
                  <div className="mt-6 space-y-3">
                    {t("duel.depositNote").split("\n").filter(Boolean).map((line) => (
                      <p key={line} className="gx-muted text-sm leading-7">{line}</p>
                    ))}
                  </div>
                  <p className="gx-muted mt-4 text-sm leading-7">{t("duel.roomsOffline")}</p>
                </section>
                <article className="gx-term mb-8">
                  <h3 className="text-lg font-bold">{t("duel.cmdTitle")}</h3>
                  <code className="gx-term-fn">{"> "}{duelTarget ? `enter(${duelTarget.roomId}, tokenId)` : t("duel.cmdFn")}</code>
                  <p className="gx-muted mt-2 text-xs leading-6">{t("duel.cmdDesc")}</p>
                  <div className="mt-4 flex flex-wrap items-center gap-3">
                    <div className="gx-segment" role="group" aria-label={t("duel.cmdTitle")}>
                      <button type="button" aria-pressed={commandStyle === "text"} onClick={() => setCommandStyle("text")}>{t("commands.styleGeneral")}</button>
                      <button type="button" aria-pressed={commandStyle === "short"} onClick={() => setCommandStyle("short")}>{t("commands.styleBinance")}</button>
                    </div>
                    <p className="gx-muted text-xs">{t(commandStyle === "short" ? "commands.styleNoteBinance" : "commands.styleNoteGeneral")}</p>
                  </div>
                  <div className="mt-4"><CopyButton value={fillCommand(t(commandStyle === "short" ? "duel.cmdShort" : "duel.cmdText"), "duel")} label={t("commands.copy")} /></div>
                </article>
                <div className="space-y-5">
                {duelRules.map((item, index) => (
                  <section key={item.title} className="gx-rule">
                    <span className="gx-rule-no" aria-hidden="true">{String(index + 1).padStart(2, "0")}</span>
                    <p className="gx-mono gx-pri text-xs">{String(index + 1).padStart(2, "0")}</p>
                    <h2 className="mt-2 text-2xl font-bold">{item.title}</h2>
                    <div className="mt-4 space-y-3">
                      {item.body.split("\n").filter(Boolean).map((line) => (
                        <p key={line} className="gx-muted text-sm leading-7">{line}</p>
                      ))}
                    </div>
                  </section>
                ))}
                </div>
              </>
            )}
            {view === "rules" && (
              <div className="gx-rules">
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
              </div>
            )}
            {view === "ladder" && (
              <>
                <div className="max-w-2xl space-y-4">
                  {t("ladder.explain").split("\n").filter(Boolean).map((line) => (
                    <p key={line} className="text-base leading-8">{line}</p>
                  ))}
                </div>
                <div className="gx-rungs mt-10">
                  {LADDER_SIZE.map((size, index) => {
                    const status = ladderStatus(index);
                    const left = size - (ladderLive.sold[index] ?? 0n);
                    return (
                      <button key={index} type="button" className="gx-rung" aria-pressed={ladderRung === index} onClick={() => setLadderRung(index)}>
                        <p className="gx-mono gx-pri text-xs">{t("ladder.band", undefined, { n: index + 1 })} · {t(index === 0 ? "ladder.multiple.1" : index === 1 ? "ladder.multiple.2" : "ladder.multiple.3")}</p>
                        <p className={`mt-4 text-lg font-semibold ${status === "ladder.open" ? "gx-pri" : ""}`}>{t(status)}</p>
                        <dl className="mt-5 space-y-3 text-sm">
                          <div className="flex justify-between gap-3"><dt className="gx-muted">{t("ladder.price")}</dt><dd className="gx-mono">{priceText(ladderPrice(index))} BNB</dd></div>
                          <div className="flex justify-between gap-3"><dt className="gx-muted">{t("ladder.left")}</dt><dd className="gx-mono">{fmtBnb(left > 0n ? left : 0n, 4)}</dd></div>
                          <div className="flex justify-between gap-3"><dt className="gx-muted">{t("ladder.size")}</dt><dd className="gx-mono">{fmtBnb(size, 4)}</dd></div>
                        </dl>
                      </button>
                    );
                  })}
                </div>
                <p className="gx-muted mt-4 text-sm">{ladderLive.twap === null ? t("ladder.twapWait") : `${t("ladder.twap")} ${priceText(ladderLive.twap)} BNB`}</p>
                <section className="gx-panel mt-8 max-w-xl p-6">
                  <label className="gx-muted text-xs" htmlFor="ladder-qty">{t("ladder.amount")}</label>
                  <input id="ladder-qty" className="gx-field mt-3" inputMode="numeric" value={ladderQty} aria-label={t("ladder.amount")} onChange={(event) => setLadderQty(event.target.value.replace(/[^\d]/g, ""))} />
                  <dl className="mt-6 space-y-3 text-sm">
                    <div className="flex justify-between gap-3"><dt className="gx-muted">{t("ladder.cost")}</dt><dd className="gx-mono">{priceText(ladderPay)} BNB</dd></div>
                    <div className="flex justify-between gap-3"><dt className="gx-muted">{t("ladder.recipient")}</dt><dd className="gx-mono break-all">{sdk.wallet.address ?? "—"}</dd></div>
                  </dl>
                  <button type="button" className="gx-btn gx-btn-lg gx-btn-solid mt-6" disabled={ladderBuying || (sdk.wallet.isConnected && !sdk.wallet.isWrongNetwork && (!ladderOpen || ladderAmount === 0n || ladderAmount > ladderLeft))} onClick={() => void buyLadder()}>
                    {ladderBuying ? t("ladder.pending") : !sdk.wallet.isConnected ? t("ladder.connect") : sdk.wallet.isWrongNetwork ? t("ladder.switch") : t("ladder.buy")}
                  </button>
                  {!ladderOpen && <p className="gx-muted mt-4 text-sm">{t(ladderStatus(ladderRung) === "ladder.offline" ? "ladder.unlaunched" : ladderStatus(ladderRung))}</p>}
                </section>
                <article className="gx-term mt-8">
                  <h3 className="text-lg font-bold">{t("ladder.cmdTitle")}</h3>
                  <code className="gx-term-fn">{"> "}{t("ladder.cmdFn")}</code>
                  <p className="gx-muted mt-2 text-xs leading-6">{t("ladder.cmdDesc")}</p>
                  <div className="mt-4 flex flex-wrap items-center gap-3">
                    <div className="gx-segment" role="group" aria-label={t("ladder.cmdTitle")}>
                      <button type="button" aria-pressed={commandStyle === "text"} onClick={() => setCommandStyle("text")}>{t("commands.styleGeneral")}</button>
                      <button type="button" aria-pressed={commandStyle === "short"} onClick={() => setCommandStyle("short")}>{t("commands.styleBinance")}</button>
                    </div>
                    <p className="gx-muted text-xs">{t(commandStyle === "short" ? "commands.styleNoteBinance" : "commands.styleNoteGeneral")}</p>
                  </div>
                  <div className="mt-4"><CopyButton value={fillCommand(t(commandStyle === "short" ? "ladder.cmdShort" : "ladder.cmdText"), "ladder")} label={t("commands.copy")} /></div>
                </article>
              </>
            )}
            {view === "tokenomics" && (
              <>
                <div className="gx-token-layout">
                  <div className="gx-donut-wrap">
                    <Donut active={slice} lockLabel={t("token.lockArc")} label={t("token.donutLabel")} />
                    {(() => {
                      const activeSlice = SLICES[slice] ?? SLICES[0];
                      return (
                        <div key={slice} className="gx-swap gx-donut-center">
                          <p className="gx-mono gx-pri text-4xl font-bold">{activeSlice.key === "team" ? "5%" : `${((activeSlice.amount / 777_777_777) * 100).toFixed(1)}%`}</p>
                          {activeSlice.key === "team" && <p className="gx-muted text-xs">{t("token.ofCards")}</p>}
                          {activeSlice.key === "team" && <p className="gx-chip gx-chip-pri mx-auto mt-2">{t("token.inContract")}</p>}
                          <p className="mt-1 text-sm">{allocCopy[activeSlice.key].name}</p>
                        </div>
                      );
                    })()}
                    <p className="gx-muted mt-3 text-center text-xs">{t("token.dashNote")}</p>
                  </div>
                  <ul className="space-y-2">
                    {SLICES.map((item, index) => (
                      <li key={item.key}>
                        <button type="button" className={`gx-alloc ${slice === index ? "gx-alloc-active" : ""}`} onMouseEnter={() => setSlice(index)} onFocus={() => setSlice(index)} onClick={() => setSlice(index)}>
                          <span className="gx-dot" style={{ opacity: SLICE_ALPHA[index] }} />
                          <span className="min-w-0 flex-1">
                            <span className="flex flex-wrap items-center gap-2 font-medium">{allocCopy[item.key].name}{item.key === "team" && <span className="gx-chip gx-chip-pri">{t("token.locked")}</span>}</span>
                            <span className="gx-muted block text-xs">{allocCopy[item.key].note}</span>
                          </span>
                          {item.key === "team" ? <span className="gx-mono text-right text-sm">5%<span className="gx-muted block text-xs">{t("token.ofCards")}</span></span> : <span className="gx-mono text-right text-sm">{fmtInt(item.amount)}<span className="gx-muted block text-xs">{((item.amount / 777_777_777) * 100).toFixed(1)}%</span></span>}
                        </button>
                      </li>
                    ))}
                  </ul>
                </div>
                <div className="gx-callout mt-10">
                  <p className="font-bold">{t("token.calloutTitle")}</p>
                  <p className="gx-muted mt-2 text-sm leading-7">{t("token.calloutBody")}</p>
                </div>
                <h2 className="mb-6 mt-16 text-2xl font-bold">{t("token.flowsTitle")}</h2>
                <div className="grid gap-5 md:grid-cols-3">
                  {flows.map(({ icon: Icon, title, body }) => (
                    <section key={title} className="gx-panel p-6">
                      <Icon className="gx-pri" size={24} aria-hidden="true" />
                      <h3 className="mt-4 text-xl font-bold">{title}</h3>
                      <p className="gx-muted mt-4 text-sm leading-7">{body}</p>
                    </section>
                  ))}
                </div>
              </>
            )}
          </Shell>
        )}
      </div>
    </div>
  );
}

function Shell({ rise, index, code, title, lead, seed, foot, children }: { rise: string; index: string; code: string; title: string; lead: string; seed: number; foot: string; children: ReactNode }) {
  return (
    <main>
      <section className="gx-container gx-page-hero">
        <div className={`${rise} min-w-0`}>
          <p className="gx-kicker">{index} / {code}</p>
          <h1 className="gx-page-title mt-4">{title}<span className="gx-pri">.</span></h1>
          <p className="gx-muted mt-5 max-w-xl text-base leading-8">{lead}</p>
        </div>
        <div className={`${rise} gx-page-art`} aria-hidden="true">
          <GenerativeCard id={seed} kind="open" className="h-full w-full" />
          <span className="gx-page-index">{index}</span>
        </div>
      </section>
      <div className="gx-container gx-exhibit-caption"><span>MINT.AI / {code}</span><ArrowDownRight className="gx-pri" size={16} aria-hidden="true" /></div>
      <div className={`${rise} gx-container py-12`}>{children}</div>
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
