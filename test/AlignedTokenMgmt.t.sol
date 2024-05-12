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
    }

    // TODO: Add liquidity to pool so buy can process, reverts if only one NFT is present
    /*function testBuyNftsFromPool() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = INFTXVaultV3(vault).nftIdAt(0);
        av.buyNftsFromPool(10 ether, tokenIds, type(uint256).max, 3000, 0);
    }*/

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
