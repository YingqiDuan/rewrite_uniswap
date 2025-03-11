# Uniswap V2 Rewrite

This repository contains a rewritten version of the Uniswap V2 protocol, integrating core and peripheral contracts in a single repository. Based on the original code, all contracts have been upgraded to Solidity 0.8.19.

## Structure

- `src/`: Main contract files
  - `UniswapV2Factory.sol`: Factory contract for creating trading pairs
  - `UniswapV2Pair.sol`: Pair contract for token exchange
  - `UniswapV2ERC20.sol`: ERC20 implementation for liquidity tokens
  - `UniswapV2Router02.sol`: Router contract for interacting with pairs
  
- `src/interfaces/`: Interface files
  - `IUniswapV2Factory.sol`: Factory interface
  - `IUniswapV2Pair.sol`: Pair interface
  - `IUniswapV2ERC20.sol`: ERC20 interface
  - `IUniswapV2Router01.sol`: Router01 interface
  - `IUniswapV2Router02.sol`: Router02 interface
  - `IERC20.sol`: ERC20 token interface
  - `IWETH.sol`: Wrapped Ether interface
  - `IUniswapV2Callee.sol`: Flash loan callback interface
  
- `src/libraries/`: Library files
  - `Math.sol`: Mathematical utility functions
  - `SafeMath.sol`: Safe math operations (preserved for original logic, although Solidity 0.8+ has built-in overflow checks)
  - `UQ112x112.sol`: Fixed-point math for price calculations
  - `UniswapV2Library.sol`: Helper functions used by the Router
  - `TransferHelper.sol`: Safe token transfer utilities

## Compiler Version

- All contracts: Solidity 0.8.19 (upgraded from original version)
- Original versions:
  - Core contracts (Factory, Pair, ERC20): Solidity 0.5.16
  - Peripheral contracts (Router): Solidity 0.6.6

## Upgrade Notes

To run in a modern Solidity environment, we made the following modifications to the source code:

1. Upgraded all contracts to Solidity 0.8.19
2. Added SPDX license identifiers
3. Removed the `public` modifier from constructors (no longer needed in 0.8+)
4. Added `override` modifiers for interface implementations
5. Replaced `uint(-1)` with `type(uint256).max`
6. Added explicit `uint160` casting in the `pairFor` function to satisfy 0.8+ address conversion requirements
7. Retained the `SafeMath` library, even though 0.8+ has built-in overflow checks for integer operations

## Source Code

This code is based on the original Uniswap V2 repositories:
- [Uniswap V2 Core](https://github.com/Uniswap/v2-core)
- [Uniswap V2 Periphery](https://github.com/Uniswap/v2-periphery)
- [Uniswap Solidity Library](https://github.com/Uniswap/solidity-lib)

## License

The Uniswap V2 protocol is licensed under GPL-3.0.
