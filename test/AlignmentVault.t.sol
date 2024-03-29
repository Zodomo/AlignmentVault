// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {Test, console2} from "../lib/forge-std/src/Test.sol";
import {AlignmentVault} from "../src/AlignmentVault.sol";

contract AlignmentVaultTest is Test {
    AlignmentVault public av;
    address public milady = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5;

    function setUp() public {
        av = new AlignmentVault();
    }

    function targetInitialize() public {
        av.initialize(address(this), milady, 5);
    }

    function lazyInitialize() public {
        av.initialize(address(this), milady, 0);
    }

    function testTargetInitialize() public {
        targetInitialize();
        assertEq(av.vaultId(), 5);
        assertEq(av.alignedNft(), milady);
    }

    function testLazyInitialize() public {
        lazyInitialize();
        assertEq(av.vaultId(), 5);
        assertEq(av.alignedNft(), milady);
    }
}