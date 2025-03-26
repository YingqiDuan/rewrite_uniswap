// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
// In Solidity 0.8.0+ integer operations automatically check for overflow, but we keep SafeMath to maintain the original logic

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
