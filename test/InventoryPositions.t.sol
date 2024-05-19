// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import "./AlignmentVault.t.sol";

contract InventoryPositionsTest is AlignmentVaultTest {
    function setUp() public override {
        super.setUp();
        transferMilady(deployer, 69);
        transferMilady(address(av), 333);
        transferMilady(address(av), 420);
    }

    function testInventoryPositionCreateVToken() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 69;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        uint256 expectedPositionId = IERC721Enumerable(address(NFTX_INVENTORY_STAKING)).totalSupply() + 1;

        mintVToken(tokenIds, amounts, deployer, deployer);
        IERC20(vault).transfer(address(av), 1 ether);

        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionCreated(expectedPositionId, 1 ether);
        uint256 positionId = av.inventoryPositionCreateVToken(1 ether);
        (,,,,, uint256 vTokenShareBalance,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        uint256[] memory positionIds = av.getInventoryPositionIds();

        assertEq(positionId, expectedPositionId, "positionId doesn't match expectations");
        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 0, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 2, "NFT balance is incorrect");
        assertEq(vTokenShareBalance, 1 ether, "vTokenShareBalance doesn't match position");
        assertEq(positionIds[0], positionId, "inventory position ID unaccounted for");
    }

    function testInventoryPositionCreateNfts() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 333;
        tokenIds[1] = 420;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;
        uint256 expectedPositionId = IERC721Enumerable(address(NFTX_INVENTORY_STAKING)).totalSupply() + 1;

        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionCreated(expectedPositionId, 2 ether);
        uint256 positionId = av.inventoryPositionCreateNfts(tokenIds, amounts);
        (,,,,, uint256 vTokenShareBalance,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        uint256[] memory positionIds = av.getInventoryPositionIds();

        assertEq(positionId, expectedPositionId, "positionId doesn't match expectations");
        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 0, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 0, "NFT balance is incorrect");
        assertEq(vTokenShareBalance, 2 ether, "vTokenShareBalance doesn't match position");
        assertEq(positionIds[0], positionId, "inventory position ID unaccounted for");
    }

    // Cannot increase an inventory position created with NFTs
    function testInventoryPositionIncrease() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 333;
        tokenIds[1] = 420;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        av.mintVToken(tokenIds, amounts);
        uint256 positionId = av.inventoryPositionCreateVToken(1 ether);
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionIncreased(positionId, 1 ether);
        av.inventoryPositionIncrease(positionId, 1 ether);
        (,,,,, uint256 vTokenShareBalance,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        uint256[] memory positionIds = av.getInventoryPositionIds();

        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 0, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 0, "NFT balance is incorrect");
        assertEq(vTokenShareBalance, 2 ether, "vTokenShareBalance doesn't match position");
        assertEq(positionIds[0], positionId, "inventory position ID unaccounted for");
    }

    function testInventoryVTokenPositionVTokenWithdrawal() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 333;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        av.mintVToken(tokenIds, amounts);
        uint256 positionId = av.inventoryPositionCreateVToken(1 ether);
        vm.warp(block.timestamp + 3 days + 1);
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionWithdrawal(positionId, 1 ether);
        av.inventoryPositionWithdrawal(positionId, 1 ether, none, 0);
        (,,,,, uint256 vTokenShareBalance,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        uint256[] memory positionIds = av.getInventoryPositionIds();

        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 1 ether, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 1, "NFT balance is incorrect");
        assertEq(vTokenShareBalance, 0, "vTokenShareBalance doesn't match position");
        assertEq(positionIds[0], positionId, "inventory position ID unaccounted for");
    }

    function testInventoryVTokenPositionNftWithdrawal() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 333;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        av.mintVToken(tokenIds, amounts);
        uint256 positionId = av.inventoryPositionCreateVToken(1 ether);
        vm.warp(block.timestamp + 3 days + 1);
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionWithdrawal(positionId, 1 ether);
        av.inventoryPositionWithdrawal(positionId, 1 ether, tokenIds, 0);
        (,,,,, uint256 vTokenShareBalance,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        uint256[] memory positionIds = av.getInventoryPositionIds();

        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 0, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 2, "NFT balance is incorrect");
        assertEq(vTokenShareBalance, 0, "vTokenShareBalance doesn't match position");
        assertEq(positionIds[0], positionId, "inventory position ID unaccounted for");
    }

    function testInventoryVTokenPositionBothWithdrawal() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 333;
        tokenIds[1] = 420;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;
        uint256[] memory withdrawal = new uint256[](1);
        withdrawal[0] = 420;

        av.mintVToken(tokenIds, amounts);
        uint256 positionId = av.inventoryPositionCreateVToken(2 ether);
        vm.warp(block.timestamp + 3 days + 1);
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionWithdrawal(positionId, 2 ether);
        av.inventoryPositionWithdrawal(positionId, 2 ether, withdrawal, 0);
        (,,,,, uint256 vTokenShareBalance,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        uint256[] memory positionIds = av.getInventoryPositionIds();

        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 1 ether, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 1, "NFT balance is incorrect");
        assertEq(vTokenShareBalance, 0, "vTokenShareBalance doesn't match position");
        assertEq(positionIds[0], positionId, "inventory position ID unaccounted for");
    }

    function testInventoryNftPositionVTokenWithdrawal() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 333;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        uint256 positionId = av.inventoryPositionCreateNfts(tokenIds, amounts);
        vm.warp(block.timestamp + 3 days + 1);
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionWithdrawal(positionId, 1 ether);
        av.inventoryPositionWithdrawal(positionId, 1 ether, none, 0);
        (,,,,, uint256 vTokenShareBalance,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        uint256[] memory positionIds = av.getInventoryPositionIds();

        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 1 ether, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 1, "NFT balance is incorrect");
        assertEq(vTokenShareBalance, 0, "vTokenShareBalance doesn't match position");
        assertEq(positionIds[0], positionId, "inventory position ID unaccounted for");
    }

    function testInventoryNftPositionNftWithdrawal() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 333;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        uint256 positionId = av.inventoryPositionCreateNfts(tokenIds, amounts);
        vm.warp(block.timestamp + 3 days + 1);
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionWithdrawal(positionId, 1 ether);
        av.inventoryPositionWithdrawal(positionId, 1 ether, tokenIds, 0);
        (,,,,, uint256 vTokenShareBalance,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        uint256[] memory positionIds = av.getInventoryPositionIds();

        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 0, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 2, "NFT balance is incorrect");
        assertEq(vTokenShareBalance, 0, "vTokenShareBalance doesn't match position");
        assertEq(positionIds[0], positionId, "inventory position ID unaccounted for");
    }

    function testInventoryNftPositionBothWithdrawal() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 333;
        tokenIds[1] = 420;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;
        uint256[] memory withdrawal = new uint256[](1);
        withdrawal[0] = 420;

        uint256 positionId = av.inventoryPositionCreateNfts(tokenIds, amounts);
        vm.warp(block.timestamp + 3 days + 1);
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionWithdrawal(positionId, 2 ether);
        av.inventoryPositionWithdrawal(positionId, 2 ether, withdrawal, 0);
        (,,,,, uint256 vTokenShareBalance,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        uint256[] memory positionIds = av.getInventoryPositionIds();

        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 1 ether, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 1, "NFT balance is incorrect");
        assertEq(vTokenShareBalance, 0, "vTokenShareBalance doesn't match position");
        assertEq(positionIds[0], positionId, "inventory position ID unaccounted for");
    }

    function testInventoryVTokenPositionCombineVTokenPosition() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 333;
        tokenIds[1] = 420;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;
        uint256[] memory childPositionIds = new uint256[](1);
        uint256[] memory positionIds = new uint256[](2);

        av.mintVToken(tokenIds, amounts);
        uint256 positionId = av.inventoryPositionCreateVToken(1 ether);
        positionIds[0] = positionId;
        childPositionIds[0] = av.inventoryPositionCreateVToken(1 ether);
        positionIds[1] = childPositionIds[0];

        vm.warp(block.timestamp + 3 days + 1);
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionCombination(positionId, childPositionIds);
        av.inventoryPositionCombine(positionId, childPositionIds);
        (,,,,, uint256 vTokenShareBalance0,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        (,,,,, uint256 vTokenShareBalance1,,) = NFTX_INVENTORY_STAKING.positions(childPositionIds[0]);

        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(NFTX_INVENTORY_STAKING.ownerOf(childPositionIds[0]), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 0, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 0, "NFT balance is incorrect");
        assertEq(vTokenShareBalance0, 2 ether, "vTokenShareBalance doesn't match position");
        assertEq(vTokenShareBalance1, 0, "vTokenShareBalance doesn't match position");
        assertEq(av.getInventoryPositionIds(), positionIds, "inventory position IDs unaccounted for");
    }

    function testInventoryVTokenPositionCombineNftPosition() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 333;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        uint256[] memory childPositionIds = new uint256[](1);
        uint256[] memory positionIds = new uint256[](2);

        av.mintVToken(tokenIds, amounts);
        uint256 positionId = av.inventoryPositionCreateVToken(1 ether);
        positionIds[0] = positionId;
        tokenIds[0] = 420;
        childPositionIds[0] = av.inventoryPositionCreateNfts(tokenIds, amounts);
        positionIds[1] = childPositionIds[0];

        vm.warp(block.timestamp + 3 days + 1);
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionCombination(positionId, childPositionIds);
        av.inventoryPositionCombine(positionId, childPositionIds);
        (,,,,, uint256 vTokenShareBalance0,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        (,,,,, uint256 vTokenShareBalance1,,) = NFTX_INVENTORY_STAKING.positions(childPositionIds[0]);

        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(NFTX_INVENTORY_STAKING.ownerOf(childPositionIds[0]), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 0, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 0, "NFT balance is incorrect");
        assertEq(vTokenShareBalance0, 2 ether, "vTokenShareBalance doesn't match position");
        assertEq(vTokenShareBalance1, 0, "vTokenShareBalance doesn't match position");
        assertEq(av.getInventoryPositionIds(), positionIds, "inventory position IDs unaccounted for");
    }

    function testInventoryNftPositionCombineVTokenPosition() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 333;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        uint256[] memory childPositionIds = new uint256[](1);
        uint256[] memory positionIds = new uint256[](2);

        uint256 positionId = av.inventoryPositionCreateNfts(tokenIds, amounts);
        positionIds[0] = positionId;
        tokenIds[0] = 420;
        av.mintVToken(tokenIds, amounts);
        childPositionIds[0] = av.inventoryPositionCreateVToken(1 ether);
        positionIds[1] = childPositionIds[0];

        vm.warp(block.timestamp + 3 days + 1);
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionCombination(positionId, childPositionIds);
        av.inventoryPositionCombine(positionId, childPositionIds);
        (,,,,, uint256 vTokenShareBalance0,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        (,,,,, uint256 vTokenShareBalance1,,) = NFTX_INVENTORY_STAKING.positions(childPositionIds[0]);

        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(NFTX_INVENTORY_STAKING.ownerOf(childPositionIds[0]), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 0, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 0, "NFT balance is incorrect");
        assertEq(vTokenShareBalance0, 2 ether, "vTokenShareBalance doesn't match position");
        assertEq(vTokenShareBalance1, 0, "vTokenShareBalance doesn't match position");
        assertEq(av.getInventoryPositionIds(), positionIds, "inventory position IDs unaccounted for");
    }

    function testInventoryNftPositionCombineNftPosition() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 333;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        uint256[] memory childPositionIds = new uint256[](1);
        uint256[] memory positionIds = new uint256[](2);

        uint256 positionId = av.inventoryPositionCreateNfts(tokenIds, amounts);
        positionIds[0] = positionId;
        tokenIds[0] = 420;
        childPositionIds[0] = av.inventoryPositionCreateNfts(tokenIds, amounts);
        positionIds[1] = childPositionIds[0];

        vm.warp(block.timestamp + 3 days + 1);
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionCombination(positionId, childPositionIds);
        av.inventoryPositionCombine(positionId, childPositionIds);
        (,,,,, uint256 vTokenShareBalance0,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        (,,,,, uint256 vTokenShareBalance1,,) = NFTX_INVENTORY_STAKING.positions(childPositionIds[0]);

        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(NFTX_INVENTORY_STAKING.ownerOf(childPositionIds[0]), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 0, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 0, "NFT balance is incorrect");
        assertEq(vTokenShareBalance0, 2 ether, "vTokenShareBalance doesn't match position");
        assertEq(vTokenShareBalance1, 0, "vTokenShareBalance doesn't match position");
        assertEq(av.getInventoryPositionIds(), positionIds, "inventory position IDs unaccounted for");
    }

    function testInventoryPositionCollectAllFees() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 69;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        vm.startPrank(deployer);
        mintVToken(tokenIds, amounts, deployer, deployer);
        IERC20(vault).transfer(address(av), 1 ether);
        uint256 positionId = av.inventoryPositionCreateVToken(1 ether);
        vm.stopPrank();

        WETH.deposit{value: 10 ether}();
        WETH.transfer(address(NFTX_VAULT_FACTORY.feeDistributor()), 10 ether);

        startHoax(address(NFTX_VAULT_FACTORY.feeDistributor()));
        WETH.approve(address(NFTX_INVENTORY_STAKING), type(uint256).max);
        bool rewardsDistributed = NFTX_INVENTORY_STAKING.receiveWethRewards(vaultId, 10 ether);
        if (!rewardsDistributed) revert("Rewards not distributed");
        vm.stopPrank();

        vm.startPrank(deployer);
        uint256 balance = WETH.balanceOf(deployer);
        uint256 fees = av.getTotalInventoryPositionFees();
        assertEq(fees, av.getSpecificInventoryPositionFees(positionId), "total vs specific fees getter mismatch");
        av.inventoryPositionCollectAllFees(deployer);
        assertEq(WETH.balanceOf(deployer), balance + fees, "balance not changed by exact fees claim amount");
        vm.stopPrank();
    }
}
