# Uniswap V2 Deployment Guide

This guide will help you deploy the Uniswap V2 contracts to Ethereum mainnet or any testnet.

## Prerequisites

### 1. Install Dependencies

Make sure you have Foundry installed. If not, install it with the following commands:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Set Environment Variables

Create a `.env` file and add the following:

```
PRIVATE_KEY=your_private_key_without_0x_prefix
ETHERSCAN_API_KEY=your_etherscan_api_key (optional, for contract verification)
RPC_URL_MAINNET=https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY
RPC_URL_SEPOLIA=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
```

Load the environment variables:

```bash
source .env
```

## Deploy to Testnet (Sepolia)

```bash
forge script script/Deploy.s.sol:DeployUniswapV2 --rpc-url $RPC_URL_SEPOLIA --broadcast --verify
```

## Deploy to Mainnet

```bash
forge script script/Deploy.s.sol:DeployUniswapV2 --rpc-url $RPC_URL_MAINNET --broadcast --verify
```

## Deploy to Other Networks

You can modify the `Deploy.s.sol` script to support additional networks and deploy using the appropriate RPC URL.

## Verify Successful Deployment

After deployment completes, the script will output:

```
UniswapV2Factory deployed at: 0x...
UniswapV2Router02 deployed at: 0x...
WETH address: 0x...
```

Record these addresses for future use.

## Interacting with the Contracts

You can interact with the deployed contracts using the `cast` command or a frontend application:

```bash
# Create a token pair
cast send <FACTORY_ADDRESS> "createPair(address,address)(address)" <TOKEN_A> <TOKEN_B> --private-key $PRIVATE_KEY --rpc-url $RPC_URL

# Add liquidity
cast send <ROUTER_ADDRESS> "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)(uint256,uint256,uint256)" <TOKEN_A> <TOKEN_B> <AMOUNT_A> <AMOUNT_B> <MIN_A> <MIN_B> <TO_ADDRESS> <DEADLINE> --private-key $PRIVATE_KEY --rpc-url $RPC_URL
```

## Code Check and Security

Before deploying to mainnet, ensure:

1. Run all tests: `forge test`
2. Analyze code coverage: `forge coverage`
3. Consider an external audit

## Troubleshooting

If you encounter gas estimation issues, try increasing the gas limit:

```bash
forge script script/Deploy.s.sol:DeployUniswapV2 --rpc-url $RPC_URL --broadcast --verify --gas-limit 5000000
``` 