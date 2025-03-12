// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./mocks/MockTokenWithFee.sol";

contract MockTokenWithFeeTest is Test {
    MockTokenWithFee public token;
    address public constant USER1 = address(0x1);
    address public constant USER2 = address(0x2);
    
    function setUp() public {
        token = new MockTokenWithFee("Fee Token", "FEE", 18);
        token.mint(address(this), 1000 ether);
        token.mint(USER1, 1000 ether);
    }
    
    function testTransferWithFee() public {
        uint256 initialBalance = token.balanceOf(address(this));
        uint256 initialRecipientBalance = token.balanceOf(USER1);
        uint256 initialContractBalance = token.balanceOf(address(token));
        
        uint256 transferAmount = 100 ether;
        uint256 expectedFee = transferAmount * token.FEE_PERCENT() / 100;
        uint256 expectedReceivedAmount = transferAmount - expectedFee;
        
        // Execute transfer
        bool success = token.transfer(USER1, transferAmount);
        
        // Verify transfer was successful
        assertTrue(success, "Transfer should succeed");
        
        // Verify balances
        assertEq(
            token.balanceOf(address(this)), 
            initialBalance - transferAmount, 
            "Sender balance should be reduced by the full amount"
        );
        
        assertEq(
            token.balanceOf(USER1), 
            initialRecipientBalance + expectedReceivedAmount, 
            "Recipient should receive amount minus fee"
        );
        
        assertEq(
            token.balanceOf(address(token)), 
            initialContractBalance + expectedFee, 
            "Contract should receive the fee"
        );
    }
    
    function testTransferFromWithFee() public {
        uint256 initialBalance = token.balanceOf(USER1);
        uint256 initialRecipientBalance = token.balanceOf(USER2);
        uint256 initialContractBalance = token.balanceOf(address(token));
        
        uint256 transferAmount = 100 ether;
        uint256 expectedFee = transferAmount * token.FEE_PERCENT() / 100;
        uint256 expectedReceivedAmount = transferAmount - expectedFee;
        
        // Approve spending
        vm.prank(USER1);
        token.approve(address(this), transferAmount);
        
        // Execute transferFrom
        bool success = token.transferFrom(USER1, USER2, transferAmount);
        
        // Verify transfer was successful
        assertTrue(success, "TransferFrom should succeed");
        
        // Verify balances
        assertEq(
            token.balanceOf(USER1), 
            initialBalance - transferAmount, 
            "Sender balance should be reduced by the full amount"
        );
        
        assertEq(
            token.balanceOf(USER2), 
            initialRecipientBalance + expectedReceivedAmount, 
            "Recipient should receive amount minus fee"
        );
        
        assertEq(
            token.balanceOf(address(token)), 
            initialContractBalance + expectedFee, 
            "Contract should receive the fee"
        );
    }
    
    function testTransferFromWithInfiniteApproval() public {
        // Set up infinite approval
        vm.prank(USER1);
        token.approve(address(this), type(uint256).max);
        
        // Execute transferFrom multiple times
        uint256 transferAmount = 100 ether;
        token.transferFrom(USER1, USER2, transferAmount);
        token.transferFrom(USER1, USER2, transferAmount);
        
        // Verify allowance remains at max
        assertEq(
            token.allowance(USER1, address(this)),
            type(uint256).max,
            "Allowance should remain at max"
        );
    }
} 