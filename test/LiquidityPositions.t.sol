// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import "./AlignmentVault.t.sol";
import {IUniswapV3Pool} from "../lib/nftx-protocol-v3/src/uniswap/v3-core/interfaces/IUniswapV3Pool.sol";
import {INonfungiblePositionManager} from
    "../lib/nftx-protocol-v3/src/uniswap/v3-periphery/interfaces/INonfungiblePositionManager.sol";
import {Position} from "../lib/nftx-protocol-v3/src/uniswap/v3-core/libraries/Position.sol";
import {TickMath} from "../lib/nftx-protocol-v3/src/uniswap/v3-core/libraries/TickMath.sol";
import {LiquidityAmounts} from "../lib/nftx-protocol-v3/src/uniswap/v3-periphery/libraries/LiquidityAmounts.sol";
import {FullMath} from "../lib/nftx-protocol-v3/src/uniswap/v3-core/libraries/FullMath.sol";

contract LiquidityPositionsTest is AlignmentVaultTest {
    using TickMath for int24;
    using TickMath for uint160;

    function setUp() public override {
        super.setUp();
        transferMilady(address(this), 69);
        transferMilady(address(av), 333);
        transferMilady(address(av), 420);

        positionManager = address(NFTX_POSITION_ROUTER.positionManager());

        pool = _getPool();
    }

    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    int24 constant _MIN_TICK = -887_272;
    int24 constant _MAX_TICK = -_MIN_TICK;

    uint256 constant Q128 = 0x100000000000000000000000000000000;

    bytes32 positionKey;
    address positionManager;
    IUniswapV3Pool pool;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //               LIQUIDITY POSITION MANAGEMENT
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function testLiquidityPositionCreate_Tokens() public prank(deployer) {
        (int24 tickUpper, int24 tickLower) = _getUpperLowerTicks();

        uint256 vTokenAmount = 2 ether;
        uint256 ethAmount = 3 ether;

        deal(vault, address(av), vTokenAmount);

        uint128 expectedLiquidity = _getLiquidityForAmounts(ethAmount, vTokenAmount, tickLower, tickUpper);

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

    // @todo add another position
    function testLiquidityPositionCollectAllFees() public prank(deployer) {
        (int24 tickUpper, int24 tickLower) = _getUpperLowerTicks();

        uint256 vTokenAmount = 2 ether;
        uint256 ethAmount = 3 ether;

        deal(vault, address(av), vTokenAmount);

        positionKey = keccak256(abi.encodePacked(positionManager, tickLower, tickUpper));

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

        _buyVTokenFromPool(address(uint160(uint256(keccak256("trader 1")))), 1 ether);
        _buyVTokenFromPool(address(uint160(uint256(keccak256("trader 2")))), 1.5 ether);

        (uint128 ethFeesExpected,) = av.getSpecificLiquidityPositionFees(id);

        uint256 balBefore = WETH.balanceOf(deployer);

        vm.expectEmit(true, false, false, true);
        emit Collect(id, deployer, ethFeesExpected, 0);

        _changePrank(deployer);
        av.liquidityPositionCollectAllFees(deployer);

        assertEq(WETH.balanceOf(deployer) - balBefore, ethFeesExpected, "unexpected eth fees collected");
    }

    function testGetSpecificLiquidityPositionFees() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 333;
        tokenIds[1] = 420;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        uint256 id = av.liquidityPositionCreate({
            ethAmount: 3 ether,
            vTokenAmount: 0,
            tokenIds: tokenIds,
            amounts: amounts,
            tickLower: type(int24).min,
            tickUpper: type(int24).max,
            sqrtPriceX96: 0,
            ethMin: 0,
            vTokenMin: 0
        });

        _buyVTokenFromPool(address(uint160(uint256(keccak256("trader 1")))), 1 ether);
        _buyVTokenFromPool(address(uint160(uint256(keccak256("trader 2")))), 1.5 ether);
        _buyWethFromPool(address(uint160(uint256(keccak256("trader 3")))), 2 ether);

        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
            tokenId: id,
            recipient: deployer,
            amount0Max: 100, // returns no tokens to AV (putting 0 will cause a revert so we put a very small amount)
            amount1Max: 100
        });

        uint256 balBeforeWeth = WETH.balanceOf(deployer);
        uint256 balBeforeVToken = IERC20(vault).balanceOf(deployer);

        _changePrank(address(av)); // cache position fees so far in manager
        INonfungiblePositionManager(positionManager).collect(params);

        assertEq(WETH.balanceOf(deployer) - balBeforeWeth, 100, "non-zero eth fees collected");
        assertEq(IERC20(vault).balanceOf(deployer) - balBeforeVToken, 100, "non-zero eth fees collected");

        _buyVTokenFromPool(address(uint160(uint256(keccak256("trader 4")))), 0.5 ether);
        _buyWethFromPool(address(uint160(uint256(keccak256("trader 5")))), 1 ether);

        (uint128 ethFeesExpected, uint256 vTokenFeesExpected) = av.getSpecificLiquidityPositionFees(id);

        balBeforeWeth = WETH.balanceOf(deployer);
        balBeforeVToken = IERC20(vault).balanceOf(deployer);

        vm.expectEmit(true, false, false, true);
        emit Collect(id, deployer, ethFeesExpected, vTokenFeesExpected);

        _changePrank(deployer);
        av.liquidityPositionCollectAllFees(deployer);

        assertEq(WETH.balanceOf(deployer) - balBeforeWeth, ethFeesExpected, "unexpected eth fees collected");
        assertEq(
            IERC20(vault).balanceOf(deployer) - balBeforeVToken, vTokenFeesExpected, "unexpected vToken fees collected"
        );
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //                   HELPER FUNCTIONS
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function _getPool() internal view returns (IUniswapV3Pool) {
        (address poolAddress,,) = av.getUniswapPoolValues();

        return IUniswapV3Pool(poolAddress);
    }

    function _getCurrentTick() internal view returns (int24 tick) {
        (, tick,,,,,) = IUniswapV3Pool(pool).slot0();
    }

    function _getUpperLowerTicks() internal view returns (int24 tickUpper, int24 tickLower) {
        int24 tick = _getCurrentTick();
        int24 tick1 = tick + (tick / 10);
        int24 tick2 = tick - (tick / 10);

        tick1 = _conformTickSpacing(tick1);
        tick2 = _conformTickSpacing(tick2);

        (tickUpper, tickLower) = tick1 > tick2 ? (tick1, tick2) : (tick2, tick1);
    }

    function _conformTickSpacing(int24 tick) internal view returns (int24) {
        int24 spacing = pool.tickSpacing();
        return tick % spacing == 0 ? tick : tick - (tick % spacing);
    }

    function _getLiquidity(uint256 id) internal view returns (uint128 liquidity) {
        (,,,,,,, liquidity,,,,) = INonfungiblePositionManager(positionManager).positions(id);
    }

    function _getPositionTicks(uint256 id) internal view returns (int24 tickLower, int24 tickUpper) {
        (,,,,, tickLower, tickUpper,,,,,) = INonfungiblePositionManager(positionManager).positions(id);
    }

    function _buyVTokenFromPool(address trader, uint256 amount) internal {
        deal(address(WETH), trader, amount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(WETH),
            tokenOut: vault,
            fee: STANDARD_FEE,
            recipient: trader,
            deadline: block.timestamp,
            amountIn: amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        _changePrank(trader);
        WETH.approve(address(NFTX_SWAP_ROUTER), amount);
        NFTX_SWAP_ROUTER.exactInputSingle(params);
    }

    function _buyWethFromPool(address trader, uint256 amount) internal {
        deal(vault, trader, amount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: vault,
            tokenOut: address(WETH),
            fee: STANDARD_FEE,
            recipient: trader,
            deadline: block.timestamp,
            amountIn: amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        _changePrank(trader);
        IERC20(vault).approve(address(NFTX_SWAP_ROUTER), amount);
        NFTX_SWAP_ROUTER.exactInputSingle(params);
    }

    function _getLiquidityForAmounts(
        uint256 ethAmount,
        uint256 vTokenAmount,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (uint128 liquidity) {
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);

        (uint256 amount0, uint256 amount1) =
            address(vault) < address(WETH) ? (vTokenAmount, ethAmount) : (ethAmount, vTokenAmount);

        liquidity =
            LiquidityAmounts.getLiquidityForAmounts(sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96, amount0, amount1);
    }

    /// @dev refreshes position to get updated fee growth
    function _refreshPosition(int24 tickLower, int24 tickUpper) internal {
        _changePrank(positionManager);
        pool.burn(tickLower, tickUpper, 0);
    }
}
