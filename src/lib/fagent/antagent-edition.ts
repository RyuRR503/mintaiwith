/** Website reference for ANTAGENT-flattened.zip (2026-11-22), not the retired live deployment. */
export const ANTAGENT_EDITION = {
  deploymentConfirmed: false,
  quote: "ANTB",
  quoteAddress: "0x38Dd26788Cf2d901E3aBf04efE3007d459d0Fc53",
  totalCards: 777_777, paidCards: 758_032, teamCards: 19_745,
  presaleCards: 8_429, poolQuote: 120, poolTokens: 63_300_000,
  cardGrant: 8_440, ladderTokens: 29_758_758, burnedAtLaunch: 446_930_459,
  totalTokens: 777_777_777, maxPerTx: 10, maxBefore: 10, maxAfter: 20,
  taxBps: 200, dividendBps: 5000, floorBps: 1500, poolBps: 1500, opsBps: 2000,
  startPrice: 16_000_000_000_000_000n, stepPrice: 800_000_000_000_000n,
  capPrice: 160_000_000_000_000_000n, priceSpan: 1000,
  tiers: [
    { name: ["普通", "Common"], count: 453_767, weight: 2 },
    { name: ["稀有", "Rare"], count: 246_612, weight: 5 },
    { name: ["史诗", "Epic"], count: 58_428, weight: 14 },
    { name: ["传奇", "Legendary"], count: 18_970, weight: 40 },
  ],
} as const;

export function antagentPrice(index: number): bigint {
  if (index <= 0) return 0n;
  const e = ANTAGENT_EDITION;
  const price = e.startPrice + BigInt(Math.floor((index - 1) / e.priceSpan)) * e.stepPrice;
  return price > e.capPrice ? e.capPrice : price;
}
export function ageDiscount(blockAge: number): number {
  if (blockAge >= 5_760_000) return 8000;
  if (blockAge >= 3_840_000) return 8500;
  if (blockAge >= 1_920_000) return 9000;
  return 10000;
}
export function antagentQuote(start: number, count: number, rate = 10000): bigint {
  let total = 0n;
  for (let i = 0; i < count; i++) total += antagentPrice(start + i) * BigInt(rate) / 10000n;
  return total;
}

