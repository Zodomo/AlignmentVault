// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import "./AlignmentVault.t.sol";

contract AlignedTokenMgmtTest is AlignmentVaultTest {
    function setUp() public override {
        super.setUp();
        transferMilady(address(this), 69);
        transferMilady(address(this), 333);
        IERC721(MILADY).transferFrom(address(this), address(av), 69);
        IERC721(MILADY).safeTransferFrom(address(this), address(av), 333);
        transferMilady(address(av), 420);
        transferMilady(address(av), 777);
        transferMilady(address(av), 999);
    }

    function testBuyNftsFromPool() public prank(deployer) {
        // Add NFTs to inventory
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 420;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        av.inventoryPositionCreateNfts(tokenIds, amounts);

        // Add NFTs to liquidity
        tokenIds = new uint256[](2);
        tokenIds[0] = 777;
        tokenIds[1] = 999;
        amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;
        av.liquidityPositionCreate({
            ethAmount :  20 ether,
            vTokenAmount : 0,
            tokenIds : tokenIds,
            amounts : amounts,
            tickLower : type(int24).min,
            tickUpper : type(int24).max,
            sqrtPriceX96 : 0,
            ethMin : 0,
            vTokenMin : 0
        });

        // Buy NFT from pool
        tokenIds = new uint256[](1);
        tokenIds[0] = 420;
        av.buyNftsFromPool(50 ether, tokenIds, type(uint256).max, 3000, 0);
    }

    function testMintVToken() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 69;
        tokenIds[1] = 333;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;
        av.mintVToken(tokenIds, amounts);
        assertEq(IERC20(vault).balanceOf(address(av)), 2 ether, "vToken mint amount error");
    }

    function testBuyVToken() public prank(deployer) {
        av.buyVToken(1 ether, 3000, 0, 0);
        assertEq(IERC20(vault).balanceOf(address(av)) > 0, true, "vToken balance didn't increase");
    }

    function testBuyVTokenExact() public prank(deployer) {
        av.buyVTokenExact(5 ether, 3000, 0.1 ether, 0);
        assertEq(IERC20(vault).balanceOf(address(av)), 0.1 ether, "vToken swap wasn't exact");
    }

    function testSellVToken() public prank(deployer) {
        av.buyVTokenExact(5 ether, 3000, 0.1 ether, 0);
        av.sellVToken(0.1 ether, 3000, 0, 0);
        assertEq(IERC20(vault).balanceOf(address(av)), 0, "vToken balance wasn't swapped");
    }

    function testSellVTokenExact() public prank(deployer) {
        av.buyVTokenExact(5 ether, 3000, 0.1 ether, 0);
        uint256 balance = address(av).balance;
        av.sellVTokenExact(0.1 ether, 3000, 0.01 ether, 0);
        assertEq(address(av).balance, balance + 0.01 ether, "ETH balance didn't increase");
    }
}
