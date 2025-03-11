// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "./ERC20Mock.sol";

contract MockTokenWithFee is ERC20Mock {
    uint public constant FEE_PERCENT = 5; // 5% fee
    
    constructor(string memory name_, string memory symbol_, uint8) 
        ERC20Mock(name_, symbol_) {}
    
    function transfer(address to, uint256 amount) external override returns (bool) {
        require(balanceOf[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        
        uint256 fee = amount * FEE_PERCENT / 100;
        uint256 netAmount = amount - fee;
        
        // Deduct total amount from sender
        balanceOf[msg.sender] -= amount;
        
        // Add fee to contract
        balanceOf[address(this)] += fee;
        emit Transfer(msg.sender, address(this), fee);
        
        // Add net amount to recipient
        balanceOf[to] += netAmount;
        emit Transfer(msg.sender, to, netAmount);
        
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        require(balanceOf[from] >= amount, "ERC20: transfer amount exceeds balance");
        require(allowance[from][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");
        
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }
        
        uint256 fee = amount * FEE_PERCENT / 100;
        uint256 netAmount = amount - fee;
        
        // Deduct total amount from sender
        balanceOf[from] -= amount;
        
        // Add fee to contract
        balanceOf[address(this)] += fee;
        emit Transfer(from, address(this), fee);
        
        // Add net amount to recipient
        balanceOf[to] += netAmount;
        emit Transfer(from, to, netAmount);
        
        return true;
    }
} 