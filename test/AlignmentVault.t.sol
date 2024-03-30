// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {Test, console2} from "../lib/forge-std/src/Test.sol";
import {AlignmentVault} from "../src/AlignmentVault.sol";
import {IAlignmentVault} from "../src/IAlignmentVault.sol";
import {IERC721} from "../lib/openzeppelin-contracts-v5/contracts/interfaces/IERC721.sol";

contract AlignmentVaultTest is Test {
    AlignmentVault public av;
    address public constant MILADY = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5;
    address public constant VAULT = 0xfA95083034ed077860afcEabDF277C1524C644a5;
    uint256 public constant VAULT_ID = 5;

    function setUp() public {
        av = new AlignmentVault();
        av.initialize(address(this), MILADY, VAULT_ID);
    }

    function targetInitialize() public {
        av = new AlignmentVault();
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_VaultInitialized(VAULT, VAULT_ID);
        av.initialize(address(this), MILADY, VAULT_ID);
    }

    function lazyInitialize() public {
        av = new AlignmentVault();
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_VaultInitialized(VAULT, VAULT_ID);
        av.initialize(address(this), MILADY, 0);
    }

    function transferMilady(address recipient, uint256 tokenId) public {
        address target = IERC721(MILADY).ownerOf(tokenId);
        vm.prank(target);
        IERC721(MILADY).transferFrom(target, recipient, tokenId);
    }

    function safeTransferMilady(address recipient, uint256 tokenId) public {
        address target = IERC721(MILADY).ownerOf(tokenId);
        vm.prank(target);
        IERC721(MILADY).safeTransferFrom(target, recipient, tokenId);
    }

    function testTargetInitialize() public {
        targetInitialize();
        assertEq(av.vaultId(), VAULT_ID);
        assertEq(address(av.alignedNft()), MILADY);
    }

    function testLazyInitialize() public {
        lazyInitialize();
        assertEq(av.vaultId(), VAULT_ID);
        assertEq(address(av.alignedNft()), MILADY);
    }

    function testWrapOnReceive() public {
        (bool success,) = payable(address(av)).call{value: 0.1 ether}("");
        if (!success) revert("ETH direct payment to contract failed");
    }

    function testOnERC721Received() public {
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_ReceivedAlignedNft(420, 1);
        safeTransferMilady(address(av), 420);
    }

    function testGetInventory() public {
        uint256[] memory inventory = new uint256[](1);
        inventory[0] = 69;
        safeTransferMilady(address(av), 69);
        assertEq(av.getNftInventory(), inventory);
    }

    function testUpdateInventory() public {
        transferMilady(address(av), 333);
        uint256[] memory inventory = new uint256[](0);
        assertEq(av.getNftInventory(), inventory);
        inventory = new uint256[](1);
        inventory[0] = 333;
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_ReceivedAlignedNft(333, 1);
        av.updateInventory(inventory);
    }
}