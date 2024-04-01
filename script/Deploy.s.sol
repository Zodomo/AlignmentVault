// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

// Importing Script and console2 from the specified path
import {Script, console2} from "../lib/forge-std/src/Script.sol";
// Importing AlignmentVault contract from the specified path
import {AlignmentVault} from "../src/AlignmentVault.sol";

// Interface for initialization functions
interface IInitialize {
    // Function to initialize the contract with specific parameters
    function initialize(
        address _owner, // Address of the owner
        address _alignedNft, // Address of the aligned NFT
        uint256 _vaultId // ID of the vault
    ) external payable;
    
    // Function to disable initializers
    function disableInitializers() external payable;
}

// Contract for deploying scripts
contract DeployScript is Script {
    // No additional code comments needed
}
