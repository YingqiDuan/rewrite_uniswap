// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Pair.sol";
import "../src/UniswapV2Router02.sol";
import "./mocks/ERC20Mock.sol";
import "./mocks/WETH9.sol";

contract TestUtils is Test {
    // Addresses for different actors
    address public constant OWNER = address(1);
    address public constant USER1 = address(2);
    address public constant USER2 = address(3);
    address public constant FEE_TO = address(4);
    
    // Contracts
    UniswapV2Factory public factory;
    WETH9 public weth;
    UniswapV2Router02 public router;
    ERC20Mock public tokenA;
    ERC20Mock public tokenB;
    ERC20Mock public tokenC;
    
    // Default token amounts
    uint256 public constant INITIAL_MINT_AMOUNT = 1_000_000 ether;
    uint256 public constant LIQUIDITY_AMOUNT = 10_000 ether;
    
    constructor() {
        vm.startPrank(OWNER);
        
        // Deploy factory
        factory = new UniswapV2Factory(OWNER);
        
        // Deploy WETH
        weth = new WETH9();
        
        // Deploy router
        router = new UniswapV2Router02(address(factory), address(weth));
        
        // Deploy test tokens
        tokenA = new ERC20Mock("Token A", "TKNA");
        tokenB = new ERC20Mock("Token B", "TKNB");
        tokenC = new ERC20Mock("Token C", "TKNC");
        
        // Mint initial token amounts
        tokenA.mint(USER1, INITIAL_MINT_AMOUNT);
        tokenB.mint(USER1, INITIAL_MINT_AMOUNT);
        tokenC.mint(USER1, INITIAL_MINT_AMOUNT);
        
        tokenA.mint(USER2, INITIAL_MINT_AMOUNT);
        tokenB.mint(USER2, INITIAL_MINT_AMOUNT);
        tokenC.mint(USER2, INITIAL_MINT_AMOUNT);
        
        vm.stopPrank();
    }
    
    // Helper methods for setting up contracts
    function setupFactory() public {
        vm.startPrank(OWNER);
        factory = new UniswapV2Factory(OWNER);
        vm.stopPrank();
    }
    
    function setupWeth() public {
        weth = new WETH9();
    }
    
    function setupRouter() public {
        router = new UniswapV2Router02(address(factory), address(weth));
    }
    
    // Helper function to create a pair through factory
    function createPair(address tokenA, address tokenB) public returns (address pair) {
        pair = factory.createPair(tokenA, tokenB);
    }
    
    // Helper function to add liquidity
    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 amountA,
        uint256 amountB,
        address to
    ) public returns (uint256 liquidity) {
        vm.startPrank(to);
        
        ERC20Mock(_tokenA).approve(address(router), amountA);
        ERC20Mock(_tokenB).approve(address(router), amountB);
        
        (,, liquidity) = router.addLiquidity(
            _tokenA,
            _tokenB,
            amountA,
            amountB,
            0, // Accept any amount
            0, // Accept any amount
            to,
            block.timestamp + 1 hours
        );
        
        vm.stopPrank();
    }
    
    // Helper function to add ETH liquidity
    function addLiquidityETH(
        address token,
        uint256 amountToken,
        uint256 amountETH,
        address to
    ) public returns (uint256 liquidity) {
        vm.startPrank(to);
        vm.deal(to, amountETH);
        
        ERC20Mock(token).approve(address(router), amountToken);
        
        (,, liquidity) = router.addLiquidityETH{value: amountETH}(
            token,
            amountToken,
            0, // Accept any amount
            0, // Accept any amount
            to,
            block.timestamp + 1 hours
        );
        
        vm.stopPrank();
    }
    
    // Helper function to perform a token swap
    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address to
    ) public returns (uint256 amountOut) {
        vm.startPrank(to);
        
        ERC20Mock(tokenIn).approve(address(router), amountIn);
        
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            0, // Accept any amount out
            path,
            to,
            block.timestamp + 1 hours
        );
        
        amountOut = amounts[1];
        
        vm.stopPrank();
    }
    
    // Helper to create token-token pair and add liquidity
    function setupPair(address _tokenA, address _tokenB, address user, uint256 amount) public returns (address pair, uint256 liquidity) {
        pair = createPair(_tokenA, _tokenB);
        liquidity = addLiquidity(_tokenA, _tokenB, amount, amount, user);
    }
    
    // Helper to create token-WETH pair and add liquidity
    function setupETHPair(address token, address user, uint256 amount) public returns (address pair, uint256 liquidity) {
        pair = createPair(token, address(weth));
        liquidity = addLiquidityETH(token, amount, amount, user);
    }
} 