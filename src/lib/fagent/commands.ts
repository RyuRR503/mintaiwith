import { parseEther } from "viem";
import type { Language } from "./i18n";
import { FAGENT } from "./config";
import { walletCommand, withChecks } from "./checks";
export const commandHead = `你是我的币安 Agent 钱包助手。网络：BNB Chain，chainId=56。NFT 卡牌：${FAGENT.cards}。铸造及市场交易调用卡牌，不调用工厂或只读订单簿。金库由卡牌 vault() 发现，不得使用旧地址。先模拟，展示参数、金额和 gas，等我确认后才发送，不索要私钥。`;
export const commandHeader = (lang: Language) => lang === "en" ? `You are my Binance Agent Wallet assistant. BNB Chain, chainId=56. NFT card: ${FAGENT.cards}. Mint and market transactions target the card, never either factory or the read-only lens. Discover the vault using cards.vault(); never use an old address. Simulate, show parameters, payment and gas; send only after I confirm. Never request private keys.` : commandHead;
export function orderPrice(price: string) {
  if (!/^\d+(\.\d{1,18})?$/.test(price)) throw new Error("Invalid price");
  const wei = parseEther(price); if (wei <= 0n || wei > (1n << 96n) - 1n) throw new Error("Invalid price"); return wei;
}
export function mintCommand(count: number, language: Language = "zh") {
  if (!Number.isInteger(count) || count < 1 || count > 10) throw new Error("Count must be 1–10");
  const wei = 2450000000000000n * BigInt(count);
  return withChecks("mint", `${commandHeader(language)}\nfunction mint(uint256 count, uint256 minTokens) payable\ncount=${count}; presale minTokens=0; value=${wei} wei.\n${language === "en" ? "This amount is for presale only. After launch recalculate the quote and positive minTokens; report PaidMint logs and transaction hash, never fabricate success." : "此金额仅适用于预售。开池后须重新报价并设置正数 minTokens；按 PaidMint 日志与交易哈希报告结果，不得虚构成功。"}`, language);
}
export function buyCommand(id: number, price: string, language: Language = "zh") { return batchBuyCommand([{ id, priceWei: String(orderPrice(price)) }], 250, language); }
export function batchBuyCommand(cards: { id: number; priceWei: string }[], maxBuy: number, language: Language = "zh") {
  if (!cards.length || !Number.isInteger(maxBuy) || maxBuy < 1 || cards.length > Math.min(250, maxBuy) || new Set(cards.map(c => c.id)).size !== cards.length || cards.some(c => !Number.isInteger(c.id) || c.id < 1 || c.id > 777777 || !/^\d+$/.test(c.priceWei) || BigInt(c.priceWei) <= 0n || BigInt(c.priceWei) > (1n << 96n) - 1n)) throw new Error("Invalid orders");
  const sum = cards.reduce((a,c) => a + BigInt(c.priceWei),0n);
  return withChecks("buy", `${commandHeader(language)}\nfunction buy(uint256[] tokenIds, uint256[] maxPrices) payable\n${language === "en" ? "parameters" : "参数"} [${cards.map(c => c.id)}], [${cards.map(c => c.priceWei)}]; value=${sum} wei.\n${language === "en" ? "Verify live listings and owners. Report only actual Sold logs; unused payment is refunded." : "核对最新 listings 和 ownerOf，只按 Sold 日志报告实际成交，未用款退回。"}`, language);
}
export function bidCommand(price: string, quantity: number, batch = 0, language: Language = "zh") {
  const wei = orderPrice(price);
  if (!Number.isInteger(quantity) || quantity < 1 || quantity > 4294967295 || batch !== 0) throw new Error("This contract has no batch filter");
  return withChecks("placeBid", `${commandHeader(language)}\nfunction placeBid(uint256 price, uint256 quantity) payable\n${language === "en" ? "parameters" : "参数"} ${wei}, ${quantity}; value=${wei * BigInt(quantity)} wei.`, language);
}
export function cardCommand(kind: "claim" | "redeem" | "list" | "unlist", id: number | string, price = "0.003", language: Language = "zh") {
  if (kind === "redeem") throw new Error("Burn-to-redeem is not supported by this contract");
  const sig = kind === "claim" ? "function claim(uint256[] tokenIds)" : kind === "list" ? "function list(uint256[] tokenIds, uint256[] prices)" : "function unlist(uint256[] tokenIds)";
  return withChecks(kind, `${commandHeader(language)}\n${sig}\ntokenIds=[${id}]${kind === "list" ? `; prices=[${orderPrice(price)}]` : ""}; value=0 wei.`, language);
}
export function getAgentCommands(language: Language = "zh") {
  const en = language === "en"; const id = en ? "[cardId]" : "【卡号】";
  const entry = (group: string, zh: string, english: string, fn: string, descZh: string, descEn: string, text: string) => ({ group, title: en ? english : zh, fn, desc: en ? descEn : descZh, text });
  const custom = (key: string, sig: string, note: string) => withChecks(key, `${commandHeader(language)}\n${sig}\n${note}`, language);
  return [
    entry("铸造", "查询我的钱包", "Check my wallet", "balanceOf(address)", "只读查询持卡、余额及剩余名额。", "Read holdings, balance and remaining slots.", walletCommand(language)),
    entry("铸造", "铸造卡牌", "Mint cards", "mint(uint256 count,uint256 minTokens)", "预售每张 0.00245 BNB，每地址最多 10 张。", "Presale: 0.00245 BNB each, 10 paid mints per address.", custom("mint", "function mint(uint256 count, uint256 minTokens) payable", en ? "Ask count and use live price; presale minTokens=0, post-launch use a positive slippage-adjusted quote." : "先问张数，以实时价格付款；预售 minTokens=0，开池后须用滑点调整后的正数报价。")),
    entry("买", "买入挂单卡牌", "Buy listed cards", "buy(tokenIds,maxPrices)", "开池后按最新卖单与限价购买。", "After launch, buy against live listings and price caps.", custom("buy", "function buy(uint256[] tokenIds, uint256[] maxPrices) payable", `tokenIds=[${id}]; maxPrices=[${en ? "max price wei" : "最高价 wei"}]; value=sum(maxPrices).`)),
    entry("买", "发布求购", "Place a bid", "placeBid(price,quantity)", "求购款存于卡牌合约，没有批次筛选。", "Bid payment is held by the card, with no batch filter.", custom("placeBid", "function placeBid(uint256 price, uint256 quantity) payable", "value=price × quantity wei.")),
    entry("买", "撤销求购", "Cancel bids", "cancelBids(bidIds)", "退回自己未成交的求购款。", "Recover your unfilled bid payment.", custom("cancelBids", "function cancelBids(uint256[] bidIds)", `bidIds=[${en ? "bidId" : "求购编号"}]; value=0.`)),
    entry("卖", "挂单出售", "List cards", "list(tokenIds,prices)", "开池后可挂单，价格须为 0.00001 BNB 的整数倍。", "After launch; prices must be multiples of 0.00001 BNB.", cardCommand("list", id, "0.003", language)),
    entry("卖", "卖给求购", "Sell to a bid", "sellToBid(bidId,tokenIds)", "成交手续费 1%，未领分红归卖家。", "1% fill fee; accrued dividends stay with the seller.", custom("sellToBid", "function sellToBid(uint256 bidId, uint256[] tokenIds)", `bidId=[bidId]; tokenIds=[${id}]; value=0. ${en ? "Ask my minimum price and verify the bidder and remaining quantity." : "询问最低接受价并核对买家和剩余数量。"}`)),
    entry("卖", "下架挂单", "Unlist cards", "unlist(tokenIds)", "撤销自己卡牌的卖单。", "Remove your cards from sale.", cardCommand("unlist", id, undefined, language)),
    entry("收益", "领取分红", "Claim dividends", "claim(tokenIds)", "在卡牌合约领取，保留 NFT。", "Claim from the card contract and keep the NFT.", cardCommand("claim", id, undefined, language)),
    entry("收益", "预售失败退款", "Presale refund", "refund(tokenIds)", "7 天预售期结束仍未卖满，可烧卡全额退款；卖满的那一笔会自动开池，卖满后不可退款。", "Burn for a full refund only if the 7-day presale ends unsold; the 20,000th mint auto-launches the pool, so a sold-out presale cannot be refunded.", custom("refund", "function refund(uint256[] tokenIds)", `${en ? "Read launched, paidMinted, presaleDeadline and chain time. Require not launched, paidMinted below 20,000 and the deadline passed. Burning is irreversible: confirm twice." : "读取 launched、paidMinted、presaleDeadline 及链上时间。必须未开池、未卖满且已过预售截止；烧卡不可逆，二次确认。"} tokenIds=[${id}]; value=0.`)),
    entry("收益", "提取卖卡收入", "Withdraw sale proceeds", "withdrawProceeds(to)", "仅提取属于自己地址的卖卡款。", "Withdraw only your own credited sale proceeds.", custom("withdrawProceeds", "function withdrawProceeds(address to)", en ? "Read proceedsOwed(me)>0; to=me; value=0." : "读取 proceedsOwed(我的地址)>0；to=我的地址；value=0。")),
  ];
}
export const agentCommands = getAgentCommands();
