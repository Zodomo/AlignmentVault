// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {Script, console2} from "../lib/forge-std/src/Script.sol";
import {AlignmentVault} from "../src/AlignmentVault.sol";

interface IInitialize {
    function initialize(address _owner, address _alignedNft, uint256 _vaultId) external payable;
    function disableInitializers() external payable;
}

contract DeployScript is Script {
    AlignmentVault public alignmentVault;

    constructor(AlignmentVault _alignmentVault) {
        alignmentVault = _alignmentVault;
    }

    // Function to deploy the AlignmentVault contract
    function deployAlignmentVault(
        address _owner,
        address _alignedNft,
        uint256 _vaultId
    ) external payable {
        // Initialize the AlignmentVault contract
        IInitialize(alignmentVault).initialize{value: msg.value}(
            _owner,
            _alignedNft,
            _vaultId
        );

        // Optionally disable initializers if required
        // IInitialize(alignmentVault).disableInitializers{value: msg.value}();

        // Emit an event or perform any other necessary actions
        emit AlignmentVaultDeployed(msg.sender, _owner, _alignedNft, _vaultId);
    }

    // Event to log the deployment of AlignmentVault
    event AlignmentVaultDeployed(
        address indexed deployer,
        address indexed owner,
        address alignedNft,
        uint256 vaultId
    );
}

contract DeployScript is Script {}
