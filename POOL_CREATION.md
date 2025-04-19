# Uniswap V2 池子创建指南

本指南将帮助你在 Sepolia 测试网上创建新的 Uniswap V2 交易对池子。

## 前提条件

1. 确保你已经安装了 Foundry：
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. 设置环境变量：
   创建一个 `.env` 文件并添加以下内容：
   ```
   PRIVATE_KEY=你的私钥（不带0x前缀）
   RPC_URL_SEPOLIA=https://eth-sepolia.g.alchemy.com/v2/你的API密钥
   ```

3. 加载环境变量：
   ```bash
   source .env
   ```

## 创建新的池子

### 选项1：创建 SecondToken/WETH 池子

这个选项将部署一个新的 SecondToken 代币，并创建一个 SecondToken/WETH 的池子：

```bash
forge script script/deploy/CreateSecondPool.s.sol:CreateSecondPoolScript --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv
```

### 选项2：创建 SecondToken/TEST 池子

如果你想创建一个 SecondToken 和已有 TEST 代币的池子，请先编辑 `script/deploy/CreateSecondPool.s.sol` 文件：

1. 将 TEST_TOKEN 常量值设置为你已部署的 TEST 代币地址
2. 取消注释 "选项2" 部分的代码

然后运行：

```bash
forge script script/deploy/CreateSecondPool.s.sol:CreateSecondPoolScript --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv
```

### 自定义参数

你可以在脚本中修改以下参数：
- 添加的代币数量 (`tokenAmount`)
- 添加的 ETH 数量 (`ethAmount`)
- 对于代币/代币池，可以调整 `secondTokenAmount` 和 `testTokenAmount`

## 验证池子创建

脚本运行完成后，会输出以下信息：
- 新部署的 SecondToken 地址
- 流动性添加成功的确认
- 使用的代币数量
- 获得的 LP 代币数量

## 添加更多流动性

如果你想为已创建的池子添加更多流动性，可以编辑脚本或使用 Uniswap 界面添加流动性。

## 故障排除

如果遇到 gas 估算问题，请尝试增加 gas 限制：

```bash
forge script script/deploy/CreateSecondPool.s.sol:CreateSecondPoolScript --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv --gas-limit 5000000
``` 


== Logs ==
  SecondToken deployed at:  0x944eeEb269Db1829366791CE583a127dB9CEe422
  Deployer address:  0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
  Router approved to use SecondToken
  Adding liquidity with ETH amount:  100000000000000000
  Adding token amount:  1000000000000000000000
  SecondToken/WETH liquidity added successfully!
  Token amount used:  1000000000000000000000
  ETH amount used:  100000000000000000
  LP tokens received:  9999999999999999000