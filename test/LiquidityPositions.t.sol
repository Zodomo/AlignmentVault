// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import "./AlignmentVault.t.sol";

contract LiquidityPositionsTest is AlignmentVaultTest {
    using TickMath for int24;
    using TickMath for uint160;

    function setUp() public override {
        super.setUp();
        transferMilady(address(this), 69);
        transferMilady(address(av), 333);
        transferMilady(address(av), 420);
    }

    int24 constant _MIN_TICK = -887_272;
    int24 constant _MAX_TICK = -_MIN_TICK;

    uint256 constant Q128 = 0x100000000000000000000000000000000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //               LIQUIDITY POSITION MANAGEMENT
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function testLiquidityPositionCreate_Tokens() public prank(deployer) {
        (int24 tickUpper, int24 tickLower) = _getUpperLowerTicks();

        uint256 vTokenAmount = 2 ether;
        uint256 ethAmount = 3 ether;

        deal(vault, address(av), vTokenAmount);

        uint128 expectedLiquidity = _getLiquidityForAmounts(ethAmount, vTokenAmount, tickLower, tickUpper);

        vm.recordLogs();

        uint256 id = av.liquidityPositionCreate({
            ethAmount: ethAmount,
            vTokenAmount: vTokenAmount,
            tokenIds: none,
            amounts: none,
            tickLower: tickLower,
            tickUpper: tickUpper,
            sqrtPriceX96: 0,
            ethMin: 0,
            vTokenMin: 0
        });

        Vm.Log[] memory events = vm.getRecordedLogs();

        bytes32 eventSig = events[events.length - 1].topics[0];
        bytes32 idTopic = events[events.length - 1].topics[1];
        address emitter = events[events.length - 1].emitter;

        assertEq(emitter, address(av), "unexpected log: emitter");
        assertEq(eventSig, keccak256("AV_LiquidityPositionCreated(uint256)"), "unexpected log: signature");
        assertEq(idTopic, bytes32(id), "unexpected log: id");

        uint128 liquidity = _getLiquidity(id);

        assertEq(IERC721(positionManager).ownerOf(id), address(av), "position owner is not av");

        assertEq(liquidity, expectedLiquidity, "unexpected liquidity minted");
    }

    function testLiquidityPositionCreate_NFTs() public prank(deployer) {
        (int24 tickUpper, int24 tickLower) = _getUpperLowerTicks();

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 333;
        tokenIds[1] = 420;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        uint256 ethAmount = 3 ether;

        uint128 expectedLiquidity = _getLiquidityForAmounts(ethAmount, tokenIds.length * 1 ether, tickLower, tickUpper);

        vm.recordLogs();

        uint256 id = av.liquidityPositionCreate({
            ethAmount: ethAmount,
            vTokenAmount: 0,
            tokenIds: tokenIds,
            amounts: amounts,
            tickLower: tickLower,
            tickUpper: tickUpper,
            sqrtPriceX96: 0,
            ethMin: 0,
            vTokenMin: 0
        });

        Vm.Log[] memory events = vm.getRecordedLogs();

        bytes32 eventSig = events[events.length - 1].topics[0];
        bytes32 idTopic = events[events.length - 1].topics[1];
        address emitter = events[events.length - 1].emitter;

        assertEq(emitter, address(av), "unexpected log: emitter");
        assertEq(eventSig, keccak256("AV_LiquidityPositionCreated(uint256)"), "unexpected log: signature");
        assertEq(idTopic, bytes32(id), "unexpected log: id");

        uint128 liquidity = _getLiquidity(id);

        assertEq(IERC721(positionManager).ownerOf(id), address(av), "position owner is not av");

        assertEq(liquidity, expectedLiquidity, "unexpected liquidity minted");
    }

    function testLiquidityPositionCreate_FullRange() public prank(deployer) {
        uint256 vTokenAmount = 2 ether;
        uint256 ethAmount = 3 ether;

        deal(vault, address(av), vTokenAmount);

        // actual ticks will be min and max tick conformed to tick spacing
        int24 tickLowerExpected = _conformTickSpacing(_MIN_TICK);
        int24 tickUpperExpected = _conformTickSpacing(_MAX_TICK);

        uint128 expectedLiquidity =
            _getLiquidityForAmounts(ethAmount, vTokenAmount, tickLowerExpected, tickUpperExpected);

        vm.recordLogs();

        uint256 id = av.liquidityPositionCreate({
            ethAmount: ethAmount,
            vTokenAmount: vTokenAmount,
            tokenIds: none,
            amounts: none,
            tickLower: type(int24).min, // going out of tick bounds to test tick formatter
            tickUpper: type(int24).max,
            sqrtPriceX96: 0,
            ethMin: 0,
            vTokenMin: 0
        });

        Vm.Log[] memory events = vm.getRecordedLogs();

        bytes32 eventSig = events[events.length - 1].topics[0];
        bytes32 idTopic = events[events.length - 1].topics[1];
        address emitter = events[events.length - 1].emitter;

        assertEq(emitter, address(av), "unexpected log: emitter");
        assertEq(eventSig, keccak256("AV_LiquidityPositionCreated(uint256)"), "unexpected log: signature");
        assertEq(idTopic, bytes32(id), "unexpected log: id");

        uint128 liquidity = _getLiquidity(id);
        (int24 tickLower, int24 tickUpper) = _getPositionTicks(id);

        assertEq(IERC721(positionManager).ownerOf(id), address(av), "position owner is not av");

        assertEq(liquidity, expectedLiquidity, "unexpected liquidity minted");

        assertEq(tickLower, tickLowerExpected, "unexpected tick lower");
        assertEq(tickUpper, tickUpperExpected, "unexpected tick upper");
    }

    function testLiquidityPositionIncrease_Tokens() public prank(deployer) {
        (int24 tickUpper, int24 tickLower) = _getUpperLowerTicks();

        uint256 vTokenAmount = 2 ether;
        uint256 ethAmount = 3 ether;

        deal(vault, address(av), vTokenAmount);

        // create initial position
        uint256 id = av.liquidityPositionCreate({
            ethAmount: ethAmount,
            vTokenAmount: vTokenAmount,
            tokenIds: none,
            amounts: none,
            tickLower: tickLower,
            tickUpper: tickUpper,
            sqrtPriceX96: 0,
            ethMin: 0,
            vTokenMin: 0
        });

        uint128 liquidityBefore = _getLiquidity(id);

        vTokenAmount = 1 ether;
        ethAmount = 1.5 ether;

        uint128 expectedLiquidity = _getLiquidityForAmounts(ethAmount, vTokenAmount, tickLower, tickUpper);

        vm.expectEmit(true, false, false, false, address(av));
        emit IAlignmentVault.AV_LiquidityPositionIncreased(id);

        // increase position
        av.liquidityPositionIncrease({
            positionId: id,
            ethAmount: ethAmount,
            vTokenAmount: vTokenAmount,
            tokenIds: none,
            amounts: none,
            ethMin: 0,
            vTokenMin: 0
        });

        uint128 liquidity = _getLiquidity(id) - liquidityBefore;

        assertEq(liquidity, expectedLiquidity, "unexpected liquidity added");
    }

    function testLiquidityPositionIncrease_NFTs() public prank(deployer) {
        (int24 tickUpper, int24 tickLower) = _getUpperLowerTicks();

        uint256 vTokenAmount = 2 ether;
        uint256 ethAmount = 3 ether;

        deal(vault, address(av), vTokenAmount);

        // create initial position
        uint256 id = av.liquidityPositionCreate({
            ethAmount: ethAmount,
            vTokenAmount: vTokenAmount,
            tokenIds: none,
            amounts: none,
            tickLower: tickLower,
            tickUpper: tickUpper,
            sqrtPriceX96: 0,
            ethMin: 0,
            vTokenMin: 0
        });

        uint128 liquidityBefore = _getLiquidity(id);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 333;
        tokenIds[1] = 420;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        uint128 expectedLiquidity = _getLiquidityForAmounts(ethAmount, tokenIds.length * 1 ether, tickLower, tickUpper);

        vm.expectEmit(true, false, false, false, address(av));
        emit IAlignmentVault.AV_LiquidityPositionIncreased(id);

        // increase position
        av.liquidityPositionIncrease({
            positionId: id,
            ethAmount: ethAmount,
            vTokenAmount: 0,
            tokenIds: tokenIds,
            amounts: amounts,
            ethMin: 0,
            vTokenMin: 0
        });

        uint128 liquidity = _getLiquidity(id) - liquidityBefore;

        assertEq(liquidity, expectedLiquidity, "unexpected liquidity added");
    }

    function test_LiquidityPositionWithdrawal_Tokens() public prank(deployer) {
        uint256 vTokenAmount = 2 ether;
        uint256 ethAmount = 3 ether;

        deal(vault, address(av), vTokenAmount);

        (int24 tickUpper, int24 tickLower) = _getUpperLowerTicks();

        uint256 id = av.liquidityPositionCreate({
            ethAmount: ethAmount,
            vTokenAmount: vTokenAmount,
            tokenIds: none,
            amounts: none,
            tickLower: tickLower,
            tickUpper: tickUpper,
            sqrtPriceX96: 0,
            ethMin: 0,
            vTokenMin: 0
        });

        // note: bypass timelock penalty
        vm.warp(INonfungiblePositionManager(positionManager).lockedUntil(id) + 1);

        uint128 liquidity = _getLiquidity(id);

        uint128 withdrawnLiquidity = liquidity / 3;

        (ethAmount, vTokenAmount) = _getAmountsForLiquidity(withdrawnLiquidity, tickLower, tickUpper);

        uint256 ethBalBefore = address(av).balance;
        uint256 vTokenBalBefore = IERC20(vault).balanceOf(address(av));

        vm.expectEmit(true, false, false, false, address(av));
        emit IAlignmentVault.AV_LiquidityPositionWithdrawal(id);

        av.liquidityPositionWithdrawal({
            positionId: id,
            tokenIds: none,
            vTokenPremiumLimit: 0,
            liquidity: withdrawnLiquidity,
            amount0Min: 0,
            amount1Min: 0
        });

        assertEq(_getLiquidity(id), liquidity - withdrawnLiquidity, "unexpected liquidity remaining");
        assertEq(address(av).balance - ethBalBefore, ethAmount, "unexpected eth withdrawn");
        assertEq(IERC20(vault).balanceOf(address(av)) - vTokenBalBefore, vTokenAmount, "unexpected vToken withdrawn");
    }

    function test_LiquidityPositionWithdrawal_Nfts() public prank(deployer) {
        uint256 vTokenAmount = 1.5 ether;
        uint256 ethAmount = 8 ether;

        deal(vault, address(av), vTokenAmount);

        (int24 tickUpper, int24 tickLower) = _getUpperLowerTicks();

        uint256 id = av.liquidityPositionCreate({
            ethAmount: ethAmount,
            vTokenAmount: vTokenAmount,
            tokenIds: none,
            amounts: none,
            tickLower: tickLower,
            tickUpper: tickUpper,
            sqrtPriceX96: 0,
            ethMin: 0,
            vTokenMin: 0
        });

        // note: bypass timelock penalty
        vm.warp(INonfungiblePositionManager(positionManager).lockedUntil(id) + 1);

        uint128 liquidity = _getLiquidity(id);

        (ethAmount, vTokenAmount) = _getAmountsForLiquidity(liquidity, tickLower, tickUpper);

        uint256 ethBalBefore = address(av).balance;
        uint256 vTokenBalBefore = IERC20(vault).balanceOf(address(av));

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = INFTXVaultV3(vault).allHoldings()[0];

        vm.expectEmit(true, false, false, false, address(av));
        emit IAlignmentVault.AV_LiquidityPositionWithdrawal(id);

        av.liquidityPositionWithdrawal({
            positionId: id,
            tokenIds: tokenIds,
            vTokenPremiumLimit: 0,
            liquidity: liquidity,
            amount0Min: 0,
            amount1Min: 0
        });

        assertEq(_getLiquidity(id), 0, "unexpected liquidity remaining");
        assertEq(address(av).balance - ethBalBefore, ethAmount, "unexpected eth withdrawn");
        assertEq(IERC20(vault).balanceOf(address(av)) - vTokenBalBefore, vTokenAmount - 1 ether, "unexpected vToken withdrawn");
        assertEq(IERC721(MILADY).ownerOf(tokenIds[0]), address(av));
    }

    function testLiquidityPositionCollectFees() public prank(deployer) {
        (int24 tickUpper, int24 tickLower) = _getUpperLowerTicks();

        uint256 vTokenAmount = 1 ether;
        uint256 ethAmount = 1.5 ether;

        deal(vault, address(av), vTokenAmount * 3);

        positionKey = keccak256(abi.encodePacked(positionManager, tickLower, tickUpper));

        av.liquidityPositionCreate({
            ethAmount: ethAmount,
            vTokenAmount: vTokenAmount,
            tokenIds: none,
            amounts: none,
            tickLower: tickLower,
            tickUpper: tickUpper,
            sqrtPriceX96: 0,
            ethMin: 0,
            vTokenMin: 0
        });

        uint256 id1 = av.liquidityPositionCreate({
            ethAmount: ethAmount,
            vTokenAmount: vTokenAmount,
            tokenIds: none,
            amounts: none,
            tickLower: type(int24).min,
            tickUpper: type(int24).max,
            sqrtPriceX96: 0,
            ethMin: 0,
            vTokenMin: 0
        });

        _buyVTokenFromPool(address(uint160(uint256(keccak256("trader 1")))), 1 ether);

        (tickUpper, tickLower) = _getUpperLowerTicks();

        _changePrank(deployer);
        uint256 id2 = av.liquidityPositionCreate({
            ethAmount: ethAmount,
            vTokenAmount: vTokenAmount,
            tokenIds: none,
            amounts: none,
            tickLower: tickLower,
            tickUpper: tickUpper,
            sqrtPriceX96: 0,
            ethMin: 0,
            vTokenMin: 0
        });

        _buyVTokenFromPool(address(uint160(uint256(keccak256("trader 2")))), 1.5 ether);
        _buyWethFromPool(address(uint160(uint256(keccak256("trader 3")))), 2 ether);
        _buyVTokenFromPool(address(uint160(uint256(keccak256("trader 4")))), 0.5 ether);

        (uint128 ethFeesExpected1, uint256 vTokenFeesExpected1) = av.getSpecificLiquidityPositionFees(id1);
        (uint128 ethFeesExpected2, uint256 vTokenFeesExpected2) = av.getSpecificLiquidityPositionFees(id2);

        uint256 wethBalBefore = WETH.balanceOf(deployer);
        uint256 vTokenBalBefore = IERC20(vault).balanceOf(deployer);

        uint256[] memory ids = new uint256[](2);
        ids[0] = id1;
        ids[1] = id2;

        vm.expectEmit(true, false, false, true, positionManager);
        emit Collect(id1, deployer, ethFeesExpected1, vTokenFeesExpected1);
        emit Collect(id2, deployer, ethFeesExpected2, vTokenFeesExpected2);

        vm.expectEmit(true, false, false, false, address(av));
        emit IAlignmentVault.AV_LiquidityPositionsCollected(ids);

        _changePrank(deployer);
        av.liquidityPositionCollectFees(deployer, ids);

        assertEq(WETH.balanceOf(deployer) - wethBalBefore, ethFeesExpected1 + ethFeesExpected2, "unexpected eth fees collected");
        assertEq(IERC20(vault).balanceOf(deployer) - vTokenBalBefore, vTokenFeesExpected1 + vTokenFeesExpected2, "unexpected vToken fees collected");
    }

    function testLiquidityPositionCollectAllFees() public prank(deployer) {
        (int24 tickUpper, int24 tickLower) = _getUpperLowerTicks();

        uint256 vTokenAmount = 2 ether;
        uint256 ethAmount = 3 ether;

        deal(vault, address(av), vTokenAmount * 2);

        positionKey = keccak256(abi.encodePacked(positionManager, tickLower, tickUpper));

        uint256 id1 = av.liquidityPositionCreate({
            ethAmount: ethAmount,
            vTokenAmount: vTokenAmount,
            tokenIds: none,
            amounts: none,
            tickLower: tickLower,
            tickUpper: tickUpper,
            sqrtPriceX96: 0,
            ethMin: 0,
            vTokenMin: 0
        });

        uint256 id2 = av.liquidityPositionCreate({
            ethAmount: ethAmount,
            vTokenAmount: vTokenAmount,
            tokenIds: none,
            amounts: none,
            tickLower: type(int24).min,
            tickUpper: type(int24).max,
            sqrtPriceX96: 0,
            ethMin: 0,
            vTokenMin: 0
        });

        _buyVTokenFromPool(address(uint160(uint256(keccak256("trader 1")))), 1 ether);
        _buyVTokenFromPool(address(uint160(uint256(keccak256("trader 2")))), 1.5 ether);
        _buyWethFromPool(address(uint160(uint256(keccak256("trader 3")))), 2 ether);
        _buyVTokenFromPool(address(uint160(uint256(keccak256("trader 4")))), 0.5 ether);

        (uint128 ethFeesExpected1, uint256 vTokenFeesExpected1) = av.getSpecificLiquidityPositionFees(id1);
        (uint128 ethFeesExpected2, uint256 vTokenFeesExpected2) = av.getSpecificLiquidityPositionFees(id2);

        uint256 wethBalBefore = WETH.balanceOf(deployer);
        uint256 vTokenBalBefore = IERC20(vault).balanceOf(deployer);

        vm.expectEmit(true, false, false, true, positionManager);
        emit Collect(id1, deployer, ethFeesExpected1, vTokenFeesExpected1);
        emit Collect(id2, deployer, ethFeesExpected2, vTokenFeesExpected2);

        vm.expectEmit(true, false, false, false, address(av));
        emit IAlignmentVault.AV_LiquidityPositionsCollected(av.getLiquidityPositionIds());

        _changePrank(deployer);
        av.liquidityPositionCollectAllFees(deployer);

        assertEq(WETH.balanceOf(deployer) - wethBalBefore, ethFeesExpected1 + ethFeesExpected2, "unexpected eth fees collected");
        assertEq(IERC20(vault).balanceOf(deployer) - vTokenBalBefore, vTokenFeesExpected1 + vTokenFeesExpected2, "unexpected vToken fees collected");
    }

    function testOnERC721Received_LiquidityPosition() public prank(deployer) {
        AlignmentVault donator = AlignmentVault(payable(avf.deploy(deployer, MILADY, VAULT_ID))); // simpler to make another AV

        uint256 ethAmount = 3 ether;
        uint256 vTokenAmount = 2 ether;

        vm.deal(address(donator), ethAmount);
        deal(vault, (address(donator)), vTokenAmount);

        uint256[] memory ids = new uint256[](1);

        uint256 id = ids[0] = donator.liquidityPositionCreate({
            ethAmount: ethAmount,
            vTokenAmount: vTokenAmount,
            tokenIds: none,
            amounts: none,
            tickLower: type(int24).min,
            tickUpper: type(int24).max,
            sqrtPriceX96: 0,
            ethMin: 0,
            vTokenMin: 0
        });

        assertEq(donator.getLiquidityPositionIds(), ids, "incorrect liquidity position before: donator");
        assertEq(av.getLiquidityPositionIds(), none, "incorrect liquidity position before: av");

        vm.expectEmit(true, false, false, false, address(av));
        emit IAlignmentVault.AV_LiquidityPositionCreated(id);

        _changePrank(address(donator));
        IERC721(positionManager).safeTransferFrom(address(donator), address(av), id);

        assertEq(av.getLiquidityPositionIds(), ids, "incorrect liquidity position after: av");
    }

    function testLiquidityPositionUpdateSet() public prank(deployer) {
        AlignmentVault donator = AlignmentVault(payable(avf.deploy(deployer, MILADY, VAULT_ID))); // simpler to make another AV

        uint256 ethAmount = 3 ether;
        uint256 vTokenAmount = 2 ether;

        vm.deal(address(donator), ethAmount);
        deal(vault, (address(donator)), vTokenAmount);

        uint256[] memory ids = new uint256[](1);

        uint256 id = ids[0] = donator.liquidityPositionCreate({
            ethAmount: ethAmount,
            vTokenAmount: vTokenAmount,
            tokenIds: none,
            amounts: none,
            tickLower: type(int24).min,
            tickUpper: type(int24).max,
            sqrtPriceX96: 0,
            ethMin: 0,
            vTokenMin: 0
        });

        _changePrank(address(donator));
        IERC721(positionManager).transferFrom(address(donator), address(av), id);

        assertEq(donator.getLiquidityPositionIds(), ids, "incorrect liquidity position before: donator");
        assertEq(av.getLiquidityPositionIds(), none, "incorrect liquidity position before: av");

        vm.expectEmit(true, false, false, false, address(av));
        emit IAlignmentVault.AV_LiquidityPositionCreated(id);

        av.liquidityPositionUpdateSet(id);
        
        assertEq(av.getLiquidityPositionIds(), ids, "incorrect liquidity position after: av");
    }

}