export const EDITION_RULES = [
  { zh: ["ANTB 底池与付款", "用 ANTB 铸造和交易卡牌，持卡分红也以 ANTB 发放。项目代币与 ANTB 配对组成交易池。\n参与前请准备 ANTB，以及用于网络手续费和卡牌揭晓服务费的少量 BNB。铸造前需完成 ANTB 授权。"], en: ["ANTB pool & payments", "Mint and trade cards with ANTB, and receive card dividends in ANTB. The trading pool pairs the project token with ANTB.\nPrepare ANTB and a small amount of BNB for network and card-reveal fees. ANTB approval is required before minting."] },
  { zh: ["供应与铸造限额", "卡牌上限 777,777 张：付费卡 758,032 张，团队卡 19,745 张。\n铸造需持有 Agent ID，额度按钱包地址计算。开池前每个地址最多铸造 10 张；开池后累计额度提高到 20 张，已铸数量计入总额度。\n例如开池前已铸满 10 张，开池后还可补铸 10 张；开池前铸了 3 张，开池后还可铸 17 张。每笔最多 10 张，可分多笔完成。烧卡不会恢复额度，市场买入不占铸造额度。"], en: ["Supply & mint limits", "777,777 cards: 758,032 paid and 19,745 team cards.\nMinting requires a current Agent ID. Limits apply per wallet address: up to 10 cards before pool launch, rising to 20 total after launch. Previous mints count toward this total.\nIf you minted 10 before launch, you can mint 10 more afterward; if you minted 3, you can mint 17 more. Each transaction allows up to 10 cards, so larger remaining quotas require multiple transactions. Burns do not restore quota; market purchases do not consume mint quota."] },
  { zh: ["阶梯铸造与身份折扣", "第 1 张付费卡原价 0.016 ANTB，每铸出 1,000 张上涨 0.0008 ANTB，最高 0.16 ANTB，开池后仍沿用阶梯。跨档的一笔交易逐张计价。\n持有 Agent ID 满 10 天享九折，满 20 天享八五折，满 30 天享八折。享受折扣需当前持有 Agent ID，并通过持有记录验证；未满足条件按原价。卡牌揭晓服务费不参与折扣。"], en: ["Mint ladder & Agent ID discount", "The first paid card costs 0.016 ANTB. Every 1,000 paid mints adds 0.0008 ANTB, capped at 0.16 ANTB. The ladder continues after launch; a batch crossing a rung is priced card by card.\nHold an Agent ID for 10 days for 10% off, 20 days for 15% off, or 30 days for 20% off. Discounts require a current Agent ID and verified holding records; otherwise full price applies. Card-reveal fees are not discounted."] },
  { zh: ["预售、开池与退款", "预售窗口为 7 天，第 8,429 张付费卡售出时在同笔交易开池；120 ANTB 与 63,300,000 枚项目代币进入主池，LP 销毁。\n预售资金优先用于开池，余款用于运营。全部按原价铸造时合计 160.0096 ANTB；实际募集额随折扣变化，开池须满足资金条件。\n只有七天到期且未售满、未开池，才可烧掉自己的预售卡按实际付款退回 ANTB。卡牌揭晓服务费不退。"], en: ["Presale, launch & refunds", "The presale lasts seven days. The 8,429th paid card triggers launch in the same transaction: 120 ANTB and 63,300,000 project tokens enter the pool; LP is burned.\nPresale funds first support pool launch; the remainder funds operations. Full-price mints total 160.0096 ANTB. Discounts affect actual receipts, and launch requires sufficient funding.\nOnly an unsold, unlaunched presale after the deadline allows card burns for a refund of the ANTB actually paid. Card-reveal fees are not refunded."] },
  { zh: ["稀有度与分红倍数", "以普通卡为 1 倍：普通 453,767 张 / 1 倍；稀有 246,612 张 / 2.5 倍；史诗 58,428 张 / 7 倍；传奇 18,970 张 / 20 倍。\n铸造后卡牌先封存，随后随机揭晓等级；未揭晓不参与分红。揭晓后按分红倍数分配，不是每卡平分：同一轮分红，一张传奇卡可分得一张普通卡的 20 倍；实际金额取决于参与卡牌和可分配资金，不代表保证收益。\n抽取消耗剩余档位库存，实际概率随库存变化。预售退款会把已揭晓档位归还卡组。"], en: ["Rarity & dividend multipliers", "Relative to Common: Common 453,767 / 1×; Rare 246,612 / 2.5×; Epic 58,428 / 7×; Legendary 18,970 / 20×.\nCards are sealed after minting, then randomly reveal their tier. Unrevealed cards earn no dividends. Revealed cards share funds by dividend multiplier, not equally per card. In the same distribution, one Legendary receives 20 times one Common's share. Actual amounts depend on eligible cards and available funds, not a guaranteed return.\nDraws consume the remaining tier inventory, so probabilities change. Presale refunds restore revealed tiers to the deck."] },
  { zh: ["代币领取与转卡", "每张预售卡配置 8,440 枚代币，开池时可领 20%，余下 80% 在 5 天内线性释放；预售与团队配置绑定接收地址，不随卡转移。\n开池后铸造实付款的 25% 归运营、75% 在主池买币。买到的代币 10% 销毁、90% 从铸造起在 5 天内释放。\n开池后卡牌转移时，已解锁部分留给原持有人，仍锁定部分随卡转移，原定释放结束时间不变。地板基金买走该卡，会销毁其未领的关联代币。"], en: ["Token vesting & transfers", "Each presale card allocates 8,440 tokens: 20% at launch and 80% linearly over five days. Presale and team allocations belong to their recipient address and do not follow the NFT.\nAfter launch, 25% of actual mint payments goes to operations and 75% buys tokens in the pool. 10% of tokens bought is burned; 90% vests over five days from minting.\nWhen a post-launch card moves, unlocked tokens stay with its previous holder; the locked remainder follows the NFT with the original end time. A floor purchase burns its unclaimed linked tokens."] },
  { zh: ["交易税与税收分配", "买卖税为 2%。扣除 Flap 协议费用后，金库收到的 ANTB 分为：50% 持卡分红、15% 地板基金、15% 加池储备、20% 运营。\n例如金库实际收到 100 ANTB，则分别为 50 / 15 / 15 / 20 ANTB。分红仍按已揭晓卡牌的分红倍数分配，不承诺固定金额。自动执行与对决服务费由独立 BNB 预算支付。"], en: ["Trading tax & revenue split", "Buy/sell tax is 2%. After Flap protocol fees, ANTB actually delivered to the vault is split: 50% dividends, 15% floor fund, 15% liquidity reserve and 20% operations.\nFor 100 ANTB received, the allocations are 50 / 15 / 15 / 20 ANTB. Dividends use revealed-card multipliers, with no fixed payout promise. Automation and duel service fees are paid from separate BNB budgets."] },
  { zh: ["地板基金与加池", "地板基金按最低挂单向上收卡并销毁，卖家获得挂单价及该卡已累积分红。付费卡最高按该卡实际铸造付款收购；团队卡上限 0.0196 ANTB；高于 0.16 ANTB 的挂单停止扫盘。预售和团队代币配置不会被地板回购销毁。\n自动执行服务费充足时，约每 30 分钟安排一次回购，也可主动发起扫盘。资金或条件不足不会保证成交。\n加池储备低于 0.1 ANTB 暂存，达到条件后延迟约 5 分钟执行，每次最多使用 1 ANTB；加池服务费由独立 BNB 储备支付。加深流动性不等于保证涨价。"], en: ["Floor fund & liquidity", "The floor fund buys eligible listings from the cheapest upward and burns cards. Sellers receive the ask plus accrued dividends. Paid cards are capped at their actual mint payment; team cards at 0.0196 ANTB. Asks above 0.16 ANTB stop the sweep. Presale and team token allocations are not burned by floor purchases.\nWith sufficient automation fees, buybacks are scheduled roughly every 30 minutes; a sweep may also be requested. Funding and eligibility still determine execution.\nLiquidity reserves below 0.1 ANTB remain pending. Eligible additions execute about five minutes later, using up to 1 ANTB per run, with fees from a separate BNB reserve. Deeper liquidity does not guarantee a higher price."] },
  { zh: ["阶梯认购与七天分红", "预留 29,758,758 枚代币，分成开池价的 1.5 / 2 / 3 倍三档。30 分钟平均价格达到某档门槛时，用户才可按该档价格用 ANTB 认购。\n认购收入全部用于持卡分红，在 7 天计划内逐步发放。后续认购款按到账时间并入分配计划，每笔款项的分配周期不一定都是完整七天。"], en: ["Ladder subscriptions & seven-day dividends", "29,758,758 reserved tokens are split across 1.5x / 2x / 3x opening-price rungs. A rung may be purchased with ANTB only while the 30-minute TWAP meets its threshold.\nAll subscription proceeds fund card dividends, distributed gradually under a seven-day schedule. Later receipts join the distribution schedule according to arrival time; each payment does not necessarily receive a fresh seven-day period."] },
  { zh: ["团队配置与开池销毁", "团队卡上限 19,745 张，约占卡牌总量 2.54%。每铸出 19 张付费卡解锁 1 张，达到上限后不再增加，开池后才能领取。团队卡同样需要揭晓并按揭晓等级的分红倍数参与分红。\n每张团队卡配置 8,440 枚代币；开池前已解锁的从开池时开始释放，之后解锁的从解锁时开始释放，均为 20% 立即释放加 5 天线性释放。\n代币总量 777,777,777：开池 63,300,000；预售配置 71,140,760；团队配置 166,647,800；阶梯 29,758,758；未分配 446,930,459 枚在开池交易中转入黑洞销毁。"], en: ["Team allocation & launch burn", "19,745 team cards, about 2.54% of card supply. One unlocks per 19 paid mints, capped at the team limit and claimable only after launch. Team cards also reveal a tier and earn its dividend multiplier.\nEach team card allocates 8,440 tokens. Slots unlocked before launch vest from launch; later slots from their unlock time. Both release 20% immediately and the rest linearly over five days.\n777,777,777 tokens: pool 63,300,000; presale 71,140,760; team 166,647,800; ladder 29,758,758; unallocated 446,930,459 burned to the dead address at launch."] },
  { zh: ["对决、权限与风险", "用 NFT 卡牌参与夺卡对决：等待可取消，配对后锁定；配对后最早约 60 秒随机结算，超过 1 小时仍无赢家可按规则退回双方卡牌。胜场记录在卡上，第 6 次胜利销毁本次赢来的卡，幸存卡胜场归零。无输家补偿。稀有度倍数用于分红，不能当作提高对决胜率的保证。\n服务费以 BNB 支付；独立对决预算最多 0.1 BNB，不动用地板基金支付。\n管理者可调整运营与团队收款地址、转移管理权，合约支持升级。守护者可提取不属于客户资金的 BNB；ANTB 客户账款与代币储备不在该提取权限内。参与前请了解数字资产价格波动、对决输卡与合约升级风险。"], en: ["Duels, permissions & risk", "Duels stake NFT cards. Waiting may be cancelled; paired cards are locked. Random settlement is earliest about 60 seconds after pairing; unresolved matches may return both cards after one hour. Wins follow the card. Its sixth win burns the newly won card and resets the survivor's counter. There is no loser compensation. Dividend rarity multiplier is not a promise of better duel odds.\nService fees are paid in BNB. The separate duel budget is capped at 0.1 BNB and does not use the floor fund.\nAdministrators may change operations and team payment addresses, transfer ownership and upgrade contracts. The Guardian may withdraw BNB that is not customer funds; this permission does not cover ANTB customer balances or token reserves. Participation carries price, card-loss and contract-upgrade risks."] },
] as const;

