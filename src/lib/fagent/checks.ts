import type { Language } from "./i18n";
import { FAGENT } from "./config";

/** Explicit read-only signatures so any AI can pre-check without fetching the ABI. */
export const READS = {
  balance: "eth_getBalance(我的地址)",
  hasAgentId: "function hasAgentId(address) view returns (bool)",
  mintsUsed: "function mintsUsed(address) view returns (uint256)",
  MAX_MINTS: "function MAX_MINTS() view returns (uint256)",
  userMints: "function userMints() view returns (uint256)",
  USER_CARDS: "function USER_CARDS() view returns (uint256)",
  mintPrice: "function mintPrice() view returns (uint256)",
  balanceOf: "function balanceOf(address) view returns (uint256)",
  ownerOf: "function ownerOf(uint256) view returns (address)",
  isActive: "function isActive(uint256) view returns (bool)",
  redeemed: "function redeemed(uint256) view returns (bool)",
  listings: "function listings(uint256) view returns (address seller, uint96 price)",
  bids: "function bids(uint256) view returns (address bidder, uint96 price, uint32 remaining, uint8 batchPlusOne)",
  getActiveBids: "function getActiveBids(uint256 cursor, uint256 limit) view returns (uint256[] bidIds, (address bidder, uint96 price, uint32 remaining, uint8 batchPlusOne)[] orders, uint256 next)",
  nextBidId: "function nextBidId() view returns (uint256)",
  MAX_BUY: "function MAX_BUY() view returns (uint256)",
  MAX_LIST: "function MAX_LIST() view returns (uint256)",
  MAX_SELL_TO_BID: "function MAX_SELL_TO_BID() view returns (uint256)",
  pendingDividend: "function pendingDividend(uint256) view returns (uint256)",
  batchAccounted: "function batchAccounted(uint256) view returns (bool)",
  batchOpenedAt: "function batchOpenedAt() view returns (uint256)",
  STALL_RELEASE: "function STALL_RELEASE() view returns (uint256)",
  undistributedTax: "function undistributedTax() view returns (uint256)",
  proceedsOwed: "function proceedsOwed(address) view returns (uint256)",
} as const;
type R = keyof typeof READS;
type Step = [R, string, string];

