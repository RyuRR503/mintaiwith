# 新增“币安钱包专用”指令

## 问题
币安内置 AI 能认出短格式指令；网站现有指令太长，还让 AI 去链上查 ABI，币安 AI 查不到就卡住。但其他 AI 用现在的长指令没问题，所以不能直接替换。

## 改法
指令页每张卡上加一个切换：**通用 AI / 币安钱包**。
- 通用 AI：保持现有指令不变。
- 币安钱包：新的短格式，复制按钮复制当前选中的版本。卡牌查询弹窗里的指令也同样可切换。

币安钱包版格式：

```text
你是我的币安 Agent 钱包助手。网络：BNB Chain (chainId=56)。
卡牌金库 Vault：0xbc2d…2b78
请直接调用金库合约的函数（不要去链上查 ABI，函数签名已给出）：
function mint(uint256 count) payable
- 参数 count：1
- value：0.002 BNB（2000000000000000 wei）
生成交易预览让我确认，确认后再发送。
```

要点：开头固定“你是我的币安 Agent 钱包助手”；写完整函数签名；参数一行一个；金额同时写 BNB 和 wei；不要求先读一堆状态。铸造、买卖、求购、分红、兑换、同步、提取全部 11 条都有币安版，中英文同步。

## 技术细节
- `src/lib/fagent/commands.ts` 新增 `binanceCommand` 系列生成函数，签名取自 vault ABI；现有函数不改。
- `AgentCommands.tsx`、`ChainTools.tsx` 加切换按钮，选择记在本地。
- `translations.ts` 补英文；新增测试核对签名和 wei 金额。
