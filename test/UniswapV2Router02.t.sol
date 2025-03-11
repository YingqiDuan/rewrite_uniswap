// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "./TestUtils.sol";
import "../src/UniswapV2Router02.sol";
import "../src/libraries/UniswapV2Library.sol";
import "../src/UniswapV2Pair.sol";
import "./mocks/ERC20Mock.sol";

contract UniswapV2Router02Test is TestUtils {
    // Addresses for tokens used in tests
    address private _tokenA;
    address private _tokenB;
    address private _tokenC;
    address private _wethAddress;
    
    // Token amounts for testing
    uint256 private constant _INITIAL_AMOUNT_A = 100 ether;
    uint256 private constant _INITIAL_AMOUNT_B = 100 ether;
    uint256 private constant _SWAP_AMOUNT = 1 ether;
    uint256 private constant _LIQUIDITY_AMOUNT = 10 ether;
    uint256 private constant _MIN_AMOUNT = 1;
    uint256 private constant _ETH_AMOUNT = 5 ether;
    
    // Deadline for transactions
    uint256 private _deadline;
    
    function setUp() public {
        // Initialize token addresses
        _tokenA = address(tokenA);
        _tokenB = address(tokenB);
        _tokenC = address(tokenC);
        _wethAddress = address(weth);
        
        // Set deadline for transactions
        _deadline = block.timestamp + 1 hours;
    }
    
    // Basic sanity check that router was initialized correctly
    function testRouterInitialization() public {
        assertEq(router.factory(), address(factory), "Router factory address mismatch");
        assertEq(router.WETH(), address(weth), "Router WETH address mismatch");
    }
    
    // ============ Add Liquidity Tests ============
    
    // Test adding liquidity to a new pair
    function testAddLiquidityNewPair() public {
        // Prepare initial setup
        vm.startPrank(USER1);
        
        // Approve router to spend tokens
        tokenA.approve(address(router), _LIQUIDITY_AMOUNT);
        tokenB.approve(address(router), _LIQUIDITY_AMOUNT);
        
        // Verify no pair exists yet
        address pairAddress = factory.getPair(_tokenA, _tokenB);
        assertEq(pairAddress, address(0), "Pair should not exist before adding liquidity");
        
        // Call addLiquidity
        (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity(
            _tokenA,
            _tokenB,
            _LIQUIDITY_AMOUNT,
            _LIQUIDITY_AMOUNT,
            _MIN_AMOUNT,
            _MIN_AMOUNT,
            USER1,
            _deadline
        );
        
        // Pair should be created
        pairAddress = factory.getPair(_tokenA, _tokenB);
        assertTrue(pairAddress != address(0), "Pair should be created");
        
        // Verify returned amounts
        assertEq(amountA, _LIQUIDITY_AMOUNT, "Returned amountA should match provided amount");
        assertEq(amountB, _LIQUIDITY_AMOUNT, "Returned amountB should match provided amount");
        
        // Verify LP tokens were minted (minus MINIMUM_LIQUIDITY)
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        uint256 expectedLiquidity = Math.sqrt(_LIQUIDITY_AMOUNT * _LIQUIDITY_AMOUNT) - pair.MINIMUM_LIQUIDITY();
        assertEq(liquidity, expectedLiquidity, "Liquidity amount mismatch");
        assertEq(pair.balanceOf(USER1), expectedLiquidity, "LP balance mismatch");
        
        // Verify reserves
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        assertEq(uint256(reserve0), _LIQUIDITY_AMOUNT, "Reserve0 mismatch");
        assertEq(uint256(reserve1), _LIQUIDITY_AMOUNT, "Reserve1 mismatch");
        
        vm.stopPrank();
    }
    
    // Test adding liquidity to an existing pair
    function testAddLiquidityExistingPair() public {
        // First create the pair and add initial liquidity
        vm.startPrank(USER1);
        tokenA.approve(address(router), _LIQUIDITY_AMOUNT);
        tokenB.approve(address(router), _LIQUIDITY_AMOUNT);
        
        (uint256 initialAmountA, uint256 initialAmountB, uint256 initialLiquidity) = router.addLiquidity(
            _tokenA,
            _tokenB,
            _LIQUIDITY_AMOUNT,
            _LIQUIDITY_AMOUNT,
            _MIN_AMOUNT,
            _MIN_AMOUNT,
            USER1,
            _deadline
        );
        vm.stopPrank();
        
        address pairAddress = factory.getPair(_tokenA, _tokenB);
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        
        // Now add more liquidity from USER2
        vm.startPrank(USER2);
        uint256 additionalAmount = _LIQUIDITY_AMOUNT / 2;
        tokenA.approve(address(router), additionalAmount);
        tokenB.approve(address(router), additionalAmount);
        
        uint256 initialTotalSupply = pair.totalSupply();
        
        // Call addLiquidity
        (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity(
            _tokenA,
            _tokenB,
            additionalAmount,
            additionalAmount,
            _MIN_AMOUNT,
            _MIN_AMOUNT,
            USER2,
            _deadline
        );
        
        // Verify proportional liquidity
        uint256 expectedLiquidity = (additionalAmount * initialTotalSupply) / _LIQUIDITY_AMOUNT;
        assertEq(liquidity, expectedLiquidity, "Additional liquidity amount mismatch");
        assertEq(pair.balanceOf(USER2), expectedLiquidity, "USER2 LP balance mismatch");
        
        // Verify reserves increased
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        assertEq(uint256(reserve0), _LIQUIDITY_AMOUNT + additionalAmount, "Reserve0 mismatch after adding liquidity");
        assertEq(uint256(reserve1), _LIQUIDITY_AMOUNT + additionalAmount, "Reserve1 mismatch after adding liquidity");
        
        vm.stopPrank();
    }
    
    // Test adding liquidity with slippage protection
    function testAddLiquidityWithSlippage() public {
        // First, USER2 creates a pair with imbalanced reserves (2:1 ratio)
        vm.startPrank(USER2);
        tokenA.approve(address(router), 20 ether);
        tokenB.approve(address(router), 10 ether);
        
        // Add initial liquidity with 2:1 ratio (tokenA:tokenB)
        (uint amountA, uint amountB, uint liquidity) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            20 ether,
            10 ether,
            1, // min A
            1, // min B
            USER2,
            block.timestamp + 3600 // 1 hour in seconds
        );
        vm.stopPrank();
        
        // Verify the pair was created with the expected reserves
        address pairAddress = factory.getPair(address(tokenA), address(tokenB));
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairAddress).getReserves();
        
        // Now USER1 tries to add liquidity with equal amounts
        vm.startPrank(USER1);
        tokenA.approve(address(router), 10 ether);
        tokenB.approve(address(router), 10 ether);
        
        uint balanceABefore = tokenA.balanceOf(USER1);
        uint balanceBBefore = tokenB.balanceOf(USER1);
        
        // USER1 tries to add equal amounts, but due to the 2:1 ratio in the pool,
        // one token amount will be adjusted
        (uint returnedAmountA, uint returnedAmountB, ) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            10 ether,
            10 ether,
            1, // min A
            1, // min B
            USER1,
            block.timestamp + 3600 // 1 hour in seconds
        );
        
        uint balanceAAfter = tokenA.balanceOf(USER1);
        uint balanceBAfter = tokenB.balanceOf(USER1);
        
        uint spentAmountA = balanceABefore - balanceAAfter;
        uint spentAmountB = balanceBBefore - balanceBAfter;
        
        // Verify that the spent amounts match the returned amounts
        assertEq(spentAmountA, returnedAmountA, "Spent amount of tokenA should match returned amountA");
        assertEq(spentAmountB, returnedAmountB, "Spent amount of tokenB should match returned amountB");
        
        // Based on the trace, we can see that tokenB is being adjusted down (5 ether instead of 10 ether)
        // This is because the pool has a 2:1 ratio (tokenA:tokenB)
        // When adding 10 ether of tokenA, we need 5 ether of tokenB to maintain the ratio
        assertTrue(returnedAmountB < 10 ether, "amountB should be adjusted down due to pool ratio");
        
        // Test that if minimum amounts are too high, the transaction reverts
        vm.expectRevert("UniswapV2Router: INSUFFICIENT_B_AMOUNT");
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            10 ether,
            10 ether,
            1, // min A
            10 ether, // min B - too high, should revert
            USER1,
            block.timestamp + 3600 // 1 hour in seconds
        );
        
        vm.stopPrank();
    }
    
    // Test adding ETH liquidity
    function testAddLiquidityETH() public {
        // Prepare initial setup
        vm.startPrank(USER1);
        vm.deal(USER1, _ETH_AMOUNT); // Give USER1 some ETH
        
        // Approve router to spend tokens
        tokenA.approve(address(router), _LIQUIDITY_AMOUNT);
        
        // Verify no pair exists yet
        address pairAddress = factory.getPair(_tokenA, _wethAddress);
        assertEq(pairAddress, address(0), "Pair should not exist before adding liquidity");
        
        // Call addLiquidityETH
        (uint256 amountToken, uint256 amountETH, uint256 liquidity) = router.addLiquidityETH{value: _ETH_AMOUNT}(
            _tokenA,
            _LIQUIDITY_AMOUNT,
            _MIN_AMOUNT,
            _MIN_AMOUNT,
            USER1,
            _deadline
        );
        
        // Pair should be created
        pairAddress = factory.getPair(_tokenA, _wethAddress);
        assertTrue(pairAddress != address(0), "Pair should be created");
        
        // Verify returned amounts
        assertEq(amountToken, _LIQUIDITY_AMOUNT, "Returned amountToken should match provided amount");
        assertEq(amountETH, _ETH_AMOUNT, "Returned amountETH should match provided ETH");
        
        // Verify LP tokens were minted
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        uint256 expectedLiquidity = Math.sqrt(_LIQUIDITY_AMOUNT * _ETH_AMOUNT) - pair.MINIMUM_LIQUIDITY();
        assertEq(liquidity, expectedLiquidity, "Liquidity amount mismatch");
        assertEq(pair.balanceOf(USER1), expectedLiquidity, "LP balance mismatch");
        
        // Verify WETH balance in pair
        assertEq(IERC20(_wethAddress).balanceOf(pairAddress), _ETH_AMOUNT, "WETH balance in pair mismatch");
        
        // Verify token balance in pair
        assertEq(tokenA.balanceOf(pairAddress), _LIQUIDITY_AMOUNT, "Token balance in pair mismatch");
        
        vm.stopPrank();
    }
    
    // Test adding ETH liquidity with refund
    function testAddLiquidityETHWithRefund() public {
        // Prepare initial setup
        vm.startPrank(USER1);
        
        // First create a pair with a specific ratio (2 tokens : 1 ETH)
        vm.deal(USER1, _ETH_AMOUNT);
        tokenA.approve(address(router), _LIQUIDITY_AMOUNT * 2);
        
        (uint256 initialTokenAmount, uint256 initialETHAmount, ) = router.addLiquidityETH{value: _ETH_AMOUNT}(
            _tokenA,
            _LIQUIDITY_AMOUNT * 2, // 2:1 ratio of token:ETH
            _MIN_AMOUNT,
            _MIN_AMOUNT,
            USER1,
            _deadline
        );
        
        // Now try to add more liquidity with excess ETH
        // The router should only use the amount needed to maintain the 2:1 ratio
        uint256 excessETH = _ETH_AMOUNT * 10; // Much more than needed
        vm.deal(USER1, excessETH);
        tokenA.approve(address(router), _LIQUIDITY_AMOUNT);
        
        // Save initial ETH balance
        uint256 initialETHBalance = USER1.balance;
        
        // Call addLiquidityETH with excess ETH
        // Since we're adding _LIQUIDITY_AMOUNT of tokens and the ratio is 2:1,
        // we should only need _LIQUIDITY_AMOUNT/2 of ETH
        (uint256 amountToken, uint256 amountETH, ) = router.addLiquidityETH{value: excessETH}(
            _tokenA,
            _LIQUIDITY_AMOUNT,
            _MIN_AMOUNT,
            _MIN_AMOUNT,
            USER1,
            _deadline
        );
        
        // Verify some ETH was refunded
        uint256 finalETHBalance = USER1.balance;
        uint256 ethUsed = initialETHBalance - finalETHBalance;
        
        // The ETH used should be equal to amountETH (the amount actually added to the pool)
        assertEq(ethUsed, amountETH, "Only the necessary ETH should be spent");
        
        // The ETH used should be less than the excess ETH we sent
        assertTrue(ethUsed < excessETH, "Some ETH should be refunded");
        
        // The ETH used should be approximately _LIQUIDITY_AMOUNT/2 (to maintain the 2:1 ratio)
        // The actual amount might be slightly different due to rounding
        assertTrue(amountETH < _LIQUIDITY_AMOUNT, "ETH amount should be less than token amount");
        
        // Verify other amounts are correct
        assertEq(amountToken, _LIQUIDITY_AMOUNT, "Token amount should remain as desired");
        
        vm.stopPrank();
    }
    
    // ============ Remove Liquidity Tests ============
    
    // Test removing liquidity from a token pair
    function testRemoveLiquidity() public {
        // First add liquidity
        vm.startPrank(USER1);
        tokenA.approve(address(router), _LIQUIDITY_AMOUNT);
        tokenB.approve(address(router), _LIQUIDITY_AMOUNT);
        
        (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity(
            _tokenA,
            _tokenB,
            _LIQUIDITY_AMOUNT,
            _LIQUIDITY_AMOUNT,
            _MIN_AMOUNT,
            _MIN_AMOUNT,
            USER1,
            _deadline
        );
        
        address pairAddress = factory.getPair(_tokenA, _tokenB);
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        
        // Save initial token balances
        uint256 initialBalanceA = tokenA.balanceOf(USER1);
        uint256 initialBalanceB = tokenB.balanceOf(USER1);
        
        // Approve router to spend LP tokens
        pair.approve(address(router), liquidity);
        
        // Remove liquidity (all of it)
        (uint256 returnedAmountA, uint256 returnedAmountB) = router.removeLiquidity(
            _tokenA,
            _tokenB,
            liquidity,
            _MIN_AMOUNT,
            _MIN_AMOUNT,
            USER1,
            _deadline
        );
        
        // Verify returned amounts match deposited amounts (considering MINIMUM_LIQUIDITY is locked)
        assertApproxEqRel(returnedAmountA, amountA, 0.001e18, "Returned amountA should be close to initial deposit");
        assertApproxEqRel(returnedAmountB, amountB, 0.001e18, "Returned amountB should be close to initial deposit");
        
        // Verify LP tokens were burned
        assertEq(pair.balanceOf(USER1), 0, "LP tokens should be burned");
        
        // Verify tokens were transferred back to user
        assertEq(tokenA.balanceOf(USER1) - initialBalanceA, returnedAmountA, "User should receive tokenA");
        assertEq(tokenB.balanceOf(USER1) - initialBalanceB, returnedAmountB, "User should receive tokenB");
        
        // Verify reserves were updated - only MINIMUM_LIQUIDITY should remain
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        uint256 minLiquidity = pair.MINIMUM_LIQUIDITY();
        
        // The remaining reserves should be proportional to the minimum liquidity
        // compared to the original liquidity
        uint256 expectedReserve = (minLiquidity * _LIQUIDITY_AMOUNT) / (liquidity + minLiquidity);
        
        // Check that reserves are close to the expected minimum values
        assertTrue(uint256(reserve0) <= expectedReserve + 10, "Reserve0 should be minimal (only MINIMUM_LIQUIDITY)");
        assertTrue(uint256(reserve1) <= expectedReserve + 10, "Reserve1 should be minimal (only MINIMUM_LIQUIDITY)");
        
        vm.stopPrank();
    }
    
    // Test removing ETH liquidity
    function testRemoveLiquidityETH() public {
        // First add ETH liquidity
        vm.startPrank(USER1);
        vm.deal(USER1, _ETH_AMOUNT);
        tokenA.approve(address(router), _LIQUIDITY_AMOUNT);
        
        (uint256 amountToken, uint256 amountETH, uint256 liquidity) = router.addLiquidityETH{value: _ETH_AMOUNT}(
            _tokenA,
            _LIQUIDITY_AMOUNT,
            _MIN_AMOUNT,
            _MIN_AMOUNT,
            USER1,
            _deadline
        );
        
        address pairAddress = factory.getPair(_tokenA, _wethAddress);
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        
        // Save initial balances
        uint256 initialTokenBalance = tokenA.balanceOf(USER1);
        uint256 initialETHBalance = USER1.balance;
        
        // Approve router to spend LP tokens
        pair.approve(address(router), liquidity);
        
        // Remove liquidity
        (uint256 returnedTokenAmount, uint256 returnedETHAmount) = router.removeLiquidityETH(
            _tokenA,
            liquidity,
            _MIN_AMOUNT,
            _MIN_AMOUNT,
            USER1,
            _deadline
        );
        
        // Verify returned amounts are close to initial amounts (some MINIMUM_LIQUIDITY is kept in the pool)
        assertApproxEqRel(returnedTokenAmount, amountToken, 0.001e18, "Returned token amount should be close to initial deposit");
        assertApproxEqRel(returnedETHAmount, amountETH, 0.001e18, "Returned ETH amount should be close to initial deposit");
        
        // Verify LP tokens were burned
        assertEq(pair.balanceOf(USER1), 0, "LP tokens should be burned");
        
        // Verify tokens and ETH were returned to user
        assertEq(tokenA.balanceOf(USER1) - initialTokenBalance, returnedTokenAmount, "User should receive tokens");
        assertEq(USER1.balance - initialETHBalance, returnedETHAmount, "User should receive ETH");
        
        vm.stopPrank();
    }
    
    // 辅助函数，创建移除流动性所需的签名
    function _createPermitSignature(
        UniswapV2Pair pair,
        address owner,
        address spender,
        uint256 value
    ) internal returns (uint8 v, bytes32 r, bytes32 s) {
        uint256 nonce = pair.nonces(owner);
        uint256 permitDeadline = _deadline;
        
        bytes32 domainSeparator = pair.DOMAIN_SEPARATOR();
        bytes32 permitTypehash = pair.PERMIT_TYPEHASH();
        
        bytes32 structHash = keccak256(abi.encode(permitTypehash, owner, spender, value, nonce, permitDeadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        
        // 使用私钥签名
        uint256 privateKey = 1; // 测试私钥
        (v, r, s) = vm.sign(privateKey, digest);
        
        return (v, r, s);
    }
    
    // Test removing ETH liquidity with permit
    function testRemoveLiquidityETHWithPermit() public {
        // First add ETH liquidity
        vm.startPrank(USER1);
        vm.deal(USER1, _ETH_AMOUNT);
        tokenA.approve(address(router), _LIQUIDITY_AMOUNT);
        
        (uint256 amountToken, uint256 amountETH, uint256 liquidity) = router.addLiquidityETH{value: _ETH_AMOUNT}(
            _tokenA,
            _LIQUIDITY_AMOUNT,
            _MIN_AMOUNT,
            _MIN_AMOUNT,
            USER1,
            _deadline
        );
        
        address pairAddress = factory.getPair(_tokenA, _wethAddress);
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        
        // Create signature parameters for permit
        uint256 privateKey = 1; // Private key for permit signing
        address owner = vm.addr(privateKey);
        
        // Transfer LP tokens to the owner who will use permit
        pair.transfer(owner, liquidity);
        vm.stopPrank();
        
        // Deal ETH to owner for gas
        vm.deal(owner, 1 ether);
        
        // 使用辅助函数创建签名
        (uint8 v, bytes32 r, bytes32 s) = _createPermitSignature(pair, owner, address(router), liquidity);
        
        // Save initial balances
        uint256 initialTokenBalance = tokenA.balanceOf(owner);
        uint256 initialETHBalance = owner.balance;
        
        // Call removeLiquidityETHWithPermit using owner as sender
        vm.prank(owner);
        (uint256 returnedTokenAmount, uint256 returnedETHAmount) = router.removeLiquidityETHWithPermit(
            _tokenA,
            liquidity,
            _MIN_AMOUNT,
            _MIN_AMOUNT,
            owner,
            _deadline,
            false, // Not approveMax
            v, r, s
        );
        
        // Verify returned amounts
        assertApproxEqRel(returnedTokenAmount, amountToken, 0.001e18, "Returned token amount should be close to initial deposit");
        assertApproxEqRel(returnedETHAmount, amountETH, 0.001e18, "Returned ETH amount should be close to initial deposit");
        
        // Verify LP tokens were burned
        assertEq(pair.balanceOf(owner), 0, "LP tokens should be burned");
        
        // Verify tokens and ETH were returned to owner
        assertEq(tokenA.balanceOf(owner) - initialTokenBalance, returnedTokenAmount, "Owner should receive tokens");
        assertApproxEqRel(owner.balance - initialETHBalance, returnedETHAmount, 0.001e18, "Owner should receive ETH");
    }
    
    // Test removing liquidity with permit
    function testRemoveLiquidityWithPermit() public {
        // First add liquidity
        vm.startPrank(USER1);
        tokenA.approve(address(router), _LIQUIDITY_AMOUNT);
        tokenB.approve(address(router), _LIQUIDITY_AMOUNT);
        
        (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity(
            _tokenA,
            _tokenB,
            _LIQUIDITY_AMOUNT,
            _LIQUIDITY_AMOUNT,
            _MIN_AMOUNT,
            _MIN_AMOUNT,
            USER1,
            _deadline
        );
        
        address pairAddress = factory.getPair(_tokenA, _tokenB);
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        
        // Create signature parameters for permit
        uint256 privateKey = 1; // Private key for permit signing
        address owner = vm.addr(privateKey);
        
        // Transfer LP tokens to the owner who will use permit
        pair.transfer(owner, liquidity);
        vm.stopPrank();
        
        // 使用辅助函数创建签名
        (uint8 v, bytes32 r, bytes32 s) = _createPermitSignature(pair, owner, address(router), liquidity);
        
        // Save initial token balances
        uint256 initialBalanceA = tokenA.balanceOf(owner);
        uint256 initialBalanceB = tokenB.balanceOf(owner);
        
        // Call removeLiquidityWithPermit using owner as sender
        vm.prank(owner);
        (uint256 returnedAmountA, uint256 returnedAmountB) = router.removeLiquidityWithPermit(
            _tokenA,
            _tokenB,
            liquidity,
            _MIN_AMOUNT,
            _MIN_AMOUNT,
            owner,
            _deadline,
            false, // Not approveMax, just approve the exact amount
            v, r, s
        );
        
        // Verify returned amounts
        assertApproxEqRel(returnedAmountA, amountA, 0.001e18, "Returned amountA should be close to initial deposit");
        assertApproxEqRel(returnedAmountB, amountB, 0.001e18, "Returned amountB should be close to initial deposit");
        
        // Verify LP tokens were burned
        assertEq(pair.balanceOf(owner), 0, "LP tokens should be burned");
        
        // Verify tokens were transferred back to owner
        assertEq(tokenA.balanceOf(owner) - initialBalanceA, returnedAmountA, "Owner should receive tokenA");
        assertEq(tokenB.balanceOf(owner) - initialBalanceB, returnedAmountB, "Owner should receive tokenB");
    }
    
    // ============ Swap Tests ============
    
    // Helper function to set up a pair with liquidity for swap tests
    function _setupPairForSwaps() internal returns (address) {
        vm.startPrank(USER1);
        tokenA.approve(address(router), _LIQUIDITY_AMOUNT);
        tokenB.approve(address(router), _LIQUIDITY_AMOUNT);
        
        router.addLiquidity(
            _tokenA,
            _tokenB,
            _LIQUIDITY_AMOUNT,
            _LIQUIDITY_AMOUNT,
            0,
            0,
            USER1,
            _deadline
        );
        
        vm.stopPrank();
        
        return factory.getPair(_tokenA, _tokenB);
    }
    
    // Helper function to set up token-ETH pair with liquidity
    function _setupETHPairForSwaps() internal returns (address) {
        vm.startPrank(USER1);
        vm.deal(USER1, _ETH_AMOUNT);
        tokenA.approve(address(router), _LIQUIDITY_AMOUNT);
        
        router.addLiquidityETH{value: _ETH_AMOUNT}(
            _tokenA,
            _LIQUIDITY_AMOUNT,
            0,
            0,
            USER1,
            _deadline
        );
        
        vm.stopPrank();
        
        return factory.getPair(_tokenA, _wethAddress);
    }
    
    // Test swapExactTokensForTokens
    function testSwapExactTokensForTokens() public {
        // Setup pair with liquidity
        _setupPairForSwaps();
        
        // Prepare for swap
        vm.startPrank(USER2);
        tokenA.approve(address(router), _SWAP_AMOUNT);
        
        // Save initial balances
        uint256 initialBalanceA = tokenA.balanceOf(USER2);
        uint256 initialBalanceB = tokenB.balanceOf(USER2);
        
        // Calculate expected output based on formula with 0.3% fee
        uint256 amountInWithFee = _SWAP_AMOUNT * 997;
        uint256 numerator = amountInWithFee * _LIQUIDITY_AMOUNT;
        uint256 denominator = _LIQUIDITY_AMOUNT * 1000 + amountInWithFee;
        uint256 expectedAmountOut = numerator / denominator;
        
        // Create path for swap
        address[] memory path = new address[](2);
        path[0] = _tokenA;
        path[1] = _tokenB;
        
        // Execute swap
        uint256[] memory amounts = router.swapExactTokensForTokens(
            _SWAP_AMOUNT,
            1, // Min amount out (minimal slippage protection for test)
            path,
            USER2,
            _deadline
        );
        
        // Verify amounts
        assertEq(amounts.length, 2, "Amounts array should have 2 elements");
        assertEq(amounts[0], _SWAP_AMOUNT, "Input amount should match");
        assertApproxEqRel(amounts[1], expectedAmountOut, 0.001e18, "Output amount should match expected calculation");
        
        // Verify token balances changed correctly
        assertEq(initialBalanceA - tokenA.balanceOf(USER2), _SWAP_AMOUNT, "TokenA balance should decrease by exact input");
        assertEq(tokenB.balanceOf(USER2) - initialBalanceB, amounts[1], "TokenB balance should increase by output amount");
        
        vm.stopPrank();
    }
    
    // Test swapTokensForExactTokens
    function testSwapTokensForExactTokens() public {
        // Setup pair with liquidity
        _setupPairForSwaps();
        
        // Prepare for swap
        vm.startPrank(USER2);
        
        // The exact output amount we want
        uint256 exactOutputAmount = 0.5 ether;
        
        // Need to approve more than needed to account for price calculation
        uint256 maxInputAmount = 2 ether;
        tokenA.approve(address(router), maxInputAmount);
        
        // Save initial balances
        uint256 initialBalanceA = tokenA.balanceOf(USER2);
        uint256 initialBalanceB = tokenB.balanceOf(USER2);
        
        // Create path for swap
        address[] memory path = new address[](2);
        path[0] = _tokenA;
        path[1] = _tokenB;
        
        // Execute swap
        uint256[] memory amounts = router.swapTokensForExactTokens(
            exactOutputAmount,
            maxInputAmount,
            path,
            USER2,
            _deadline
        );
        
        // Verify amounts
        assertEq(amounts.length, 2, "Amounts array should have 2 elements");
        assertTrue(amounts[0] <= maxInputAmount, "Input amount should not exceed maximum");
        assertEq(amounts[1], exactOutputAmount, "Output amount should match exact requested amount");
        
        // Verify token balances changed correctly
        assertEq(initialBalanceA - tokenA.balanceOf(USER2), amounts[0], "TokenA balance should decrease by input amount");
        assertEq(tokenB.balanceOf(USER2) - initialBalanceB, exactOutputAmount, "TokenB balance should increase by exact output amount");
        
        vm.stopPrank();
    }
    
    // Test swapExactETHForTokens
    function testSwapExactETHForTokens() public {
        // Setup ETH-token pair with liquidity
        _setupETHPairForSwaps();
        
        // Prepare for swap
        vm.startPrank(USER2);
        vm.deal(USER2, _SWAP_AMOUNT);
        
        // Save initial balances
        uint256 initialETHBalance = USER2.balance;
        uint256 initialTokenBalance = tokenA.balanceOf(USER2);
        
        // Create path for swap
        address[] memory path = new address[](2);
        path[0] = _wethAddress;
        path[1] = _tokenA;
        
        // Execute swap
        uint256[] memory amounts = router.swapExactETHForTokens{value: _SWAP_AMOUNT}(
            1, // Min amount out
            path,
            USER2,
            _deadline
        );
        
        // Verify amounts
        assertEq(amounts.length, 2, "Amounts array should have 2 elements");
        assertEq(amounts[0], _SWAP_AMOUNT, "Input ETH amount should match");
        assertTrue(amounts[1] > 0, "Should receive some tokens");
        
        // Verify balances changed correctly
        assertEq(initialETHBalance - USER2.balance, _SWAP_AMOUNT, "ETH balance should decrease by exact input");
        assertEq(tokenA.balanceOf(USER2) - initialTokenBalance, amounts[1], "Token balance should increase by output amount");
        
        vm.stopPrank();
    }
    
    // Test swapTokensForExactETH
    function testSwapTokensForExactETH() public {
        // Setup ETH-token pair with liquidity
        _setupETHPairForSwaps();
        
        // Prepare for swap
        vm.startPrank(USER2);
        
        // The exact ETH output amount we want
        uint256 exactETHOutput = 0.5 ether;
        
        // Need to approve more than needed to account for price calculation
        uint256 maxTokenInput = 2 ether;
        tokenA.approve(address(router), maxTokenInput);
        
        // Save initial balances
        uint256 initialTokenBalance = tokenA.balanceOf(USER2);
        uint256 initialETHBalance = USER2.balance;
        
        // Create path for swap
        address[] memory path = new address[](2);
        path[0] = _tokenA;
        path[1] = _wethAddress;
        
        // Execute swap
        uint256[] memory amounts = router.swapTokensForExactETH(
            exactETHOutput,
            maxTokenInput,
            path,
            USER2,
            _deadline
        );
        
        // Verify amounts
        assertEq(amounts.length, 2, "Amounts array should have 2 elements");
        assertTrue(amounts[0] <= maxTokenInput, "Input token amount should not exceed maximum");
        assertEq(amounts[1], exactETHOutput, "Output ETH amount should match exact requested amount");
        
        // Verify balances changed correctly
        assertEq(initialTokenBalance - tokenA.balanceOf(USER2), amounts[0], "Token balance should decrease by input amount");
        assertEq(USER2.balance - initialETHBalance, exactETHOutput, "ETH balance should increase by exact output amount");
        
        vm.stopPrank();
    }
    
    // Test swapExactTokensForETH
    function testSwapExactTokensForETH() public {
        // Setup ETH-token pair with liquidity
        _setupETHPairForSwaps();
        
        // Prepare for swap
        vm.startPrank(USER2);
        tokenA.approve(address(router), _SWAP_AMOUNT);
        
        // Save initial balances
        uint256 initialTokenBalance = tokenA.balanceOf(USER2);
        uint256 initialETHBalance = USER2.balance;
        
        // Create path for swap
        address[] memory path = new address[](2);
        path[0] = _tokenA;
        path[1] = _wethAddress;
        
        // Execute swap
        uint256[] memory amounts = router.swapExactTokensForETH(
            _SWAP_AMOUNT,
            1, // Min ETH out
            path,
            USER2,
            _deadline
        );
        
        // Verify amounts
        assertEq(amounts.length, 2, "Amounts array should have 2 elements");
        assertEq(amounts[0], _SWAP_AMOUNT, "Input token amount should match");
        assertTrue(amounts[1] > 0, "Should receive some ETH");
        
        // Verify balances changed correctly
        assertEq(initialTokenBalance - tokenA.balanceOf(USER2), _SWAP_AMOUNT, "Token balance should decrease by exact input");
        assertEq(USER2.balance - initialETHBalance, amounts[1], "ETH balance should increase by output amount");
        
        vm.stopPrank();
    }
    
    // Test swapETHForExactTokens
    function testSwapETHForExactTokens() public {
        // Setup ETH-token pair with liquidity
        _setupETHPairForSwaps();
        
        // Prepare for swap
        vm.startPrank(USER2);
        
        // The exact token output amount we want
        uint256 exactTokenOutput = 0.5 ether;
        
        // Send more ETH than needed to test refund
        uint256 maxETHInput = 2 ether;
        vm.deal(USER2, maxETHInput);
        
        // Save initial balances
        uint256 initialETHBalance = USER2.balance;
        uint256 initialTokenBalance = tokenA.balanceOf(USER2);
        
        // Create path for swap
        address[] memory path = new address[](2);
        path[0] = _wethAddress;
        path[1] = _tokenA;
        
        // Execute swap
        uint256[] memory amounts = router.swapETHForExactTokens{value: maxETHInput}(
            exactTokenOutput,
            path,
            USER2,
            _deadline
        );
        
        // Verify amounts
        assertEq(amounts.length, 2, "Amounts array should have 2 elements");
        assertTrue(amounts[0] <= maxETHInput, "Input ETH amount should not exceed maximum");
        assertEq(amounts[1], exactTokenOutput, "Output token amount should match exact requested amount");
        
        // Verify balances changed correctly
        assertEq(initialETHBalance - USER2.balance, amounts[0], "ETH balance should decrease by calculated amount (with excess refunded)");
        assertEq(tokenA.balanceOf(USER2) - initialTokenBalance, exactTokenOutput, "Token balance should increase by exact output amount");
        
        vm.stopPrank();
    }
    
    // Test multi-hop swapping (token A -> token B -> token C)
    function testMultiHopSwap() public {
        // First set up two pairs: A-B and B-C
        vm.startPrank(USER1);
        
        // Setup A-B pair
        tokenA.approve(address(router), _LIQUIDITY_AMOUNT);
        tokenB.approve(address(router), _LIQUIDITY_AMOUNT);
        router.addLiquidity(
            _tokenA,
            _tokenB,
            _LIQUIDITY_AMOUNT,
            _LIQUIDITY_AMOUNT,
            0,
            0,
            USER1,
            _deadline
        );
        
        // Setup B-C pair
        tokenB.approve(address(router), _LIQUIDITY_AMOUNT);
        tokenC.approve(address(router), _LIQUIDITY_AMOUNT);
        router.addLiquidity(
            _tokenB,
            _tokenC,
            _LIQUIDITY_AMOUNT,
            _LIQUIDITY_AMOUNT,
            0,
            0,
            USER1,
            _deadline
        );
        vm.stopPrank();
        
        // Now perform a multi-hop swap from A to C through B
        vm.startPrank(USER2);
        tokenA.approve(address(router), _SWAP_AMOUNT);
        
        // Save initial balances
        uint256 initialBalanceA = tokenA.balanceOf(USER2);
        uint256 initialBalanceC = tokenC.balanceOf(USER2);
        
        // Create path for multi-hop swap
        address[] memory path = new address[](3);
        path[0] = _tokenA;
        path[1] = _tokenB;
        path[2] = _tokenC;
        
        // Execute swap
        uint256[] memory amounts = router.swapExactTokensForTokens(
            _SWAP_AMOUNT,
            1, // Min amount out
            path,
            USER2,
            _deadline
        );
        
        // Verify amounts
        assertEq(amounts.length, 3, "Amounts array should have 3 elements for multi-hop");
        assertEq(amounts[0], _SWAP_AMOUNT, "Input amount should match");
        assertTrue(amounts[2] > 0, "Should receive some token C");
        
        // Verify token balances changed correctly
        assertEq(initialBalanceA - tokenA.balanceOf(USER2), _SWAP_AMOUNT, "TokenA balance should decrease by exact input");
        assertEq(tokenC.balanceOf(USER2) - initialBalanceC, amounts[2], "TokenC balance should increase by output amount");
        
        vm.stopPrank();
    }
    
    // Create a mock token that takes a fee on transfer
    function _createFeeToken() internal returns (MockTokenWithFee) {
        MockTokenWithFee feeToken = new MockTokenWithFee("Fee Token", "FEE", 1e6 ether);
        feeToken.transfer(USER1, 100 ether);
        feeToken.transfer(USER2, 100 ether);
        return feeToken;
    }
    
    // Test swapExactTokensForTokensSupportingFeeOnTransferTokens
    function testSwapWithFeeOnTransfer() public {
        // Create fee token and set up pair
        MockTokenWithFee feeToken = _createFeeToken();
        address feeTokenAddress = address(feeToken);
        
        // Setup pair with fee token
        vm.startPrank(USER1);
        feeToken.approve(address(router), _LIQUIDITY_AMOUNT);
        tokenB.approve(address(router), _LIQUIDITY_AMOUNT);
        
        router.addLiquidity(
            feeTokenAddress,
            _tokenB,
            _LIQUIDITY_AMOUNT,
            _LIQUIDITY_AMOUNT,
            0,
            0,
            USER1,
            _deadline
        );
        vm.stopPrank();
        
        // Prepare for swap with fee token
        vm.startPrank(USER2);
        feeToken.approve(address(router), _SWAP_AMOUNT);
        
        // Save initial balances
        uint256 initialFeeTokenBalance = feeToken.balanceOf(USER2);
        uint256 initialTokenBBalance = tokenB.balanceOf(USER2);
        
        // Create path for swap
        address[] memory path = new address[](2);
        path[0] = feeTokenAddress;
        path[1] = _tokenB;
        
        // Execute swap with fee on transfer support
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _SWAP_AMOUNT,
            1, // Min amount out
            path,
            USER2,
            _deadline
        );
        
        // Verify token balances changed correctly
        // Note: We can't use amounts array since this function doesn't return amounts
        assertEq(initialFeeTokenBalance - feeToken.balanceOf(USER2), _SWAP_AMOUNT, "Fee token balance should decrease by exact input");
        assertTrue(tokenB.balanceOf(USER2) > initialTokenBBalance, "TokenB balance should increase");
        
        vm.stopPrank();
    }
    
    // Test swapExactETHForTokensSupportingFeeOnTransferTokens
    function testSwapETHForTokensWithFee() public {
        // Create fee token and set up pair with WETH
        MockTokenWithFee feeToken = _createFeeToken();
        address feeTokenAddress = address(feeToken);
        
        // Setup pair with fee token and WETH
        vm.startPrank(USER1);
        vm.deal(USER1, _ETH_AMOUNT);
        feeToken.approve(address(router), _LIQUIDITY_AMOUNT);
        
        router.addLiquidityETH{value: _ETH_AMOUNT}(
            feeTokenAddress,
            _LIQUIDITY_AMOUNT,
            0,
            0,
            USER1,
            _deadline
        );
        vm.stopPrank();
        
        // Prepare for swap
        vm.startPrank(USER2);
        vm.deal(USER2, _SWAP_AMOUNT);
        
        // Save initial balances
        uint256 initialETHBalance = USER2.balance;
        uint256 initialFeeTokenBalance = feeToken.balanceOf(USER2);
        
        // Create path for swap
        address[] memory path = new address[](2);
        path[0] = _wethAddress;
        path[1] = feeTokenAddress;
        
        // Execute swap with fee on transfer support
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _SWAP_AMOUNT}(
            1, // Min amount out
            path,
            USER2,
            _deadline
        );
        
        // Verify balances changed correctly
        assertEq(initialETHBalance - USER2.balance, _SWAP_AMOUNT, "ETH balance should decrease by exact input");
        assertTrue(feeToken.balanceOf(USER2) > initialFeeTokenBalance, "Fee token balance should increase");
        
        vm.stopPrank();
    }
    
    // Test swapExactTokensForETHSupportingFeeOnTransferTokens
    function testSwapTokensForETHWithFee() public {
        // Create fee token and set up pair with WETH
        MockTokenWithFee feeToken = _createFeeToken();
        address feeTokenAddress = address(feeToken);
        
        // Setup pair with fee token and WETH
        vm.startPrank(USER1);
        vm.deal(USER1, _ETH_AMOUNT);
        feeToken.approve(address(router), _LIQUIDITY_AMOUNT);
        
        router.addLiquidityETH{value: _ETH_AMOUNT}(
            feeTokenAddress,
            _LIQUIDITY_AMOUNT,
            0,
            0,
            USER1,
            _deadline
        );
        vm.stopPrank();
        
        // Prepare for swap
        vm.startPrank(USER2);
        feeToken.approve(address(router), _SWAP_AMOUNT);
        
        // Save initial balances
        uint256 initialFeeTokenBalance = feeToken.balanceOf(USER2);
        uint256 initialETHBalance = USER2.balance;
        
        // Create path for swap
        address[] memory path = new address[](2);
        path[0] = feeTokenAddress;
        path[1] = _wethAddress;
        
        // Execute swap with fee on transfer support
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _SWAP_AMOUNT,
            1, // Min ETH out
            path,
            USER2,
            _deadline
        );
        
        // Verify balances changed correctly
        assertEq(initialFeeTokenBalance - feeToken.balanceOf(USER2), _SWAP_AMOUNT, "Fee token balance should decrease by exact input");
        assertTrue(USER2.balance > initialETHBalance, "ETH balance should increase");
        
        vm.stopPrank();
    }
}

