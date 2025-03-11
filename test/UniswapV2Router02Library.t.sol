// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "./TestUtils.sol";

contract UniswapV2Router02LibraryTest is TestUtils {
    function setUp() public {
        // Basic setup already done in TestUtils
    }
    
    function testQuote() public {
        // Test the quote function
        uint amountA = 100 ether;
        uint reserveA = 1000 ether;
        uint reserveB = 2000 ether;
        
        uint amountB = router.quote(amountA, reserveA, reserveB);
        assertEq(amountB, 200 ether, "Quote calculation should match expected value");
        
        // Test with different values
        uint amountA2 = 50 ether;
        uint amountB2 = router.quote(amountA2, reserveA, reserveB);
        assertEq(amountB2, 100 ether, "Quote calculation should be proportional");
    }
    
    function testGetAmountOut() public {
        // Test the getAmountOut function
        uint amountIn = 100 ether;
        uint reserveIn = 1000 ether;
        uint reserveOut = 2000 ether;
        
        // Expected formula: amountOut = (amountIn * 997 * reserveOut) / (reserveIn * 1000 + amountIn * 997)
        uint amountOut = router.getAmountOut(amountIn, reserveIn, reserveOut);
        
        // Calculate the expected amount manually
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        uint expectedAmountOut = numerator / denominator;
        
        assertEq(amountOut, expectedAmountOut, "getAmountOut calculation should match expected value");
    }
    
    function testGetAmountIn() public {
        // Test the getAmountIn function
        uint amountOut = 100 ether;
        uint reserveIn = 1000 ether;
        uint reserveOut = 2000 ether;
        
        // Expected formula: amountIn = (reserveIn * amountOut * 1000) / ((reserveOut - amountOut) * 997) + 1
        uint amountIn = router.getAmountIn(amountOut, reserveIn, reserveOut);
        
        // Calculate the expected amount manually
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        uint expectedAmountIn = numerator / denominator + 1;
        
        assertEq(amountIn, expectedAmountIn, "getAmountIn calculation should match expected value");
    }
    
    function testGetAmountsOut() public {
        // Create a pair and add some liquidity
        address pairAddress = factory.createPair(address(tokenA), address(tokenB));
        
        uint amountA = 1000 ether;
        uint amountB = 2000 ether;
        
        vm.startPrank(USER1);
        tokenA.approve(address(router), amountA);
        tokenB.approve(address(router), amountB);
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            amountA,
            amountB,
            0,
            0,
            USER1,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
        
        // Test getAmountsOut
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        
        uint amountIn = 10 ether;
        uint[] memory amounts = router.getAmountsOut(amountIn, path);
        
        assertEq(amounts.length, 2, "Should return amounts for each token in the path");
        assertEq(amounts[0], amountIn, "First amount should be the input amount");
        assertTrue(amounts[1] > 0, "Output amount should be greater than 0");
        
        // Calculate expected output manually
        uint amountOut = router.getAmountOut(amountIn, amountA, amountB);
        assertEq(amounts[1], amountOut, "Output amount should match getAmountOut result");
    }
    
    function testGetAmountsIn() public {
        // Create a pair and add some liquidity
        address pairAddress = factory.createPair(address(tokenA), address(tokenB));
        
        uint amountA = 1000 ether;
        uint amountB = 2000 ether;
        
        vm.startPrank(USER1);
        tokenA.approve(address(router), amountA);
        tokenB.approve(address(router), amountB);
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            amountA,
            amountB,
            0,
            0,
            USER1,
            block.timestamp + 1 hours
        );
        vm.stopPrank();
        
        // Test getAmountsIn
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        
        uint amountOut = 10 ether;
        uint[] memory amounts = router.getAmountsIn(amountOut, path);
        
        assertEq(amounts.length, 2, "Should return amounts for each token in the path");
        assertEq(amounts[1], amountOut, "Last amount should be the output amount");
        assertTrue(amounts[0] > 0, "Input amount should be greater than 0");
        
        // Calculate expected input manually
        uint amountIn = router.getAmountIn(amountOut, amountA, amountB);
        assertEq(amounts[0], amountIn, "Input amount should match getAmountIn result");
    }
}