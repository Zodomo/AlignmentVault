// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {Test, console2} from "../lib/forge-std/src/Test.sol";
import {AlignmentVault} from "../src/AlignmentVault.sol";
import {IAlignmentVault} from "../src/IAlignmentVault.sol";
import {IERC721} from "../lib/openzeppelin-contracts-v5/contracts/interfaces/IERC721.sol";

contract AlignmentVaultTest is Test {
    AlignmentVault public av;
    address public milady = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5;

    function setUp() public {
        av = new AlignmentVault();
        av.initialize(address(this), milady, 5);
    }

    function targetInitialize() public {
        av = new AlignmentVault();
        av.initialize(address(this), milady, 5);
    }

    function lazyInitialize() public {
        av = new AlignmentVault();
        av.initialize(address(this), milady, 0);
    }

    function transferMilady(address recipient, uint256 tokenId) public {
        address target = IERC721(milady).ownerOf(tokenId);
        vm.prank(target);
        IERC721(milady).transferFrom(target, recipient, tokenId);
    }

    function safeTransferMilady(address recipient, uint256 tokenId) public {
        address target = IERC721(milady).ownerOf(tokenId);
        vm.prank(target);
        IERC721(milady).safeTransferFrom(target, recipient, tokenId);
    }

    function testTargetInitialize() public {
        targetInitialize();
        assertEq(av.vaultId(), 5);
        assertEq(address(av.alignedNft()), milady);
    }

    function testLazyInitialize() public {
        lazyInitialize();
        assertEq(av.vaultId(), 5);
        assertEq(address(av.alignedNft()), milady);
    }

    function testWrapOnReceive() public {
        (bool success,) = payable(address(av)).call{value: 0.1 ether}("");
        if (!success) revert("ETH direct payment to contract failed");
    }

    function testOnERC721Received() public {
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_ReceivedAlignedNft(420);
        safeTransferMilady(address(av), 420);
    }

    function testGetInventory() public {
        uint256[] memory inventory = new uint256[](1);
        inventory[0] = 69;
        safeTransferMilady(address(av), 69);
        assertEq(av.getInventory(), inventory);
    }

    function testUpdateInventory() public {
        transferMilady(address(av), 333);
        uint256[] memory inventory = new uint256[](0);
        assertEq(av.getInventory(), inventory);
        inventory = new uint256[](1);
        inventory[0] = 333;
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_ReceivedAlignedNft(333);
        av.updateInventory(inventory);
    }
}