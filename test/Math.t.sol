// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/libraries/Math.sol";

contract MathTest is Test {
    function testMin() public {
        assertEq(Math.min(1, 2), 1, "Min should return the smaller value");
        assertEq(Math.min(3, 2), 2, "Min should return the smaller value");
        assertEq(Math.min(5, 5), 5, "Min should return the value when equal");
    }
    
    function testSqrt() public {
        // Test sqrt with values > 3
        assertEq(Math.sqrt(4), 2, "Sqrt of 4 should be 2");
        assertEq(Math.sqrt(9), 3, "Sqrt of 9 should be 3");
        assertEq(Math.sqrt(16), 4, "Sqrt of 16 should be 4");
        
        // Test sqrt with values 1-3
        assertEq(Math.sqrt(1), 1, "Sqrt of 1 should be 1");
        assertEq(Math.sqrt(2), 1, "Sqrt of 2 should be 1");
        assertEq(Math.sqrt(3), 1, "Sqrt of 3 should be 1");
        
        // Test sqrt with 0
        assertEq(Math.sqrt(0), 0, "Sqrt of 0 should be 0");
        
        // Test sqrt with large numbers
        assertEq(Math.sqrt(10000), 100, "Sqrt of 10000 should be 100");
        
        // Test sqrt algorithm convergence
        // This tests the while loop execution, which is important for coverage
        uint y = 1000000000;  // A number where the algorithm needs to run multiple iterations
        uint result = Math.sqrt(y);
        assertTrue(result * result <= y, "Sqrt should be <= than the square root of the input");
        assertTrue((result + 1) * (result + 1) > y, "Sqrt + 1 should be > than the square root of the input");
    }
} 