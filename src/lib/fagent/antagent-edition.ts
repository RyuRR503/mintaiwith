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
  { zh: ["ANTB 底池与付款", "新版主池为项目代币 / ANTB，不是 BNB 池。报价币 ANTB 地址：0x38Dd26788Cf2d901E3aBf04efE3007d459d0Fc53。\n铸造、退款、挂单、求购、地板基金、分红、运营与加池均使用 ANTB；Gas 与 Flap Trigger 服务费仍使用 BNB。付款前需授权 ANTB，铸造的原生 BNB 金额仅支付每张卡的揭晓服务费。"], en: ["ANTB pool & payments", "The new pool pairs the project token with ANTB, not BNB. ANTB: 0x38Dd26788Cf2d901E3aBf04efE3007d459d0Fc53.\nMinting, refunds, listings, bids, floor purchases, dividends, operations and liquidity use ANTB. Gas and Flap Trigger fees still use BNB. Approve ANTB before minting; native BNB attached to a mint pays the reveal service fee per card."] },
  { zh: ["供应与铸造限额", "卡牌上限 777,777 张：付费卡 758,032 张，团队卡 19,745 张。\n铸造者当前必须持有 Agent ID。每笔最多 10 张；开池前每地址累计最多 10 张，开池后累计最多 20 张，包含已铸造数量。烧卡不会恢复额度，市场买入不占铸造额度。"], en: ["Supply & mint limits", "777,777 cards: 758,032 paid and 19,745 team cards.\nMinters must currently hold an Agent ID. Maximum 10 cards per transaction; 10 per address before launch and 20 lifetime after launch, including previous mints. Burns do not restore quota; secondary-market purchases do not consume it."] },
  { zh: ["阶梯铸造与身份折扣", "第 1 张付费卡原价 0.016 ANTB，每铸出 1,000 张上涨 0.0008 ANTB，最高 0.16 ANTB，开池后仍沿用阶梯。跨档的一笔交易逐张计价。\n持有 Agent ID 并提交经 Flap 预言机验证的历史持仓证明：满约 10 / 20 / 30 天按原价的 90% / 85% / 80% 付款。合约按区块差 1,920,000 / 3,840,000 / 5,760,000 判断，天数按约 0.45 秒一块换算；无证明或不足门槛按原价。Trigger 费不打折。"], en: ["Mint ladder & Agent ID discount", "The first paid card costs 0.016 ANTB. Every 1,000 paid mints adds 0.0008 ANTB, capped at 0.16 ANTB. The ladder continues after launch; a batch crossing a rung is priced card by card.\nA current Agent ID holder with an oracle-verified historical balance proof pays 90% / 85% / 80% after roughly 10 / 20 / 30 days. Exact block-age thresholds are 1,920,000 / 3,840,000 / 5,760,000 (days estimated at 0.45 seconds per block). No proof or insufficient age means full price. Trigger fees are not discounted."] },
  { zh: ["预售、开池与退款", "预售窗口为 7 天，第 8,429 张付费卡售出时在同笔交易开池；120 ANTB 与 63,300,000 枚项目代币进入主池，LP 销毁。\n全按原价成交时预售实收为 160.0096 ANTB；折扣会改变实收，开池仍需满足合约的资金条件，不能把原价总额当作保底募集额。余款归运营。\n只有七天到期且未售满、未开池，才可烧掉自己的预售卡按实际付款退回 ANTB。揭晓 Trigger 服务费不退。"], en: ["Presale, launch & refunds", "The presale lasts seven days. The 8,429th paid card triggers launch in the same transaction: 120 ANTB and 63,300,000 project tokens enter the pool; LP is burned.\nFull-price receipts total 160.0096 ANTB. Discounts change actual receipts, and launch remains subject to the contract's funding conditions; this is not a guaranteed raise. The remainder goes to operations.\nOnly an unsold, unlaunched presale after the deadline allows card burns for a refund of the ANTB actually paid. Reveal Trigger fees are not refunded."] },
  { zh: ["稀有度与加权分红", "普通 453,767 张 / 权重 2；稀有 246,612 张 / 权重 5；史诗 58,428 张 / 权重 14；传奇 18,970 张 / 权重 40。\n卡牌先封存，后由 Trigger 在后续区块回调揭晓；未揭晓权重为 0，不参与分红。揭晓后的分红按本卡权重占所有有效卡牌总权重的比例计算，不是每卡平分。传奇权重是普通的 20 倍，不代表保证收益。\n抽取消耗剩余档位库存，实际概率随库存变化；不是 Chainlink VRF。预售退款会把已揭晓档位归还卡组。"], en: ["Rarity & weighted dividends", "Common: 453,767 / weight 2; Rare: 246,612 / weight 5; Epic: 58,428 / weight 14; Legendary: 18,970 / weight 40.\nCards are sealed first, then revealed by a Trigger callback in a later block. Unrevealed cards have zero weight and earn no dividends. Rewards are proportional to card weight divided by total eligible weight, not equally split per card. Legendary has 20 times Common's weight, not a guaranteed return.\nDraws consume the remaining tier inventory, so probabilities change. This is not Chainlink VRF. Presale refunds restore revealed tiers to the deck."] },
  { zh: ["代币领取与转卡", "每张预售卡配置 8,440 枚代币，开池时可领 20%，余下 80% 在 5 天内线性释放；预售与团队配置绑定接收地址，不随卡转移。\n开池后铸造实付款的 25% 归运营、75% 在主池买币。买到的代币 10% 销毁、90% 从铸造起在 5 天内释放。\n开池后卡牌转移时，已解锁部分留给原持有人，仍锁定部分随卡转移，原定释放结束时间不变。地板基金买走该卡，会销毁其未领的关联代币。"], en: ["Token vesting & transfers", "Each presale card allocates 8,440 tokens: 20% at launch and 80% linearly over five days. Presale and team allocations belong to their recipient address and do not follow the NFT.\nAfter launch, 25% of actual mint payments goes to operations and 75% buys tokens in the pool. 10% of tokens bought is burned; 90% vests over five days from minting.\nWhen a post-launch card moves, unlocked tokens stay with its previous holder; the locked remainder follows the NFT with the original end time. A floor purchase burns its unclaimed linked tokens."] },
  { zh: ["交易税与税收分配", "买卖税为 2%。扣除 Flap 协议费用后，金库收到的 ANTB 分为：50% 持卡分红、15% 地板基金、15% 加池储备、20% 运营。\n例如金库实际收到 100 ANTB，则分别为 50 / 15 / 15 / 20 ANTB。分红仍按已揭晓卡牌权重分配，不承诺固定金额。Trigger 和对决 BNB 预算不会由 ANTB 税收自动补充。"], en: ["Trading tax & revenue split", "Buy/sell tax is 2%. After Flap protocol fees, ANTB actually delivered to the vault is split: 50% dividends, 15% floor fund, 15% liquidity reserve and 20% operations.\nFor 100 ANTB received, the allocations are 50 / 15 / 15 / 20 ANTB. Dividends use revealed-card weights, with no fixed payout promise. ANTB tax does not automatically fund native BNB Trigger or duel budgets."] },
  { zh: ["地板基金与加池", "地板基金按最低挂单向上收卡并销毁，卖家获得挂单价及该卡已累积分红。付费卡最高按该卡实际铸造付款收购；团队卡上限 0.0196 ANTB；高于 0.16 ANTB 的挂单停止扫盘。预售和团队代币配置不会被地板回购销毁。\nTrigger BNB 储备足够时约每 30 分钟安排扫盘，也可调用 sweepFloor。资金或条件不足不会保证成交。\n加池储备低于 0.1 ANTB 暂存，达到条件后延迟约 5 分钟执行，每次最多使用 1 ANTB；加池服务费由独立 BNB 储备支付。加深流动性不等于保证涨价。"], en: ["Floor fund & liquidity", "The floor fund buys eligible listings from the cheapest upward and burns cards. Sellers receive the ask plus accrued dividends. Paid cards are capped at their actual mint payment; team cards at 0.0196 ANTB. Asks above 0.16 ANTB stop the sweep. Presale and team token allocations are not burned by floor purchases.\nA funded BNB Trigger reserve schedules sweeps roughly every 30 minutes; sweepFloor is also callable. Funding and eligibility still determine execution.\nLiquidity reserves below 0.1 ANTB remain pending. Eligible additions execute about five minutes later, using up to 1 ANTB per run, with fees from a separate BNB reserve. Deeper liquidity does not guarantee a higher price."] },
  { zh: ["阶梯认购与七天分红", "预留 29,758,758 枚代币，分成开池价的 1.5 / 2 / 3 倍三档。30 分钟平均价格达到某档门槛时，用户才可按该档价格用 ANTB 认购。\n这不是自动向主池卖币，也不是强制回购。认购收入全部流向持卡分红，按合约的 7 天流式计划分配；后续款项按主流与侧流规则处理，不承诺每笔款项都重新开始七天。"], en: ["Ladder subscriptions & seven-day dividends", "29,758,758 reserved tokens are split across 1.5x / 2x / 3x opening-price rungs. A rung may be purchased with ANTB only while the 30-minute TWAP meets its threshold.\nThis is not an automatic sale into the main pool or a compulsory buyback. All subscription proceeds fund card dividends under seven-day stream rules; later payments follow primary/side-stream accounting rather than always restarting seven days."] },
  { zh: ["团队配置与开池销毁", "团队卡上限 19,745 张，约占卡牌总量 2.54%，不再是旧版 5%。每铸出 19 张付费卡解锁 1 张，达到上限后不再增加，开池后才能领取。团队卡同样需要揭晓并按抽出的权重参与分红。\n每张团队卡配置 8,440 枚代币；开池前已解锁的从开池时开始释放，之后解锁的从解锁时开始释放，均为 20% 立即释放加 5 天线性释放。\n代币总量 777,777,777：开池 63,300,000；预售配置 71,140,760；团队配置 166,647,800；阶梯 29,758,758；未分配 446,930,459 枚在开池交易中转入黑洞销毁。"], en: ["Team allocation & launch burn", "19,745 team cards, about 2.54% of card supply, not the old 5%. One unlocks per 19 paid mints, capped at the team limit and claimable only after launch. Team cards also reveal a tier and earn its weight.\nEach team card allocates 8,440 tokens. Slots unlocked before launch vest from launch; later slots from their unlock time. Both release 20% immediately and the rest linearly over five days.\n777,777,777 tokens: pool 63,300,000; presale 71,140,760; team 166,647,800; ladder 29,758,758; unallocated 446,930,459 burned to the dead address at launch."] },
  { zh: ["对决、权限与风险", "对决仍以 NFT 卡牌为赌注：等待可取消，配对后锁定；最早约 60 秒由 Trigger 回调结算，超过 1 小时仍无赢家可按规则退回双方卡牌。胜场记录在卡上，第 6 次胜利销毁本次赢来的卡，幸存卡胜场归零。无输家补偿。稀有度权重用于分红，不能当作提高对决胜率的保证。\n服务费仍为 BNB；独立对决预算最多 0.1 BNB，不动用地板基金支付。\nOwner / Guardian 可调整运营钱包、团队钱包及所有权；合约通过 Beacon 管理升级。Guardian 可取走非客户的原生 BNB，不能据此说能提走 ANTB 客户账款或代币储备。数字资产、随机对决及升级权限均有风险。"], en: ["Duels, permissions & risk", "Duels stake NFT cards. Waiting may be cancelled; paired cards are locked. Trigger settlement is earliest about 60 seconds later; unresolved matches may return both cards after one hour. Wins follow the card. Its sixth win burns the newly won card and resets the survivor's counter. There is no loser compensation. Dividend rarity weight is not a promise of better duel odds.\nService fees remain BNB. The separate duel budget is capped at 0.1 BNB and does not use the floor fund.\nOwner / Guardian may change operations/team wallets and ownership; Beacon contracts manage upgrades. Guardian may withdraw non-customer native BNB, which is not authority to withdraw ANTB customer liabilities or token reserves. Digital assets, random duels and upgrade powers carry risk."] },
] as const;

