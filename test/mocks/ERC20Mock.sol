// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "../../src/interfaces/IERC20.sol";

contract ERC20Mock is IERC20 {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint public totalSupply;
    
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }
    
    // Public mint function for testing
    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
    
    // Public burn function for testing
    function burn(address from, uint256 amount) external {
        require(balanceOf[from] >= amount, "ERC20: burn amount exceeds balance");
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }
    
    function approve(address spender, uint value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transfer(address to, uint value) virtual external returns (bool) {
        require(balanceOf[msg.sender] >= value, "ERC20: transfer amount exceeds balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) virtual external returns (bool) {
        require(balanceOf[from] >= value, "ERC20: transfer amount exceeds balance");
        require(allowance[from][msg.sender] >= value, "ERC20: transfer amount exceeds allowance");
        
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= value;
        }
        
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
} 