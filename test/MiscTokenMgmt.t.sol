// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import "./AlignmentVault.t.sol";
import {MockERC20} from "../lib/solady/test/utils/mocks/MockERC20.sol";
import {MockERC721} from "../lib/solady/test/utils/mocks/MockERC721.sol";

contract MiscTokenMgmtTest is AlignmentVaultTest {
    MockERC20 public erc20;
    MockERC721 public erc721;

    function setUp() public override {
        super.setUp();
        erc20 = new MockERC20("ERC20", "ERC20", 18);
        erc20.mint(address(this), 1 ether);
        erc20.transfer(address(av), 1 ether);

        erc721 = new MockERC721();
        erc721.mint(address(this), 1);
        erc721.transferFrom(address(this), address(av), 1);

        deal(address(WETH), address(av), FUNDING_AMOUNT);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //                  MISC TOKEN MANAGEMENT
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

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

    function testUnwrapEth() public prank(deployer) {
        av.unwrapEth(1 ether);
        assertEq(address(av).balance, FUNDING_AMOUNT + 1 ether, "post-WETH unwrap ETH balance error");
    }

    function testWrapEth() public prank(deployer) {
        av.wrapEth(1 ether);
        assertEq(WETH.balanceOf(address(av)), FUNDING_AMOUNT + 1 ether, "post-WETH wrap WETH balance error");
    }
}
