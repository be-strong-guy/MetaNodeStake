##  1️ 角色与资产
```
┌─────────┐    ┌────────────┐    ┌──────────┐
│  管理员   │    │  质押用户   │    │ 合约池子  │
│(ADMIN)  │    │   (Alice)  │    │(stToken) │
└─────────┘    └────────────┘    └──────────┘
```
管理员：开池子、调权重、升级合约
质押用户：存币、提币、领奖励
合约池子：存放 任意 ERC20 / ETH；每个池子独立记账
## 2 生命周期流程图
```
① 管理员 addPool
    ↓
② 用户 deposit / depositETH
    ↓
③ 每区块自动算奖励：updatePool
    ↓
④ 用户 claim 领取 MetaNode
    ↓
⑤ 用户 unstake 申请解锁
    ↓
⑥ 锁定期满后 withdraw 提取
```

## 3️ 详细动作拆解
### A. 管理员开池子
```solidity
 addPool(stToken, weight, minDeposit, unlockBlocks)
```
管理员给 一种质押币 开一个池子，并设置：
– poolWeight：权重越大，分到总奖励越多
– minDepositAmount：最低入场金额
– unstakeLockedBlocks：申请解锁后需等待多少区块才能提取
### B. 用户质押
```solidity
deposit(pid, amount)  /  depositETH()
```
用户把 任意 ERC20 或 ETH 打进池子；
立即 获得 “虚拟份额”（stAmount），并开始累积奖励。
### C. 每区块奖励计算
```solidity
updatePool(pid)
```
任何人可触发（前端自动触发）。
公式：

新奖励 = 区块增量 × MetaNodePerBlock × (本池权重 / 总权重)
每个份额奖励 = 新奖励 / 池子总质押量
结果写入 accMetaNodePerST，后续所有用户统一按此值结算。
### D. 用户随时领取奖励

```solidity
claim(pid)
```
按公式：
待领取 = 用户份额 × accMetaNodePerST - 已领取
领取后 finishedMetaNode 增加，防止重复领。
### E. 用户申请解除质押
```solidity
unstake(pid, amount)
```
把用户份额 标记为待解锁，写入 UnstakeRequest 列表；
立即 停止赚取奖励（份额减少，但钱仍在池子内锁定）。
### F. 锁定期满后提取

```solidity
withdraw(pid)
```
遍历用户的 UnstakeRequest，把已到期的全部提取；
原路退回 质押币（ERC20 或 ETH）。
## 4 异常与保护
质押金额 < minDeposit → 直接 revert
解锁期未满 → withdraw 跳过该笔
管理员可随时 暂停/恢复 质押、解锁、领奖
合约使用 UUPS 可升级模式，只有 UPGRADE_ROLE 能升级逻辑

## 5 部署脚本
```shell
source .env
forge script script/DeployMetaNodeStake.s.sol:DeployMetaNodeStake \
  --rpc-url $SEPOLIA_RPC \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_KEY
```

forge script script/DeployMetaNodeStake.s.sol:DeployMetaNodeStake --rpc-url "https://eth-sepolia.g.alchemy.com/v2/tSzwaEyy5RSW69g3GlBbi" --private-key "e98cb1789d5f672c5c2f019e993f537ba0a76ab5c21f70d006dcef0004c71368" --broadcast --verify --etherscan-api-key "WYHY5I36N3PZBB82KRWZWBX6PJUWHZ4ADP"