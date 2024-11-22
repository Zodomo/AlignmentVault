// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "../lib/forge-std/src/Test.sol";
import {AlignmentVaultFactory} from "./../src/AlignmentVaultFactory.sol";
import {AlignmentVaultImplementation} from "./../src/AlignmentVaultImplementation.sol";

import {IAlignmentVault} from "../src/IAlignmentVault.sol";
import {IAlignmentVaultFactory} from "../src/IAlignmentVaultFactory.sol";

import {IERC20} from "../lib/openzeppelin-contracts-v5/contracts/interfaces/IERC20.sol";

contract NonReceiver {
// @audit this could represent a state where the eth transfer reverts
}

contract AlignmentVaultFactoryTest is Test {
    AlignmentVaultFactory avf;
    AlignmentVaultImplementation avi;
    AlignmentVaultImplementation avi_new;
    NonReceiver nonrcvr;
    address deployer;
    address attacker;
    uint128 public constant MINT = 1 ether;

    address public vault;
    uint256 public vaultId;
    address public alignedNft;

    address public constant MILADY = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint96 public constant VAULT_ID = 5;

    function setUp() public {
        vm.createSelectFork("mainnet");
        deployer = makeAddr("deployer");
        attacker = makeAddr("alice");
        deal(deployer, MINT);

        avi = new AlignmentVaultImplementation();
        vm.label(address(avi), "alignment vault");
        vm.label(address(WETH), "Wrapped Eth");

        avf = new AlignmentVaultFactory(deployer, address(avi));
        vm.label(address(avf), "alignment factory ");
    }

    modifier prank(
        address who
    ) {
        vm.startPrank(who);
        _;
        vm.stopPrank();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //                HAPPY PATHS
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    function testDeployAlignmentVault() public prank(deployer) {
        (address dplymnt) = avf.deploy(deployer, MILADY, VAULT_ID);
        console2.log("the vault deployment is", dplymnt);
    }

    function testVaultInitializesProperly() public prank(deployer) {
        // deployer deploys
        (address cr) = avf.deploy(deployer, MILADY, VAULT_ID);
        assertEq(MILADY, IAlignmentVault(cr).alignedNft());
        assertEq(VAULT_ID, IAlignmentVault(cr).vaultId());

        //try calling functions on the alignment vault directly
        console2.log("the vault deployment is", cr);
        console2.log("the aligned nft is: ", IAlignmentVault(cr).alignedNft());
        console2.log("the aligned vault id is: ", IAlignmentVault(cr).vaultId());
        // console2.log("the pool is: ", IAlignmentVault(cr).pool());
    }

    function testDeployDeterministic() public prank(deployer) {
        (address dplyment) = avf.deployDeterministic(deployer, MILADY, VAULT_ID, bytes32("salt"));
        console2.log("determined address @", dplyment);
    }

    function testGetInitCodeHash() public prank(attacker) returns (bytes32 res) {
        (res) = avf.initCodeHash();
        return res;
    }

    function testPredictDeterministicAddress() public prank(attacker) returns (address dplymt) {
        (dplymt) = avf.predictDeterministicAddress(bytes32("salt"));
        return dplymt;
    }

    function testPredictedAddressesMatch() public prank(attacker) {
        (address da) = avf.deployDeterministic(deployer, MILADY, VAULT_ID, bytes32("salt"));
        (address ad) = avf.predictDeterministicAddress(bytes32("salt"));

        assertEq(da, ad);
    }

    function testUpdateAVImplementationByDeployer() public prank(deployer) {
        avi_new = new AlignmentVaultImplementation();
        avf.updateImplementation(address(avi_new));
    }

    function testUpdateAVImplementationByUnauth() public prank(attacker) {
        avi_new = new AlignmentVaultImplementation();
        vm.expectRevert();
        avf.updateImplementation(address(avi_new));
    }

    function testWithdrawEthByDeployer() public prank(deployer) {
        avf.withdrawEth(address(deployer));
    }

    function testWithdrawEthByAttacker() public prank(attacker) {
        vm.expectRevert();
        avf.withdrawEth(address(attacker));
    }

    function testWithdrawEthToReverting() public prank(deployer) {
        nonrcvr = new NonReceiver();
        vm.expectRevert();
        avf.withdrawEth(address(nonrcvr));
    }
}
