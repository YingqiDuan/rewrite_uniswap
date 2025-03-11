// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
// 在0.8.0+版本中整数操作已自动检查溢出，但我们保留SafeMath以保持原始逻辑

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}