const PLAN: Record<string, Step[]> = {
  mint: [
    ["balance", "BNB 余额 ≥ mintPrice × 数量 + 约 0.0005 BNB gas", "BNB balance ≥ mintPrice × count + ~0.0005 BNB gas"],
    ["hasAgentId", "必须为 true（只有持有 Agent ID 的钱包能铸造）", "must be true (only Agent ID wallets can mint)"],
    ["mintsUsed", "已用名额 + 本次数量 ≤ MAX_MINTS", "used + count ≤ MAX_MINTS"],
    ["MAX_MINTS", "每地址终身上限", "lifetime cap per address"],
    ["userMints", "全系列已铸 + 本次数量 ≤ USER_CARDS", "minted so far + count ≤ USER_CARDS"],
    ["USER_CARDS", "付费卡总上限", "total paid-card cap"],
    ["mintPrice", "以读数为准，value = mintPrice × 数量；与指令不一致就停止并告诉我", "use this; value = mintPrice × count; stop and tell me if it differs"],
  ],
  buy: [
    ["balance", "BNB 余额 ≥ 最高价合计 + gas", "BNB balance ≥ total max price + gas"],
    ["listings", "seller 不为 0 地址且不是我，price ≤ 我的最高价", "seller is non-zero and not me, price ≤ my max"],
    ["ownerOf", "必须等于 listings 里的 seller", "must equal the listing seller"],
    ["MAX_BUY", "一次买入张数不超过它", "cards per call ≤ this"],
  ],
  placeBid: [
    ["balance", "BNB 余额 ≥ 出价 × 数量 + gas", "BNB balance ≥ price × quantity + gas"],
    ["nextBidId", "发送后新求购的编号", "id of the new bid after sending"],
  ],
  cancelBids: [["bids", "bidder 是我且 remaining > 0", "bidder is me and remaining > 0"]],
  list: [
    ["balanceOf", "我持有的卡牌张数 > 0", "my card count > 0"],
    ["ownerOf", "必须是我的地址", "must be my address"],
    ["isActive", "必须为 true（已销毁的卡不能卖）", "must be true (burned cards can't be sold)"],
    ["MAX_LIST", "一次挂单张数不超过它", "cards per call ≤ this"],
  ],
  sellToBid: [
    ["ownerOf", "必须是我的地址", "must be my address"],
    ["isActive", "必须为 true", "must be true"],
    ["nextBidId", "分页读取的终点", "end of pagination"],
    ["getActiveBids", "从 cursor=0、limit=500 开始翻页，找价格最高、remaining>0、批次匹配的求购", "page from cursor=0, limit=500; pick the highest bid with remaining>0 and matching batch"],
    ["MAX_SELL_TO_BID", "一次卖出张数不超过它", "cards per call ≤ this"],
  ],
  unlist: [["listings", "seller 必须是我", "seller must be me"]],
  claim: [
    ["ownerOf", "必须是我的地址", "must be my address"],
    ["isActive", "必须为 true", "must be true"],
    ["pendingDividend", "可领取分红（为 0 也先模拟，以模拟结果为准）", "claimable dividend (simulate even if 0)"],
  ],
  redeem: [
    ["ownerOf", "必须是我的地址", "must be my address"],
    ["redeemed", "必须为 false", "must be false"],
    ["batchAccounted", "参数 = 卡号 ÷ 10000 取整；为 true 表示本批已售满", "arg = cardId ÷ 10000 (floor); true means batch sold out"],
    ["batchOpenedAt", "与 STALL_RELEASE 相加，判断是否已满 7 天", "plus STALL_RELEASE tells whether 7 days passed"],
    ["STALL_RELEASE", "释放等待秒数", "release wait in seconds"],
  ],
  sync: [["undistributedTax", "待分配税收", "undistributed tax"]],
  withdrawProceeds: [["proceedsOwed", "必须 > 0，否则不要发送", "must be > 0, otherwise don't send"]],
  wallet: [
    ["balance", "BNB 余额", "BNB balance"],
    ["hasAgentId", "能否铸造", "whether I can mint"],
    ["mintsUsed", "已用铸造名额", "mint slots used"],
    ["MAX_MINTS", "剩余名额 = MAX_MINTS − mintsUsed", "remaining = MAX_MINTS − mintsUsed"],
    ["mintPrice", "单张铸造价", "mint price per card"],
    ["balanceOf", "我持有的卡牌张数", "cards I hold"],
    ["proceedsOwed", "待提取的卖卡收入", "card-sale proceeds to withdraw"],
  ],
};

export const fnKey = (fn: string) => fn.split("(")[0] ?? fn;

export function checkBlock(key: string, lang: Language) {
  const steps = PLAN[key];
  if (!steps?.length) return "";
  const en = lang === "en";
  const head = en
    ? `Before any transaction, run these read-only calls on the Vault ${FAGENT.vault} (signatures given, no ABI needed; "me" = my wallet address):`
    : `发送任何交易前，先对金库 ${FAGENT.vault} 做以下只读检查（签名已给出，不需要 ABI；“我的地址”= 当前钱包地址）：`;
  const lines = steps.map(([r, zh, e], i) => `${i + 1}. ${READS[r].replace("我的地址", en ? "me" : "我的地址")} → ${en ? e : zh}`);
  const tail = en ? "Show me every result. If any check fails, stop and explain why — do not send." : "把每项结果列给我看。任何一项不通过就停止并说明原因，不要发送交易。";
  return [head, ...lines, tail].join("\n");
}

export function withChecks(key: string, text: string, lang: Language) {
  const block = checkBlock(key, lang);
  return block ? `${text}\n\n${block}` : text;
}

export function walletCommand(lang: Language) {
  const en = lang === "en";
  const head = en
    ? `You are my Binance Agent Wallet assistant. Network: BNB Chain (chainId=${FAGENT.chainId}). Read-only check, send nothing.`
    : `你是我的币安 Agent 钱包助手。网络：BNB Chain (chainId=${FAGENT.chainId})。只读查询，不发送任何交易。`;
  const tail = en
    ? `To list my card IDs: read Transfer(address,address,uint256) logs of the Vault where to = me, then keep IDs whose ownerOf is still me. Summarize: BNB balance, how many I can still mint and the cost, my card IDs.`
    : `要列出我的卡号：读取金库的 Transfer(address,address,uint256) 日志中 to = 我的地址 的记录，再用 ownerOf 过滤出仍属于我的卡。最后汇总：BNB 余额、还能铸几张及费用、我的卡号列表。`;
  return `${head}\n\n${checkBlock("wallet", lang)}\n\n${tail}`;
}
