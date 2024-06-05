// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import "./AlignmentVault.t.sol";

import {Ownable} from "../lib/solady/src/auth/Ownable.sol";
import {MockERC1155} from "../lib/solady/test/utils/mocks/MockERC1155.sol";

contract AssertionsTest is AlignmentVaultTest {

    address notOwner = makeAddr('not owner');

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //              LIQUIDITY MANAGEMENT ASSERTIONS
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function testRevert_LiquidityPositionCreate_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.liquidityPositionCreate({
            ethAmount: 0,
            vTokenAmount: 0,
            tokenIds: none,
            amounts: none,
            tickLower: 0,
            tickUpper: 0,
            sqrtPriceX96: 0,
            ethMin: 0,
            vTokenMin: 0
        });
    }

    function testRevert_LiquidityPositionIncrease_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.liquidityPositionIncrease({
            positionId: 0,
            ethAmount: 0,
            vTokenAmount: 0,
            tokenIds: none,
            amounts: none,
            ethMin: 0,
            vTokenMin: 0
        });
    }

    function testRevert_LiquidityPositionWithdraw_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.liquidityPositionWithdrawal({
            positionId: 0,
            tokenIds: none,
            vTokenPremiumLimit: 0,
            liquidity: 0,
            amount0Min: 0,
            amount1Min: 0
        });
    }

    function testRevert_LiquidityPositionCollectFees_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.liquidityPositionCollectFees(deployer, none);
    }

    function testRevert_LiquidityPositionCollectAllFees_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.liquidityPositionCollectAllFees(deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //              INVENTORY MANAGEMENT ASSERTIONS
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function testRevert_InventoryPositionCreateNfts_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.inventoryPositionCreateNfts(none, none);
    }

    function testRevert_InventoryPositionCreateVToken_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.inventoryPositionCreateVToken(0);
    }

    function testRevert_InventoryPositionIncrease_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.inventoryPositionIncrease(0 ,0);
    }

    function testRevert_InventoryPositionWithdraw_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.inventoryPositionWithdrawal(0, 0, none, 0);
    }

    function testRevert_InventoryPositionCombine_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.inventoryPositionCombine(0, none);
    }

    function testRevert_InventoryPositionCollectFees_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.inventoryPositionCollectFees(deployer, none);
    }

    function testRevert_InventoryPositionCollectAllFees_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.inventoryPositionCollectAllFees(deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //              ALIGNED MANAGEMENT ASSERTIONS
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function testRevert_BuyNftsFromPool_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.buyNftsFromPool(0, none, 0, 0, 0);
    }

    function testRevert_MintVToken_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.mintVToken(none, none);
    }

    function testRevert_BuyVToken_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.buyVToken(0, 0, 0, 0);
    }

    function testRevert_BuyVTokenExact_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.buyVTokenExact(0, 0, 0, 0);
    }

    function testRevert_SellVToken_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.sellVToken(0, 0, 0, 0);
    }

    function testRevert_SellVTokenExact_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.sellVTokenExact(0, 0, 0, 0);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //                  MISC MANAGEMENT ASSERTIONS
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function testRevert_RescueERC20_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.rescueERC20(address(0), 0, address(0));
    }

    function testRevert_RescueERC721_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.rescueERC721(address(0), 0, address(0));
    }

    function testRevert_UnwrapEth_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.unwrapEth(0);
    }

    function testRevert_WrapEth_Ownable() public prank(notOwner) {
        vm.expectRevert(Ownable.Unauthorized.selector);
        av.wrapEth(0);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //                  RECEIVER ASSERTIONS
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function testRevert_OnERC721Received_UnalignedNft_Unaligned() public {
        IERC721 unaligned = IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
        vm.startPrank(unaligned.ownerOf(1));
        vm.expectRevert(IAlignmentVault.AV_UnalignedNft.selector);
        unaligned.safeTransferFrom(unaligned.ownerOf(1), address(av), 1);
    }

    function testRevert_OnERC721Received_UnalignedNft_UnalignedLiquidityPosition() public {
        vm.startPrank(NPM.ownerOf(10));
        vm.expectRevert(IAlignmentVault.AV_UnalignedNft.selector); 
        NPM.safeTransferFrom(NPM.ownerOf(10), address(av), 10);
    }

    function testRevert_OnERC721Received_UnalignedNft_UnalignedInventoryPosition() public {
        vm.startPrank(NFTX_INVENTORY_STAKING.ownerOf(10));  
        vm.expectRevert(IAlignmentVault.AV_UnalignedNft.selector);
        NFTX_INVENTORY_STAKING.safeTransferFrom(NFTX_INVENTORY_STAKING.ownerOf(10), address(av), 10);
    }

    function testRevert_OnERC1155Received_Unaligned() public prank(notOwner) {
        MockERC1155 unaligned = new MockERC1155();
        unaligned.mint(notOwner, 1, 1, '');
        vm.expectRevert(IAlignmentVault.AV_UnalignedNft.selector); 
        unaligned.safeTransferFrom(notOwner, address(av), 1, 1, '');
    }

    function testRevert_OnERC1155BatchReceived_Unaligned() public prank(notOwner) {
        MockERC1155 unaligned = new MockERC1155();
        unaligned.mint(notOwner, 1, 1, '');
        uint256 [] memory ids = new uint256[](1);
        uint256 [] memory amounts = new uint256[](1);
        ids[0] = amounts[0] = 1;
        vm.expectRevert(IAlignmentVault.AV_UnalignedNft.selector); 
        unaligned.safeBatchTransferFrom(notOwner, address(av), ids, amounts, '');
    }

}