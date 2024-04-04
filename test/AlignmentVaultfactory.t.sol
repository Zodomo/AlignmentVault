// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "../lib/forge-std/src/Test.sol";
import {AlignmentVaultFactory} from "./../src/AlignmentVaultFactory.sol";
import {AlignmentVault} from "./../src/AlignmentVault.sol";

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
//                  WEIRD ERC20 TOKENS
/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

import "../node_modules/weird-erc20/src/MissingReturns.sol";
import "../node_modules/weird-erc20/src/ERC20.sol";

contract Attack1 {
    AlignmentVaultFactory avf;

    constructor(address _avf) {
        avf = AlignmentVaultFactory(_avf);
        avf.withdrawEth(address(this));
    }

    receive() external payable {
        avf.withdrawEth(address(this));
    }
}

contract AlignmentVaultFactoryTest is Test {
    AlignmentVaultFactory avf;
    AlignmentVault av;
    AlignmentVault av_new;
    address deployer;
    address attacker;
    uint128 public constant MINT = 1 ether;


    address public constant ERC20WHALE = address(1);
    address public constant ERC20 = address(4);
    address public constant nonCompliantERC20_1 = address(7);
    address public constant nonCompliantERC20_2 = address(9);
    address public constant nonCompliantERC20_3 = address(10);
    address public constant ERC721WHALE = address(2);
    address public constant ERC721 = address(5); // preferably milady
    address public constant ERC721another = address(6); // preferably milady
    address public constant ERC1155WHALE = address(3);
    address public constant ERC1155 = address(8);

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
    //                HAPPY PATHS
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    function testDeployAlignmentVault() public prank(deployer) {
        avf.deploy(MILADY, VAULT_ID);
    }

    function testDeployDeterministic() public prank(deployer) {
        avf.deployDeterministic(MILADY, VAULT_ID, bytes32("salt"));
    }

    function testPredictDeterministicAddress() public prank(attacker) {
        avf.predictDeterministicAddress(bytes32("salt"));
    }

    function testPredictedAddressesMatch() public prank(attacker) {
        (address da) = avf.deployDeterministic(MILADY, VAULT_ID, bytes32("salt"));
        (address ad) = avf.predictDeterministicAddress(bytes32("salt"));

        assertEq(da, ad);
    }

    function testGetInitCodeHash() public prank(attacker) {
        avf.initCodeHash();
    }

    function testUpdateAVImplementationByDeployer() public prank(deployer) {
        av_new = new AlignmentVault();
        avf.updateImplementation(address(av_new));
    }

    function testUpdateAVImplementationByUnauth() public prank(attacker) {
        av_new = new AlignmentVault();
        vm.expectRevert();
        avf.updateImplementation(address(av_new));
    }

    function testWithdrawEthByDeployer() public prank(deployer) {
        avf.withdrawEth(address(deployer));
    }

    function testWithdrawEthByDeployerToCA() public prank(deployer) {
        vm.expectRevert();
        Attack1 attk = new Attack1(address(avf));
    }

    function testWithdrawEthByDeployerToDeadAddress() public prank(deployer) {
        //@audit-issue admin could mistakely burn eth
        avf.withdrawEth(address(0));
    }

    function testWithdrawEthByAttacker() public prank(attacker) {
        vm.expectRevert();
        avf.withdrawEth(address(attacker));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //                  TOKEN INTEGRATION
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function testWithdrawErc20() public {}
    function testWithdrawErc721() public {}
    function testWithdrawErc1155() public {}
    function testWithdrawErc1155Batch() public {}
}
