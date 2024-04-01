// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

// Importing necessary libraries
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import "../src/AlignmentVault.sol";
import "../src/AlignmentVaultFactory.sol";

// Test contract to validate AlignmentVaultFactory functionalities
contract FactoryTest is DSTestPlus {
    // State variables
    AlignmentVault public implementation; // Instance of AlignmentVault contract
    AlignmentVault public implementation2; // Another instance of AlignmentVault contract
    AlignmentVaultFactory public factory; // Instance of AlignmentVaultFactory contract

    // Function to set up initial conditions before each test
    function setUp() public {
        implementation = new AlignmentVault(); // Deploy a new AlignmentVault contract
        implementation2 = new AlignmentVault(); // Deploy another AlignmentVault contract
        factory = new AlignmentVaultFactory(address(this), address(implementation)); // Deploy a new AlignmentVaultFactory contract
    }

    // Function to test updating implementation address
    function testUpdateImplementation() public {
        factory.updateImplementation(address(implementation2)); // Update implementation address to implementation2
        require(factory.implementation() == address(implementation2)); // Check if implementation address is updated correctly
    }

    // Function to test updating implementation address with no change
    function testUpdateImplementationNoChange() public {
        hevm.expectRevert(bytes("")); // Mocking revert condition
        factory.updateImplementation(address(implementation)); // Attempt to update implementation address to the same address
    }

    // Function to deploy a new AlignmentVault contract
    function deployContract() public returns (address) {
        address erc721 = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5; // ERC721 token address
        uint256 vaultId = 392; // Vault ID

        address deployment = factory.deploy(erc721, vaultId); // Deploy a new AlignmentVault contract
        return deployment;
    }

    // Function to deploy a new deterministic AlignmentVault contract
    function deployDeterministicContract() public returns (address) {
        address erc721 = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5; // ERC721 token address
        uint256 vaultId = 392; // Vault ID
        bytes32 salt = bytes32("42069"); // Salt value

        address deployment = factory.deployDeterministic(erc721, vaultId, salt); // Deploy a deterministic AlignmentVault contract
        return deployment;
    }

    // Function to test deploying a new AlignmentVault contract
    function testDeploy() public {
        address collection = deployContract(); // Deploy a new AlignmentVault contract
        require(collection != address(0), "deployment failure"); // Check if deployment is successful
    }

    // Function to test deploying a new deterministic AlignmentVault contract
    function testDeployDeterministic() public {
        address collection = deployDeterministicContract(); // Deploy a new deterministic AlignmentVault contract
        require(collection != address(0), "deployment failure"); // Check if deployment is successful
    }

    // Function to test deploying multiple AlignmentVault contracts
    function testMultipleDeployments() public {
        address deploy0 = deployContract(); // Deploy a new AlignmentVault contract
        address deploy1 = deployContract(); // Deploy another new AlignmentVault contract
        address deploy2 = deployContract(); // Deploy another new AlignmentVault contract
        address deploy3 = deployContract(); // Deploy another new AlignmentVault contract
        require(deploy0 != deploy1); // Ensure each deployment has a unique address
        require(deploy1 != deploy2);
        require(deploy2 != deploy3);
        require(deploy3 != deploy0);
    }

    // Function to test obtaining the initialization code hash of AlignmentVaultFactory contract
    function testInitCodeHash() public view {
        require(factory.initCodeHash() != bytes32(0)); // Ensure initialization code hash is not empty
    }

    // Function to test predicting the address of a deterministic AlignmentVault contract
    function testPredictDeterministicAddress(bytes32 _salt) public {
        address erc721 = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5; // ERC721 token address
        address predicted = factory.predictDeterministicAddress(_salt); // Predict the address of the deterministic contract
        address deployed = factory.deployDeterministic(erc721, 392, _salt); // Deploy a deterministic contract
        require(predicted == deployed); // Ensure predicted address matches the deployed address
    }
}
