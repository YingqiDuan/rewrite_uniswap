// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/UniswapV2Router02.sol";
import "./TestUtils.sol";

contract UniswapV2Router02LibraryTest is Test, TestUtils {
    // Events
    event SwapAmount(uint256[] amounts);

    // Test constants
    uint256 private constant _LIQUIDITY_AMOUNT = 100 ether;
    uint256 private constant _SWAP_AMOUNT = 10 ether;
    uint256 private _deadline = block.timestamp + 1 days;

    address private _pairAddress;

    function setUp() public {
        // Setup is already done in TestUtils
        setupFactory();
        setupWeth();
        setupRouter();
        
        // Setup token balances
        tokenA.mint(USER1, 1000 ether);
        tokenB.mint(USER1, 1000 ether);

        // Create the pair for testing
        _pairAddress = factory.createPair(address(tokenA), address(tokenB));
        
        // Add initial liquidity to establish a price ratio
        addLiquidityToPool();
    }
    
    function addLiquidityToPool() internal {
        vm.startPrank(USER1);
        
        tokenA.approve(address(router), _LIQUIDITY_AMOUNT);
        tokenB.approve(address(router), _LIQUIDITY_AMOUNT);
        
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            _LIQUIDITY_AMOUNT,
            _LIQUIDITY_AMOUNT,
            0,
            0,
            USER1,
            _deadline
        );
        
        vm.stopPrank();
    }

    // Test the router's quote function
    function testQuote() public {
        // Setup a 2:1 price ratio
        vm.startPrank(USER1);
        tokenA.approve(address(router), _LIQUIDITY_AMOUNT);
        tokenB.approve(address(router), _LIQUIDITY_AMOUNT * 2);
        
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            _LIQUIDITY_AMOUNT,
            _LIQUIDITY_AMOUNT * 2,
            0,
            0,
            USER1,
            _deadline
        );
        vm.stopPrank();
        
        // Test quote with the established ratio
        uint256 amountB = router.quote(_SWAP_AMOUNT, _LIQUIDITY_AMOUNT, _LIQUIDITY_AMOUNT * 2);
        assertEq(amountB, _SWAP_AMOUNT * 2, "Quote should return correct amount based on reserves ratio");
        
        // Test with zero reserves (should revert)
        vm.expectRevert("UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        router.quote(_SWAP_AMOUNT, 0, _LIQUIDITY_AMOUNT);
        
        vm.expectRevert("UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        router.quote(_SWAP_AMOUNT, _LIQUIDITY_AMOUNT, 0);
    }
    
    // Test the router's getAmountOut function
    function testGetAmountOut() public {
        // Calculate expected output
        uint256 amountOut = router.getAmountOut(_SWAP_AMOUNT, _LIQUIDITY_AMOUNT, _LIQUIDITY_AMOUNT);
        
        // Expected formula: (amountIn * 997 * reserveOut) / (reserveIn * 1000 + amountIn * 997)
        uint256 expectedAmountOut = (_SWAP_AMOUNT * 997 * _LIQUIDITY_AMOUNT) / (_LIQUIDITY_AMOUNT * 1000 + _SWAP_AMOUNT * 997);
        
        assertEq(amountOut, expectedAmountOut, "getAmountOut should calculate correct amount");
        
        // Test with zero input (should revert)
        vm.expectRevert("UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        router.getAmountOut(0, _LIQUIDITY_AMOUNT, _LIQUIDITY_AMOUNT);
        
        // Test with zero reserves (should revert)
        vm.expectRevert("UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        router.getAmountOut(_SWAP_AMOUNT, 0, _LIQUIDITY_AMOUNT);
        
        vm.expectRevert("UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        router.getAmountOut(_SWAP_AMOUNT, _LIQUIDITY_AMOUNT, 0);
    }
    
    // Test the router's getAmountIn function
    function testGetAmountIn() public {
        // Calculate expected input
        uint256 amountIn = router.getAmountIn(_SWAP_AMOUNT, _LIQUIDITY_AMOUNT, _LIQUIDITY_AMOUNT);
        
        // Expected formula: (reserveIn * amountOut * 1000) / ((reserveOut - amountOut) * 997) + 1
        uint256 expectedAmountIn = (_LIQUIDITY_AMOUNT * _SWAP_AMOUNT * 1000) / ((_LIQUIDITY_AMOUNT - _SWAP_AMOUNT) * 997) + 1;
        
        assertEq(amountIn, expectedAmountIn, "getAmountIn should calculate correct amount");
        
        // Test with zero output (should revert)
        vm.expectRevert("UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        router.getAmountIn(0, _LIQUIDITY_AMOUNT, _LIQUIDITY_AMOUNT);
        
        // Test with zero reserves (should revert)
        vm.expectRevert("UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        router.getAmountIn(_SWAP_AMOUNT, 0, _LIQUIDITY_AMOUNT);
        
        vm.expectRevert("UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        router.getAmountIn(_SWAP_AMOUNT, _LIQUIDITY_AMOUNT, 0);
    }
    
    // Test the router's getAmountsOut function
    function testGetAmountsOut() public {
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        
        uint256[] memory amounts = router.getAmountsOut(_SWAP_AMOUNT, path);
        
        assertEq(amounts.length, 2, "Path length should match amounts length");
        assertEq(amounts[0], _SWAP_AMOUNT, "First amount should be input amount");
        assertTrue(amounts[1] > 0, "Output amount should be greater than 0");
        
        // Test empty path (should revert)
        address[] memory emptyPath = new address[](0);
        vm.expectRevert("UniswapV2Library: INVALID_PATH");
        router.getAmountsOut(_SWAP_AMOUNT, emptyPath);
    }
    
    // Test the router's getAmountsIn function
    function testGetAmountsIn() public {
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        
        uint256[] memory amounts = router.getAmountsIn(_SWAP_AMOUNT, path);
        
        assertEq(amounts.length, 2, "Path length should match amounts length");
        assertEq(amounts[1], _SWAP_AMOUNT, "Last amount should be output amount");
        assertTrue(amounts[0] > 0, "Input amount should be greater than 0");
        
        // Test empty path (should revert)
        address[] memory emptyPath = new address[](0);
        vm.expectRevert("UniswapV2Library: INVALID_PATH");
        router.getAmountsIn(_SWAP_AMOUNT, emptyPath);
    }
}