export const EDITION_COPY: Record<string, readonly [string, string]> = {
  "card.title1": ["独立编号", "Unique number"],
  "card.title2": ["专属身份", "Distinct identity"],
  "mint.presale": ["起始铸造价", "Starting mint price"],
  "mint.open": ["铸造价上限", "Mint price cap"],
  "vest.title": ["预售代币释放", "Presale token release"],
  "nav.minting": ["阶梯折扣铸造", "Mint pricing"],
  "minting.title": ["阶梯折扣铸造", "Mint pricing & discounts"],
  "minting.lead": ["阶梯价格，持有折扣。了解铸造费用，再选择你的卡牌数量。", "Explore ladder prices and Agent ID holding discounts before choosing your mint quantity."],
  "nav.rarity": ["稀有度", "Rarity"],
  "commands.lead": ["通过 Binance Agent Wallet 铸造、交易与领取，操作暂未开放。", "Mint, trade and claim through Binance Agent Wallet. Operations are not open yet."],
  "duel.lead": ["开池后开放的夺卡对决：胜场随卡，第六胜销毁赢来的卡。", "Post-launch NFT duels: wins follow the card; the sixth win burns the newly won card."],
  "vault.lead": ["查看持卡分红、卡牌回购与流动性资金的收支。", "Track card dividends, card buybacks and liquidity funds."],
  "market.lead": ["用 ANTB 买卖卡牌，选择挂单出售或发布求购。", "Buy and sell cards with ANTB through listings and bids."],
  "ladder.lead": ["三档预留代币认购，ANTB 收入进入持卡分红。", "Three reserved-token rungs, with ANTB proceeds funding card dividends."],
  "calc.note": ["阶梯价格 · 身份折扣", "Ladder price · Agent ID discount"],
  "hero.kicker": ["ANTB 底池 / ANTAGENT", "ANTB POOL / ANTAGENT"],
  "hero.line1": ["ANTB 底池，", "An ANTB pool,"],
  "hero.line2": ["由每一张卡驱动", "powered by every card"],
  "hero.sub": ["777,777 张卡 · 四档稀有度 · 按倍数共享链上分红", "777,777 cards · Four rarity tiers · Tier-based on-chain dividends"],
  "hero.fairLabel": ["ANTB 底池 · 阶梯铸造", "ANTB Pool · Ladder Minting"],
  "hero.fair": ["从 0.016 ANTB 起铸，每 1,000 张递增，最高 0.16 ANTB。持有 Agent ID，符合历史持仓证明条件可享折扣。卡牌揭晓为四档稀有度，按等级倍数共享交易手续费分红；第 8,429 张预售卡触发开池。", "Mint from 0.016 ANTB, increasing every 1,000 cards and capped at 0.16 ANTB. Agent ID holders may qualify for verified age discounts. Cards reveal one of four dividend-multiplier tiers. The 8,429th presale card triggers launch."],
  "card.body": ["每张卡拥有独立编号，稀有等级在铸造后随机揭晓。", "Every card has a unique number. Its rarity is randomly revealed after minting."],
  "card.caption": ["777,777 / ANTB 底池版", "777,777 / ANTB POOL EDITION"],
  "rules.lead": ["了解铸造、分红、代币领取、卡牌交易与对决的参与规则。", "Explore the rules for minting, dividends, token claims, card trading and duels."],
  "rarity.title": ["四档稀有度", "Four rarity tiers"],
  "rarity.lead": ["不同分红倍数，同一个分红池。等级由链上揭晓，不由编号决定。", "Different dividend multipliers, one dividend pool. Tiers are revealed on-chain, not derived from the number."],
  "token.lead": ["777,777,777 枚代币：配置、储备与开池销毁。", "777,777,777 tokens: allocations, reserves and launch burn."],
  "phase.1.body": ["前 8,429 张为预售，窗口 7 天。铸造从 0.016 ANTB 起，每 1,000 张增加 0.0008 ANTB；符合证明条件可享 Agent ID 折扣。", "The first 8,429 cards form a seven-day presale. Mint prices start at 0.016 ANTB and rise by 0.0008 every 1,000 cards. Verified Agent ID age discounts may apply."],
  "phase.2.body": ["第 8,429 张成交时触发开池：120 ANTB 与 63,300,000 枚代币进主池，LP 销毁。七天到期未售满、未开池，可烧卡按实付退回 ANTB；揭晓服务费不退。", "The 8,429th mint triggers launch: 120 ANTB and 63,300,000 tokens enter the pool; LP is burned. If unsold and unlaunched after seven days, burn cards for an actual-payment ANTB refund. Reveal fees are not refunded."],
  "phase.3.body": ["每张预售卡配置 8,440 枚代币：开池时可领 1,688 枚，剩余 6,752 枚在 5 天内线性释放。预售配置绑定原接收地址，不随卡转移。", "Each presale card allocates 8,440 tokens: 1,688 at launch and 6,752 over five days. This grant stays with its original recipient, not the NFT."],
  "phase.4.body": ["开池后继续阶梯铸造，最高 0.16 ANTB。实付款用于主池买币，买到的代币 10% 销毁、90% 在 5 天释放；尚锁定部分随卡转移。详细分配见规则。", "The mint ladder continues after launch, capped at 0.16 ANTB. Mint payments buy pool tokens; 10% of tokens bought is burned and 90% vests over five days. Locked tokens follow the card. See rules for the full payment split."],
  "phase.5.body": ["地板基金用 ANTB 从最低合规挂单向上收卡并销毁。约每 30 分钟安排一次，取决于可用资金与自动执行服务费；付费卡收购上限为实际铸造付款。", "The ANTB floor fund buys eligible cheapest listings and burns the cards. Scheduled roughly every 30 minutes, subject to available funds and automation fees. A paid card is capped at its actual mint payment."],
};