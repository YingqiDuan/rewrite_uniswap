// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/libraries/UQ112x112.sol";

contract UQ112x112Test is Test {
    function testEncode() public {
        uint112 y = 10;
        uint224 result = UQ112x112.encode(y);
        uint224 expected = uint224(y) * 2**112;
        assertEq(result, expected, "Encode function should multiply by 2^112");
    }
    
    function testUqdiv() public {
        uint112 x = 100;
        uint112 y = 10;
        uint224 encoded = UQ112x112.encode(x);
        uint224 result = UQ112x112.uqdiv(encoded, y);
        uint224 expected = encoded / uint224(y);
        assertEq(result, expected, "Uqdiv function should divide correctly");
    }
    
    function testLargeNumbers() public {
        uint112 y = type(uint112).max; // Test with max value
        uint224 result = UQ112x112.encode(y);
        uint224 expected = uint224(y) * 2**112;
        assertEq(result, expected, "Encode should handle max uint112 value");
        
        uint112 divisor = 3;
        uint224 divResult = UQ112x112.uqdiv(result, divisor);
        uint224 divExpected = result / uint224(divisor);
        assertEq(divResult, divExpected, "Uqdiv should handle large encoded values");
    }
} 