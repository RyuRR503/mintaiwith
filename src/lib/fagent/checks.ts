import type { Language } from "./i18n";
import { FAGENT } from "./config";
export const READS = {
  balance: "eth_getBalance(me)",
  AGENT_ID_NFT: "function AGENT_ID_NFT() view returns (address)",
  mintsUsed: "function mintsUsed(address) view returns (uint256)",
  MAX_MINTS: "function MAX_MINTS() view returns (uint256)",
  paidMinted: "function paidMinted() view returns (uint256)",
  PAID_CAP: "function PAID_CAP() view returns (uint256)",
  priceOf: "function priceOf(uint256 paidIndex) pure returns (uint256)",
  balanceOf: "function balanceOf(address) view returns (uint256)",
  ownerOf: "function ownerOf(uint256) view returns (address)",
  launched: "function launched() view returns (bool)",
  presaleDeadline: "function presaleDeadline() view returns (uint256)",
  presaleFilledAt: "function presaleFilledAt() view returns (uint256)",
  listings: "function listings(uint256) view returns (address seller, uint96 price)",
  bids: "function bids(uint256) view returns (address bidder, uint96 price, uint32 remaining)",
  pendingDividendOf: "function pendingDividendOf(uint256) view returns (uint256)",
  proceedsOwed: "function proceedsOwed(address) view returns (uint256)",
  vault: "function vault() view returns (address)",
} as const;
export const fnKey = (fn: string) => fn.split("(")[0] ?? fn;
export function checkBlock(key: string, lang: Language) {
  const en = lang === "en";
  const head = en ? `Read-only checks on the NFT card ${FAGENT.cards}; never send until I confirm.` : `先对 NFT 卡牌 ${FAGENT.cards} 做只读检查；未经我确认不得发送。`;
  const common = [READS.ownerOf, READS.launched];
  const mint = [READS.balance, READS.AGENT_ID_NFT, READS.mintsUsed, READS.MAX_MINTS, READS.paidMinted, READS.priceOf, READS.launched, READS.presaleDeadline];
  const rules = en
    ? `Read Agent ID balanceOf(me) on the address returned by AGENT_ID_NFT(); it must be positive. Ask count; used + count <= MAX_MINTS, count <= 10. Before launch, paidMinted + count <= 20000 and the chain timestamp <= presaleDeadline. Exact value = priceOf(paidMinted + 1) × count. Before launch minTokens=0. After launch read quoteMint(address cards,uint256 count) on the read-only lens ${FAGENT.orderbook}, ask my slippage limit, calculate a positive minTokens; never use 0. Simulate, show cost and gas, and stop on any failed check.`
    : `在 AGENT_ID_NFT() 返回的地址读取 balanceOf(我的地址)，必须大于 0。先问我张数；已用名额 + 张数不超过 MAX_MINTS，单次最多 10 张。未开池时 paidMinted + 张数不得超过 20000，链上时间不得超过 presaleDeadline。准确 value = priceOf(paidMinted + 1) × 张数。预售 minTokens=0；开池后在只读订单簿 ${FAGENT.orderbook} 读取 quoteMint(address cards,uint256 count)，询问可接受滑点并算出正数 minTokens，禁止填 0。模拟并展示金额及 gas，检查失败即停止。`;
  if (key === "mint" || key === "wallet") return [head, ...mint, rules, ...(key === "wallet" ? [READS.balanceOf, READS.proceedsOwed, en ? "Read Transfer logs and filter IDs with ownerOf(me); send no transaction." : "从 Transfer 日志取卡号，再用 ownerOf 过滤仍属于我的卡；不发送交易。"] : [])].join("\n");
  return [head, ...common, en ? "Before launch, transfers and trading are locked. Verify ownership, current orders and exact payment; simulate first. The lens holds no funds: never send BNB or transactions to it or either factory." : "开池前不可转让或交易。核对持有人、最新订单和准确付款，先模拟。订单簿不存钱：不得向它或任一工厂发送 BNB 或交易。"].join("\n");
}
export const withChecks = (key: string, text: string, lang: Language) => `${text}\n\n${checkBlock(key, lang)}`;
export function walletCommand(lang: Language) {
  return `${lang === "en" ? "You are my Binance Agent Wallet assistant. Read-only check; send nothing." : "你是我的币安 Agent 钱包助手。只读查询，不发送任何交易。"}\n${checkBlock("wallet", lang)}`;
}
