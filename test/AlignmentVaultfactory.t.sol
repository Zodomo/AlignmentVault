// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "../lib/forge-std/src/Test.sol";
import {AlignmentVaultFactory} from "./../src/AlignmentVaultFactory.sol";
import {AlignmentVault} from "./../src/AlignmentVault.sol";

contract AlignmentVaultFactoryTest is Test {
    AlignmentVaultFactory avf;
    AlignmentVault av;
    address deployer;
    uint128 public constant MINT = 1 ether;

    address public vault;
    uint256 public vaultId;
    address public alignedNft;

    address public constant MILADY = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5;
    uint256 public constant VAULT_ID = 5;

    function setUp() public {
        (uint256 forkId) = vm.createSelectFork("mainnet", 15_969_633);
        emit log_named_uint("currently on", forkId);
        deployer = makeAddr("deployer");
        deal(deployer, MINT);

        av = new AlignmentVault();
        vm.label(address(av), "alignment vault");

        avf = new AlignmentVaultFactory(deployer, address(av));
        vm.label(address(avf), "alignment factory ");
    }

    modifier prank(address who) {
        vm.startPrank(who);
        _;
        vm.stopPrank();
    }

    function testDeployAlignmentVault() public prank(deployer) {
        avf.deploy(MILADY, VAULT_ID);
    }
}