export const EDITION_COPY: Record<string, readonly [string, string]> = {
  "nav.rarity": ["稀有度", "Rarity"],
  "commands.lead": ["新版操作尚未开放；上线后通过 Binance Agent Wallet 确认交易。", "New-edition operations are not open. Once live, confirm transactions through Binance Agent Wallet."],
  "duel.lead": ["开池后开放的夺卡对决：胜场随卡，第六胜销毁赢来的卡。", "Post-launch NFT duels: wins follow the card; the sixth win burns the newly won card."],
  "vault.lead": ["ANTB 税收分配、地板基金与加池储备，新版账本待上线。", "ANTB revenue, floor fund and liquidity reserves. The new ledger is not live yet."],
  "market.lead": ["以 ANTB 计价的卡牌挂单与求购，新版市场待上线。", "Card listings and bids priced in ANTB. The new market is not live yet."],
  "ladder.lead": ["三档预留代币认购，ANTB 收入进入持卡分红。", "Three reserved-token rungs, with ANTB proceeds funding card dividends."],
  "calc.note": ["阶梯价格 · 身份折扣", "Ladder price · Agent ID discount"],
  "hero.kicker": ["ANTB 底池 / ANTAGENT", "ANTB POOL / ANTAGENT"],
  "hero.line1": ["ANTB 底池，", "An ANTB pool,"],
  "hero.line2": ["由每一张卡驱动", "powered by every card"],
  "hero.sub": ["777,777 张卡 · 四档稀有度 · 按权重共享链上分红", "777,777 cards · Four rarity tiers · Weighted on-chain dividends"],
  "hero.fairLabel": ["ANTB 底池 · 阶梯铸造", "ANTB Pool · Ladder Minting"],
  "hero.fair": ["从 0.016 ANTB 起铸，每 1,000 张递增，最高 0.16 ANTB。持有 Agent ID，符合历史持仓证明条件可享折扣。卡牌揭晓为四档稀有度，按权重共享交易手续费分红；第 8,429 张预售卡触发开池。", "Mint from 0.016 ANTB, increasing every 1,000 cards and capped at 0.16 ANTB. Agent ID holders may qualify for verified age discounts. Cards reveal one of four weighted dividend tiers. The 8,429th presale card triggers launch."],
  "card.body": ["编号决定展示艺术，不决定链上稀有度。真实等级由合约揭晓。", "The number determines display art, not on-chain rarity. Real tiers are revealed by the contract."],
  "card.caption": ["777,777 / ANTB 底池版", "777,777 / ANTB POOL EDITION"],
  "rules.lead": ["最新版合约：ANTB 底池、稀有度、身份折扣与完整经济规则。", "Latest-source rules: ANTB pool, rarity, Agent ID discounts and economics."],
  "rarity.title": ["四档稀有度", "Four rarity tiers"],
  "rarity.lead": ["不同权重，同一个分红池。等级由链上揭晓，不由编号决定。", "Different weights, one dividend pool. Tiers are revealed on-chain, not derived from the number."],
  "token.lead": ["777,777,777 枚代币：配置、储备与开池销毁。", "777,777,777 tokens: allocations, reserves and launch burn."],
  "phase.1.body": ["前 8,429 张为预售，窗口 7 天。铸造从 0.016 ANTB 起，每 1,000 张增加 0.0008 ANTB；符合证明条件可享 Agent ID 折扣。", "The first 8,429 cards form a seven-day presale. Mint prices start at 0.016 ANTB and rise by 0.0008 every 1,000 cards. Verified Agent ID age discounts may apply."],
  "phase.2.body": ["第 8,429 张成交时触发开池：120 ANTB 与 63,300,000 枚代币进主池，LP 销毁。七天到期未售满、未开池，可烧卡按实付退回 ANTB；Trigger 费不退。", "The 8,429th mint triggers launch: 120 ANTB and 63,300,000 tokens enter the pool; LP is burned. If unsold and unlaunched after seven days, burn cards for an actual-payment ANTB refund. Trigger fees are not refunded."],
  "phase.3.body": ["每张预售卡配置 8,440 枚代币：开池时可领 1,688 枚，剩余 6,752 枚在 5 天内线性释放。预售配置绑定原接收地址，不随卡转移。", "Each presale card allocates 8,440 tokens: 1,688 at launch and 6,752 over five days. This grant stays with its original recipient, not the NFT."],
  "phase.4.body": ["开池后继续阶梯铸造，最高 0.16 ANTB。实付款用于主池买币，买到的代币 10% 销毁、90% 在 5 天释放；尚锁定部分随卡转移。详细分配见规则。", "The mint ladder continues after launch, capped at 0.16 ANTB. Mint payments buy pool tokens; 10% of tokens bought is burned and 90% vests over five days. Locked tokens follow the card. See rules for the full payment split."],
  "phase.5.body": ["地板基金用 ANTB 从最低合规挂单向上收卡并销毁。约每 30 分钟安排一次，受资金与 Trigger 条件限制；付费卡收购上限为实际铸造付款。", "The ANTB floor fund buys eligible cheapest listings and burns the cards. Scheduled roughly every 30 minutes, subject to funding and Trigger availability. A paid card is capped at its actual mint payment."],
};