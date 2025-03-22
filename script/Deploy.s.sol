// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Router02.sol";

contract DeployUniswapV2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address wethAddress;
        
        // Choose the correct WETH address based on chain ID
        if (block.chainid == 1) {
            // Ethereum Mainnet
            wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        } else if (block.chainid == 5) {
            // Goerli Testnet
            wethAddress = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
        } else if (block.chainid == 11155111) {
            // Sepolia Testnet
            wethAddress = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;
        } else if (block.chainid == 42161) {
            // Arbitrum One
            wethAddress = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
        } else if (block.chainid == 421613) {
            // Arbitrum Goerli
            wethAddress = 0x980B62Da83eFf3D4576C647993b0c1D7faf17c73;
        } else {
            revert("Unsupported chain");
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy Factory contract
        address feeToSetter = vm.addr(deployerPrivateKey);
        UniswapV2Factory factory = new UniswapV2Factory(feeToSetter);
        
        // Deploy Router contract
        UniswapV2Router02 router = new UniswapV2Router02(
            address(factory),
            wethAddress
        );
        
        vm.stopBroadcast();
        
        console.log("UniswapV2Factory deployed at:", address(factory));
        console.log("UniswapV2Router02 deployed at:", address(router));
        console.log("WETH address:", wethAddress);
    }
} 