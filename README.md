# Uniswap V2 Rewrite

A modern implementation of Uniswap V2 upgraded to Solidity 0.8.19, combining core and peripheral contracts in one repository.

## Structure

- **Contracts**: `UniswapV2Factory.sol`, `UniswapV2Pair.sol`, `UniswapV2ERC20.sol`, `UniswapV2Router02.sol`
- **Interfaces**: Factory, Pair, ERC20, Router and other necessary interfaces
- **Libraries**: Math utilities, SafeMath, UQ112x112, UniswapV2Library, TransferHelper

## Upgrade Notes

Key changes from original Uniswap V2:
- Solidity 0.8.19 (from 0.5.16/0.6.6)
- Added SPDX identifiers and `override` modifiers
- Fixed type conversions to comply with 0.8+ requirements
- Retained SafeMath for consistency with original logic

## Source

Based on [Uniswap V2 Core](https://github.com/Uniswap/v2-core), [V2 Periphery](https://github.com/Uniswap/v2-periphery), and [Solidity Lib](https://github.com/Uniswap/solidity-lib).

## License

GPL-3.0
