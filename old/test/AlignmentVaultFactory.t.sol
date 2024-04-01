// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import "../src/AlignmentVault.sol";
import "../src/AlignmentVaultFactory.sol";

contract FactoryTest is DSTestPlus {
    AlignmentVault public implementation; // The implementation contract for the vault
    AlignmentVault public implementation2; // Another implementation contract for testing
    AlignmentVaultFactory public factory; // The factory contract for deploying vaults

    function setUp() public {
        implementation = new AlignmentVault(); // Deploying the first implementation contract
        implementation2 = new AlignmentVault(); // Deploying the second implementation contract for testing
        factory = new AlignmentVaultFactory(address(this), address(implementation)); // Deploying the factory contract
    }

    function testUpdateImplementation() public {
        factory.updateImplementation(address(implementation2)); // Testing updating the implementation of the factory to implementation2
        require(factory.implementation() == address(implementation2)); // Verifying that the implementation was updated correctly
    }

    function testUpdateImplementationNoChange() public {
        hevm.expectRevert(bytes("")); // Expecting a revert when trying to update with the same implementation
        factory.updateImplementation(address(implementation)); // Testing updating the implementation with the same implementation
    }

    function deployContract() public returns (address) {
        address erc721 = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5; // The address of the ERC721 contract
        uint256 vaultId = 392; // The ID of the vault

        address deployment = factory.deploy(erc721, vaultId); // Deploying a vault
        return deployment; // Returning the address of the deployed vault
    }

    function deployDeterministicContract() public returns (address) {
        address erc721 = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5; // The address of the ERC721 contract
        uint256 vaultId = 392; // The ID of the vault
        bytes32 salt = bytes32("42069"); // Salt for deterministic deployment

        address deployment = factory.deployDeterministic(erc721, vaultId, salt); // Deploying a vault deterministically
        return deployment; // Returning the address of the deployed vault
    }

    function testDeploy() public {
        address collection = deployContract(); // Deploying a vault and assigning its address to collection
        require(collection != address(0), "deployment failure"); // Verifying that the deployment was successful
    }

    function testDeployDeterministic() public {
        address collection = deployDeterministicContract(); // Deploying a vault deterministically and assigning its address to collection
        require(collection != address(0), "deployment failure"); // Verifying that the deployment was successful
    }

    function testMultipleDeployments() public {
        address deploy0 = deployContract(); // Deploying the first vault and assigning its address to deploy0
        address deploy1 = deployContract(); // Deploying the second vault and assigning its address to deploy1
        address deploy2 = deployContract(); // Deploying the third vault and assigning its address to deploy2
        address deploy3 = deployContract(); // Deploying the fourth vault and assigning its address to deploy3
        require(deploy0 != deploy1); // Verifying that each deployment has a unique address
        require(deploy1 != deploy2);
        require(deploy2 != deploy3);
        require(deploy3 != deploy0);
    }

    function testInitCodeHash() public view {
        require(factory.initCodeHash() != bytes32(0)); // Verifying that the init code hash is not zero
    }

    function testPredictDeterministicAddress(bytes32 _salt) public {
        address erc721 = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5; // The address of the ERC721 contract
        address predicted = factory.predictDeterministicAddress(_salt); // Predicting the address of the deterministically deployed vault
        address deployed = factory.deployDeterministic(erc721, 392, _salt); // Deploying a vault deterministically
        require(predicted == deployed); // Verifying that the predicted address matches the deployed address
    }
}
