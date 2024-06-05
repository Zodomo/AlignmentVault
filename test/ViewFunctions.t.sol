// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import "./AlignmentVault.t.sol";

contract ViewFunctionsTest is AlignmentVaultTest {

    function setUp() public override {
        super.setUp();
        transferMilady(address(this), 69);
        transferMilady(address(av), 333);
        transferMilady(address(av), 420);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //                      VIEW FUNCTIONS
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    
    function testGetInventoryPositionIds() public prank(deployer) {
        uint256[] memory positionIds = new uint256[](2);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 333;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        positionIds[0] = av.inventoryPositionCreateNfts(tokenIds, amounts);

        tokenIds[0] = 420;

        positionIds[1] = av.inventoryPositionCreateNfts(tokenIds, amounts);

        assertEq(av.getInventoryPositionIds(), positionIds, 'unexpected inventory position ids');
    }

    function testGetSpecificInventoryPositionFees() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 333;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        uint256[] memory ids = new uint256[](1);

        uint256 id = ids[0] = av.inventoryPositionCreateNfts(tokenIds, amounts);

        tokenIds[0] = 420;

        av.inventoryPositionCreateNfts(tokenIds, amounts);

        address distributor = NFTX_VAULT_FACTORY.feeDistributor();

        deal(address(WETH), distributor, 10 ether);

        _changePrank(distributor);
        require(NFTX_INVENTORY_STAKING.receiveWethRewards(vaultId, 10 ether), 'fees not distributed');

        uint256 expectedFees = av.getSpecificInventoryPositionFees(id);

        uint256 balBefore = WETH.balanceOf(deployer);

        _changePrank(deployer);
        av.inventoryPositionCollectFees(deployer, ids);

        assertEq(WETH.balanceOf(deployer) - balBefore, expectedFees, 'unexpected fees');
    }

    function testGetTotalInventoryPositionFees() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 333;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        uint256[] memory ids = new uint256[](2);

        ids[0] = av.inventoryPositionCreateNfts(tokenIds, amounts);

        tokenIds[0] = 420;

        ids[1] = av.inventoryPositionCreateNfts(tokenIds, amounts);

        address distributor = NFTX_VAULT_FACTORY.feeDistributor();

        deal(address(WETH), distributor, 10 ether);

        _changePrank(distributor);
        require(NFTX_INVENTORY_STAKING.receiveWethRewards(vaultId, 10 ether), 'fees not distributed');

        uint256 expectedFees = av.getTotalInventoryPositionFees();

        uint256 balBefore = WETH.balanceOf(deployer);

        _changePrank(deployer);
        av.inventoryPositionCollectAllFees(deployer);

        assertEq(WETH.balanceOf(deployer) - balBefore, expectedFees, 'unexpected fees');
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //             LIQUIDITY RELATED VIEW FUNCTIONS
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function testGetLiquidityPositionIds() public prank(deployer) {
        deal(vault, address(av), 3 ether);
        deal(address(WETH), address(av), 6 ether);

        uint256[] memory ids = new uint256[](2);
        
        ids[0] = av.liquidityPositionCreate({
            ethAmount: 3 ether,
            vTokenAmount: 1.5 ether,
            tokenIds: none,
            amounts: none,
            tickLower: type(int24).min,
            tickUpper: type(int24).max,
            sqrtPriceX96: 0,
            ethMin: 0,
            vTokenMin: 0
        });

        ids[1] = av.liquidityPositionCreate({
            ethAmount: 3 ether,
            vTokenAmount: 1.5 ether,
            tokenIds: none,
            amounts: none,
            tickLower: type(int24).min,
            tickUpper: type(int24).max,
            sqrtPriceX96: 0,
            ethMin: 0,
            vTokenMin: 0
        });

        assertEq(av.getLiquidityPositionIds(), ids, "unexpected liquidity position ids");
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

    function testGetTotalLiquidityPositionFees() public prank(deployer) {
        (int24 tickUpper, int24 tickLower) = _getUpperLowerTicks();

        uint256 vTokenAmount = 2 ether;
        uint256 ethAmount = 3 ether;

        deal(vault, address(av), vTokenAmount * 2);

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

        av.liquidityPositionCreate({
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

        (uint128 ethFeesExpected, uint256 vTokenFeesExpected) = av.getTotalLiquidityPositionFees();

        uint256 wethBalBefore = WETH.balanceOf(deployer);
        uint256 vTokenBalBefore = IERC20(vault).balanceOf(deployer);

        _changePrank(deployer);
        av.liquidityPositionCollectAllFees(deployer);

        assertEq(WETH.balanceOf(deployer) - wethBalBefore, ethFeesExpected, "unexpected eth fees collected");
        assertEq(IERC20(vault).balanceOf(deployer) - vTokenBalBefore, vTokenFeesExpected, "unexpected vToken fees collected");
    }

}

   