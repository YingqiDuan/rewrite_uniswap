// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/libraries/UQ112x112.sol";

contract UQ112x112Test is Test {
    function testEncode() public {
        uint112 value = 5;
        uint224 encoded = UQ112x112.encode(value);
        
        // 5 * 2^112 = 5 * 5192296858534827628530496329220096
        uint224 expected = 25961484292674138142652481646100480;
        
        assertEq(encoded, expected, "Encoding should multiply by 2^112");
    }
    
    function testEncodeZero() public {
        uint112 value = 0;
        uint224 encoded = UQ112x112.encode(value);
        
        assertEq(encoded, 0, "Encoding zero should result in zero");
    }
    
    function testEncodeLargeNumber() public {
        // Test with a value close to the max uint112
        uint112 value = type(uint112).max;
        uint224 encoded = UQ112x112.encode(value);
        
        uint224 expected = uint224(value) << 112;
        
        assertEq(encoded, expected, "Encoding should handle large numbers correctly");
    }
    
    function testUqdiv() public {
        uint224 encoded = UQ112x112.encode(5); // 5 * 2^112
        uint112 divisor = 2;
        
        uint224 result = UQ112x112.uqdiv(encoded, divisor);
        
        // 5 * 2^112 / 2 = 2.5 * 2^112
        uint224 expected = 12980742146337069071326240823050240;
        
        assertEq(result, expected, "Division should be performed correctly");
    }
    
    function testUqdivByOne() public {
        uint224 encoded = UQ112x112.encode(5); // 5 * 2^112
        uint112 divisor = 1;
        
        uint224 result = UQ112x112.uqdiv(encoded, divisor);
        
        // Dividing by 1 should not change the value
        assertEq(result, encoded, "Division by 1 should not change the value");
    }
    
    function testDecode() public {
        // Create an encoded value (7 * 2^112)
        uint224 encoded = UQ112x112.encode(7);
        
        // Decode it - manually shift right by 112 bits and cast to uint112
        uint112 decoded = uint112(encoded >> 112);
        
        // Should get back 7
        assertEq(decoded, 7, "Decoding should recover the original value");
    }
} 