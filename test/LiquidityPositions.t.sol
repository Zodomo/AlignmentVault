// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import "./AlignmentVault.t.sol";
import "../lib/nftx-protocol-v3/src/uniswap/v3-core/interfaces/IUniswapV3Pool.sol";

contract LiquidityPositionsTest is AlignmentVaultTest {
    function setUp() public override {
        super.setUp();
        transferMilady(address(this), 69);
        transferMilady(address(av), 333);
        transferMilady(address(av), 420);
    }

    int24 private constant _MIN_TICK = -887272;
    int24 private constant _MAX_TICK = -_MIN_TICK;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //               LIQUIDITY POSITION MANAGEMENT
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    // function testLiquidityPositionCreateTokens() public prank(deployer) {
    //     (int24 tickUpper, int24 tickLower) = _getUpperLowerTicks();

    //     av.liquidityPositionCreate({
    //         ethAmount : 1 ether,
    //         vTokenAmount : 0,
    //         tokenIds : none,
    //         amounts : none,
    //         tickLower : tickLower,
    //         tickUpper : tickUpper,
    //         sqrtPriceX96 : 0,
    //         ethMin : 0,
    //         vTokenMin : 0
    //     });
    // }

    function testLiquidityPositionCreateNfts_Concentrated() public prank(deployer) {
        (int24 tickUpper, int24 tickLower) = _getUpperLowerTicks();

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 333;
        tokenIds[1] = 420;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;
        
        av.liquidityPositionCreate({
            ethAmount :  5 ether, 
            vTokenAmount : 0,
            tokenIds : tokenIds,
            amounts : amounts,
            tickLower : tickLower,
            tickUpper : tickUpper,
            sqrtPriceX96 : 0,
            ethMin : 0,
            vTokenMin : 0
        });
    }

    function testLiquidityPositionCreateNfts_FullRange() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 333;
        tokenIds[1] = 420;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;
        
        av.liquidityPositionCreate({
            ethAmount :  5 ether, 
            vTokenAmount : 0,
            tokenIds : tokenIds,
            amounts : amounts,
            tickLower : _MIN_TICK - 100, // going out of tick bounds to test tick formatter
            tickUpper : _MAX_TICK + 100,
            sqrtPriceX96 : 0,
            ethMin : 0,
            vTokenMin : 0
        });
    }


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //                   HELPER FUNCTIONS
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function _getTick() internal view returns (int24 tick) {
        (address pool,,) = av.getUniswapPoolValues();
        (,tick,,,,,) = IUniswapV3Pool(pool).slot0();
    }

    function _getUpperLowerTicks() internal view returns (int24 tickUpper, int24 tickLower) {
        int24 tick = _getTick();
        int24 tick1 = tick + (tick / 10);
        int24 tick2 = tick - (tick / 10);

        (tickUpper, tickLower) = tick1 > tick2 ? (tick1, tick2) : (tick2, tick1);
    }
}