// Mock token that takes a fee on transfer
contract MockTokenWithFee is IERC20 {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint public totalSupply;
    
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    
    uint256 public constant FEE_NUMERATOR = 5; // 0.5% fee
    uint256 public constant FEE_DENOMINATOR = 1000;
    
    constructor(string memory name_, string memory symbol_, uint256 initialSupply) {
        name = name_;
        symbol = symbol_;
        
        // 初始化总供应量和发行者余额
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }
    
    // 实现 IERC20 接口的 transfer 方法，带有费用扣除
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(balanceOf[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        
        uint256 fee = (amount * FEE_NUMERATOR) / FEE_DENOMINATOR;
        uint256 amountAfterFee = amount - fee;
        
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amountAfterFee;
        balanceOf[address(this)] += fee; // Fee goes to the token contract itself
        
        emit Transfer(msg.sender, recipient, amountAfterFee);
        emit Transfer(msg.sender, address(this), fee);
        return true;
    }
    
    // 实现 IERC20 接口的 transferFrom 方法，带有费用扣除
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(balanceOf[sender] >= amount, "ERC20: transfer amount exceeds balance");
        require(allowance[sender][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");
        
        if (allowance[sender][msg.sender] != type(uint256).max) {
            allowance[sender][msg.sender] -= amount;
        }
        
        uint256 fee = (amount * FEE_NUMERATOR) / FEE_DENOMINATOR;
        uint256 amountAfterFee = amount - fee;
        
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amountAfterFee;
        balanceOf[address(this)] += fee; // Fee goes to the token contract itself
        
        emit Transfer(sender, recipient, amountAfterFee);
        emit Transfer(sender, address(this), fee);
        return true;
    }
    
    // 实现 IERC20 接口的 approve 方法
    function approve(address spender, uint value) external override returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    // 添加一个 mint 函数以便测试
    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
} 