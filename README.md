# Uniswap V2 Rewrite

这个仓库包含了重写的Uniswap V2协议，将核心和外围合约整合在一个仓库中。在原始代码的基础上，我们已将所有合约升级到Solidity 0.8.19版本。

## 结构

- `src/`: 主要合约文件
  - `UniswapV2Factory.sol`: 创建交易对的工厂合约
  - `UniswapV2Pair.sol`: 用于代币交换的交易对合约
  - `UniswapV2ERC20.sol`: 流动性代币的ERC20实现
  - `UniswapV2Router02.sol`: 用于与交易对交互的路由合约
  
- `src/interfaces/`: 接口文件
  - `IUniswapV2Factory.sol`: 工厂接口
  - `IUniswapV2Pair.sol`: 交易对接口
  - `IUniswapV2ERC20.sol`: ERC20接口
  - `IUniswapV2Router01.sol`: Router01接口
  - `IUniswapV2Router02.sol`: Router02接口
  - `IERC20.sol`: ERC20代币接口
  - `IWETH.sol`: 包装以太币接口
  - `IUniswapV2Callee.sol`: 闪电贷回调接口
  
- `src/libraries/`: 库文件
  - `Math.sol`: 数学工具函数
  - `SafeMath.sol`: 安全数学运算（尽管Solidity 0.8+已内置溢出检查，但保留以保持原始逻辑）
  - `UQ112x112.sol`: 用于价格计算的定点数学
  - `UniswapV2Library.sol`: Router使用的辅助函数
  - `TransferHelper.sol`: 安全代币转账工具

## 编译器版本

- 所有合约: Solidity 0.8.19（已从原始版本升级）
- 原始版本:
  - 核心合约 (Factory, Pair, ERC20): Solidity 0.5.16
  - 外围合约 (Router): Solidity 0.6.6

## 版本升级说明

为了在现代Solidity环境中运行，我们对源代码进行了以下修改：

1. 升级所有合约到Solidity 0.8.19
2. 添加了SPDX许可证标识符
3. 移除了构造函数的`public`修饰符（0.8+不再需要）
4. 为接口实现添加了`override`修饰符
5. 将`uint(-1)`替换为`type(uint256).max`
6. 在`pairFor`函数中添加了`uint160`显式转换以满足0.8+的地址转换要求
7. 保留了`SafeMath`库，即使在0.8+中整数运算已内置溢出检查

## 源代码

此代码基于原始的Uniswap V2仓库：
- [Uniswap V2 Core](https://github.com/Uniswap/v2-core)
- [Uniswap V2 Periphery](https://github.com/Uniswap/v2-periphery)
- [Uniswap Solidity Library](https://github.com/Uniswap/solidity-lib)

## 许可证

Uniswap V2协议使用GPL-3.0许可证。
