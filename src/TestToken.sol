// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract TestToken is ERC20, Ownable {
    // 1000000 tokens with 18 decimals
    constructor() ERC20("Test Token", "TEST") {
        // Mint 1,000,000 tokens to deployer
        _mint(msg.sender, 1_000_000 * 10**18);
    }

    // Allow anyone to mint test tokens
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
} 