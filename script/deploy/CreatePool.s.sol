// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Script.sol";
import "../../src/TestToken.sol";
import "../../src/interfaces/IUniswapV2Router02.sol";
import "../../src/interfaces/IWETH.sol";

contract CreatePoolScript is Script {
    // Sepolia router address
    address constant ROUTER = 0xb4F2fA0daef4264e5220D0c3A9f761331cD2266D;
    // Sepolia WETH address
    address constant WETH = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;

    function run() public {
        // Get deployer from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy test token
        TestToken testToken = new TestToken();
        console.log("TestToken deployed at: ", address(testToken));
        console.log("Deployer address: ", msg.sender);

        // Approve router to use tokens
        testToken.approve(ROUTER, type(uint256).max);
        console.log("Router approved to use tokens");

        // Get ETH value (0.1 ETH)
        uint256 ethAmount = 0.1 ether;
        console.log("Adding liquidity with ETH amount: ", ethAmount);
        
        // Token amount to add (1000 tokens)
        uint256 tokenAmount = 1000 * 10**18;
        console.log("Adding token amount: ", tokenAmount);

        // Add liquidity ETH and TestToken
        IUniswapV2Router02 router = IUniswapV2Router02(ROUTER);
        (uint amountToken, uint amountETH, uint liquidity) = router.addLiquidityETH{value: ethAmount}(
            address(testToken),
            tokenAmount,
            0, // Min token amount
            0, // Min ETH amount
            msg.sender, // LP tokens recipient
            block.timestamp + 3600 // Deadline
        );

        console.log("Liquidity added successfully!");
        console.log("Token amount used: ", amountToken);
        console.log("ETH amount used: ", amountETH);
        console.log("LP tokens received: ", liquidity);

        vm.stopBroadcast();
    }
} 