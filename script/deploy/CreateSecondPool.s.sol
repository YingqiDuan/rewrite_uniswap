// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Script.sol";
import "../../src/SecondToken.sol";
import "../../src/TestToken.sol";
import "../../src/interfaces/IUniswapV2Router02.sol";
import "../../src/interfaces/IWETH.sol";
import "../../src/interfaces/IUniswapV2Factory.sol";

contract CreateSecondPoolScript is Script {
    // Sepolia router address
    address constant ROUTER = 0xb4F2fA0daef4264e5220D0c3A9f761331cD2266D;
    // Sepolia WETH address
    address constant WETH = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    // TestToken address (already deployed) - 替换为你已部署的TEST代币地址
    address constant TEST_TOKEN = 0x0000000000000000000000000000000000000000; // TODO: 填入你已部署的TEST代币地址

    function run() public {
        // Get deployer from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 部署第二个测试代币
        SecondToken secondToken = new SecondToken();
        console.log("SecondToken deployed at: ", address(secondToken));
        console.log("Deployer address: ", msg.sender);

        // 选项1: 创建 SecondToken/WETH 池子
        // Approve router to use tokens
        secondToken.approve(ROUTER, type(uint256).max);
        console.log("Router approved to use SecondToken");

        // Get ETH value (0.1 ETH)
        uint256 ethAmount = 0.1 ether;
        console.log("Adding liquidity with ETH amount: ", ethAmount);
        
        // Token amount to add (1000 tokens)
        uint256 tokenAmount = 1000 * 10**18;
        console.log("Adding token amount: ", tokenAmount);

        // Add liquidity ETH and SecondToken
        IUniswapV2Router02 router = IUniswapV2Router02(ROUTER);
        (uint amountToken, uint amountETH, uint liquidity) = router.addLiquidityETH{value: ethAmount}(
            address(secondToken),
            tokenAmount,
            0, // Min token amount
            0, // Min ETH amount
            msg.sender, // LP tokens recipient
            block.timestamp + 3600 // Deadline
        );

        console.log("SecondToken/WETH liquidity added successfully!");
        console.log("Token amount used: ", amountToken);
        console.log("ETH amount used: ", amountETH);
        console.log("LP tokens received: ", liquidity);

        // 选项2: 创建 SecondToken/TEST 池子
        // 如果你想创建一个不包含WETH的池子，取消下面的注释并替换TEST_TOKEN地址

        /*
        // 获取TEST代币实例
        TestToken testToken = TestToken(TEST_TOKEN);
        
        // 批准路由器使用两种代币
        secondToken.approve(ROUTER, type(uint256).max);
        testToken.approve(ROUTER, type(uint256).max);
        
        // 代币数量
        uint256 secondTokenAmount = 1000 * 10**18;
        uint256 testTokenAmount = 1000 * 10**18;
        
        // 添加流动性
        (uint amountA, uint amountB, uint liquidityAB) = router.addLiquidity(
            address(secondToken),
            address(testToken),
            secondTokenAmount,
            testTokenAmount,
            0, // Min amount A
            0, // Min amount B
            msg.sender, // LP tokens recipient
            block.timestamp + 3600 // Deadline
        );
        
        console.log("SecondToken/TEST liquidity added successfully!");
        console.log("SecondToken amount used: ", amountA);
        console.log("TEST amount used: ", amountB);
        console.log("LP tokens received: ", liquidityAB);
        */

        vm.stopBroadcast();
    }
} 