// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "../lib/forge-std/src/Test.sol";
import {AlignmentVaultFactory} from "./../src/AlignmentVaultFactory.sol";
import {AlignmentVault} from "./../src/AlignmentVault.sol";

contract AlignmentVaultFactoryTest is Test {
    AlignmentVaultFactory avf;
    AlignmentVault av;
    AlignmentVault av_new;
    address deployer;
    address attacker;
    uint128 public constant MINT = 1 ether;

    address public vault;
    uint256 public vaultId;
    address public alignedNft;

    address public constant MILADY = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5;
    uint256 public constant VAULT_ID = 5;

    function setUp() public {
        vm.createSelectFork("mainnet");
        deployer = makeAddr("deployer");
        attacker = makeAddr("alice");
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

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //                HAPP PATHS
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    function testDeployAlignmentVault() public prank(deployer) {
        avf.deploy(MILADY, VAULT_ID);
    }

    function testDeployDeterministic() public prank(deployer) {
        avf.deployDeterministic(MILADY, VAULT_ID, bytes32("salt"));
    }

    function testGetInitCodeHash() public prank(attacker){
        avf.initCodeHash();
    }
    function testPredictDeterministicAddress() public prank(attacker){
        avf.predictDeterministicAddress(bytes32("salt"));
    }
    function testPredictedAddressesMatch() public prank(attacker){
        (address da) = avf.deployDeterministic(MILADY, VAULT_ID, bytes32("salt"));
        (address ad) = avf.predictDeterministicAddress(bytes32("salt"));

        assertEq(da, ad);
    }
    function testUpdateAVImplementationByDeployer() public prank(deployer){
    }
    function testUpdateAVImplementationByUnauth() public prank(attacker){
        av_new = new AlignmentVault();
        vm.expectRevert();
        avf.updateImplementation(address(av_new));
    }
    function testWithdrawEthByDeployer() public prank(deployer){
        avf.withdrawEth(address(deployer));
    }
    function testWithdrawEthByDeployerToDeadAddress() public prank(deployer){
        //@audit-issue admin could mistakely burn eth
        avf.withdrawEth(address(0));
    }
    function testWithdrawEthByAttacker() public prank(attacker){
        vm.expectRevert();
        avf.withdrawEth(address(attacker));
    }
    function testWithdrawErc721() public {}
    function testWithdrawErc1155() public {}
    function testWithdrawErc1155Batch() public {}
}
