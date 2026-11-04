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
  getActiveListings: "function getActiveListings(uint256 cursor, uint256 limit) view returns (uint256[] tokenIds, (address seller, uint96 price)[] orders, uint256 next)",
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

const MY_CARDS_ZH = "找我的卡：读取金库 Transfer(address indexed from, address indexed to, uint256 indexed tokenId) 日志里 to = 我的地址 的记录，去重后逐个用 ownerOf 过滤出仍属于我的、再用 isActive 去掉已销毁的；张数应等于 balanceOf(我的地址)，对不上就告诉我。";
const MY_CARDS_EN = "Find my cards: read the Vault Transfer(address indexed from, address indexed to, uint256 indexed tokenId) logs where to = me, dedupe, keep IDs whose ownerOf is still me and isActive is true; the count should equal balanceOf(me), tell me if not.";
const CARD_ZH = MY_CARDS_ZH + "如果我没给卡号，把我的卡号列出来让我选，不要自己猜。";
const CARD_EN = MY_CARDS_EN + " If I gave no card ID, list my cards and let me choose; never guess.";
/** What the AI must ask or compute itself, so commands never rely on stale fixed numbers. */
const DYNAMIC: Record<string, [string, string]> = {
  mint: ["动态计算：先问我铸几张（不能超过 MAX_MINTS − mintsUsed，也不能超过 USER_CARDS − userMints）。value = mintPrice() 读数 × 张数，用 wei 精确计算，不要用指令里写死的金额。发送后从 Transfer 日志报告新卡号和交易哈希。", "Compute dynamically: ask how many cards (≤ MAX_MINTS − mintsUsed and ≤ USER_CARDS − userMints). value = live mintPrice() × count in exact wei; never use a hard-coded amount. After sending, report new card IDs from Transfer logs and the tx hash."],
  buy: ["动态计算：没给卡号时，用 getActiveListings(uint256 cursor, uint256 limit) 从 cursor=0、limit=500 翻页，按价格从低到高列出，问我买几张、最高接受价。tokenIds 与 maxPrices 一一对应，value = maxPrices 之和（wei）。超限价的卡会被跳过并退款，只按 Sold 日志报告成交。", "Compute dynamically: if no card ID, page getActiveListings(uint256 cursor, uint256 limit) from cursor=0, limit=500, sort by price ascending, ask how many and my max price. tokenIds and maxPrices align; value = sum of maxPrices in wei. Over-limit cards are skipped and refunded; report only Sold logs."],
  placeBid: ["动态计算：问我每张出价（BNB）、数量、只收哪一批（不限填 0，第 N 批填 N）。price 换算成 wei，value = price wei × 数量，必须精确相等。", "Compute dynamically: ask price per card (BNB), quantity and batch (0 = any, batch N = N). Convert price to wei; value = price wei × quantity exactly."],
  cancelBids: ["没给 bidId 时：用 getActiveBids 翻页找出 bidder = 我 的求购列给我选。", "If no bidId: page getActiveBids and list bids where bidder = me for me to choose."],
  list: [CARD_ZH + "问我每张售价（BNB），换算成 wei；tokenIds 与 prices 一一对应，可一次挂多张。value = 0。", CARD_EN + " Ask the price per card (BNB), convert to wei; tokenIds and prices align, multiple cards allowed. value = 0."],
  sellToBid: [CARD_ZH + "问我最低接受价，低于它就停止。只选能接受我这张卡批次的求购（batchPlusOne = 0 或 = 卡号 ÷ 10000 取整 + 1）。", CARD_EN + " Ask my minimum price and stop below it. Only bids that accept my card's batch (batchPlusOne = 0 or floor(cardId ÷ 10000) + 1)."],
  unlist: [CARD_ZH + "只列出 listings 里 seller = 我 的卡。", CARD_EN + " Only show cards whose listing seller is me."],
  claim: [CARD_ZH + "可以逐张列出 pendingDividend，问我领哪几张，每张调用一次 claim。", CARD_EN + " List pendingDividend per card, ask which to claim, one claim call per card."],
  redeem: [CARD_ZH + "先模拟并告诉我会收到多少代币和 BNB，销毁不可逆，必须我再次确认。", CARD_EN + " Simulate first and tell me the tokens and BNB I'd receive; burning is irreversible, require a second confirmation."],
  withdrawProceeds: ["参数 to 填我的钱包地址，value = 0。", "Param to = my wallet address, value = 0."],
  wallet: [MY_CARDS_ZH, MY_CARDS_EN],
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
  const dyn = DYNAMIC[key];
  if (dyn) lines.push(en ? dyn[1] : dyn[0]);
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
    ? `Summarize: BNB balance, how many I can still mint and the cost, my card IDs.`
    : `最后汇总：BNB 余额、还能铸几张及费用、我的卡号列表。`;
  return `${head}\n\n${checkBlock("wallet", lang)}\n\n${tail}`;
}
