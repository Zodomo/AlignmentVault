// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import "./AlignmentVault.t.sol";
import {MockERC20} from "../lib/solady/test/utils/mocks/MockERC20.sol";
import {MockERC721} from "../lib/solady/test/utils/mocks/MockERC721.sol";
//import {MockERC1155} from "../lib/solady/test/utils/mocks/MockERC1155.sol";

contract MiscTokenMgmtTest is AlignmentVaultTest {
    MockERC20 public erc20;
    MockERC721 public erc721;
    //MockERC1155 public erc1155;

    function setUp() public override {
        super.setUp();
        erc20 = new MockERC20("ERC20", "ERC20", 18);
        erc20.mint(address(this), 1 ether);
        erc20.transfer(address(av), 1 ether);

        erc721 = new MockERC721();
        erc721.mint(address(this), 1);
        erc721.transferFrom(address(this), address(av), 1);

        /*erc1155 = new MockERC1155();
        erc1155.mint(address(this), 1, 1, "tokenURI_1");
        erc1155.mint(address(this), 2, 2, "tokenURI_2");
        erc1155.safeTransferFrom(address(this), address(av), 1, 1, "");
        erc1155.safeTransferFrom(address(this), address(av), 2, 2, "");*/

        WETH.deposit{value: 1 ether}();
        WETH.transfer(address(av), 1 ether);
    }

    function testRescueERC20() public prank(deployer) {
        av.rescueERC20(address(erc20), 1 ether, deployer);
        assertEq(erc20.balanceOf(deployer), 1 ether, "ERC20 balance error");
        vm.expectRevert(IAlignmentVault.AV_ProhibitedWithdrawal.selector);
        av.rescueERC20(address(WETH), 1 ether, deployer);
    }

    function testRescueERC721() public prank(deployer) {
        av.rescueERC721(address(erc721), 1, deployer);
        assertEq(erc721.ownerOf(1), deployer, "ERC721 ownerOf error");
    }

    /*function testRescueERC1155() public prank(deployer) {
        av.rescueERC1155(address(erc1155), 1, 1, deployer);
        assertEq(erc1155.balanceOf(deployer, 1), 1, "ERC1155 balance error");
    }

    function testRescueERC1155Batch() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 2;
        av.rescueERC1155Batch(address(erc1155), tokenIds, amounts, deployer);
        assertEq(erc1155.balanceOf(deployer, 1), 1, "ERC1155 balance error");
        assertEq(erc1155.balanceOf(deployer, 2), 2, "ERC1155 balance error");
    }*/

    function testUnwrapEth() public prank(deployer) {
        av.unwrapEth();
        assertEq(address(av).balance, 11 ether, "post-WETH unwrap ETH balance error");
    }
}