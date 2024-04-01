// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

/**
 * @title IAlignmentVaultFactory
 * @dev Interface for the Alignment Vault Factory contract.
 * @author Zodomo.eth (X: @0xZodomo, Telegram: @zodomo, Email: zodomo@proton.me)
 */
interface IAlignmentVaultFactory {
    // Returns the address of the current implementation contract.
    function implementation() external view returns (address);

    // Returns the address of the vault deployer for a specific vault address.
    function vaultDeployers(address _vault) external view returns (address);

    // Updates the implementation contract address.
    function updateImplementation(address _implementation) external;

    // Deploys a new Alignment Vault contract.
    function deploy(address _erc721, uint256 _vaultId) external returns (address);

    // Deploys a new Alignment Vault contract with a deterministic address using salt.
    function deployDeterministic(address _erc721, uint256 _vaultId, bytes32 _salt) external returns (address);

    // Returns the init code hash used for deterministic address calculation.
    function initCodeHash() external view returns (bytes32);

    // Predicts the address of a deterministically deployed Alignment Vault using salt.
    function predictDeterministicAddress(bytes32 _salt) external view returns (address);
}
