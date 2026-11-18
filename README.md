# MINT.AI

独立 MINT.AI 卡牌网站。铸造首页 `/`、市场 `/market`、指令 `/commands`、账本 `/vault`、代币经济 `/tokenomics`、规则 `/rules` 均为独立页面。

通过公开 RPC 读取已部署的 BNB Chain 卡牌与金库合约。ABI 由用户选定的 Solidity 源码生成，地址统一保存在项目配置（代码标识仍沿用 fagent）。页面不签名、不发送交易；用户将指令交给币安 Agent 钱包确认执行。余额以 wei 字符串传递，支持批次倒计时、订单分页和成交日志区块分页，读取失败不会退回模拟数据。

## 技术栈
TanStack Start、React、TypeScript、Tailwind CSS。保留平台管理的 Cloud 配置，但页面不调用数据库或领取服务。

## 数据库
已移除复制的迁移，保留空迁移集合；此操作不删除线上数据库记录。
