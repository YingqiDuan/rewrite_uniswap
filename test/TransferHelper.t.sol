// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/libraries/TransferHelper.sol";
import "./mocks/ERC20Mock.sol";

contract TransferHelperTest is Test {
    ERC20Mock public token;
    address public constant USER = address(0x1);
    
    function setUp() public {
        token = new ERC20Mock("Test Token", "TEST");
        token.mint(address(this), 1000 ether);
        token.mint(USER, 1000 ether);
    }
    
    function testSafeApprove() public {
        TransferHelper.safeApprove(address(token), USER, 100 ether);
        assertEq(token.allowance(address(this), USER), 100 ether, "Approval amount should match");
        
        // Test with zero approval
        TransferHelper.safeApprove(address(token), USER, 0);
        assertEq(token.allowance(address(this), USER), 0, "Should reset approval to zero");
    }
    
    function testSafeTransfer() public {
        uint balanceBefore = token.balanceOf(USER);
        
        TransferHelper.safeTransfer(address(token), USER, 50 ether);
        
        uint balanceAfter = token.balanceOf(USER);
        assertEq(balanceAfter - balanceBefore, 50 ether, "Transfer amount should match");
    }
    
    function testSafeTransferFrom() public {
        // Approve first
        vm.startPrank(USER);
        token.approve(address(this), 100 ether);
        vm.stopPrank();
        
        uint balanceBefore = token.balanceOf(address(this));
        
        TransferHelper.safeTransferFrom(address(token), USER, address(this), 75 ether);
        
        uint balanceAfter = token.balanceOf(address(this));
        assertEq(balanceAfter - balanceBefore, 75 ether, "TransferFrom amount should match");
    }
    
    function testSafeTransferETH() public {
        // Fund this contract with ETH
        vm.deal(address(this), 10 ether);
        
        uint balanceBefore = USER.balance;
        
        TransferHelper.safeTransferETH(USER, 3 ether);
        
        uint balanceAfter = USER.balance;
        assertEq(balanceAfter - balanceBefore, 3 ether, "ETH transfer amount should match");
    }
    
    receive() external payable {
        // Needed to receive ETH
    }
} 