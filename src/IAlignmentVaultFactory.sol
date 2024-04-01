// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

/**
 * @title IAlignmentVaultFactory
 * @dev Interface for the Alignment Vault Factory contract
 *      This interface defines functions for deploying and managing Alignment Vaults.
 *      Alignment Vaults are used to store ERC721 tokens in a deterministic way.
 * @author Zodomo.eth (X: @0xZodomo, Telegram: @zodomo, Email: zodomo@proton.me)
 */
interface IAlignmentVaultFactory {
    // Returns the current implementation address of the factory contract
    function implementation() external view returns (address);

    // Returns the deployer contract address for a specific type of vault
    function vaultDeployers(address _vault) external view returns (address);

    // Updates the implementation address of the factory contract
    function updateImplementation(address _implementation) external;

    // Deploys a new Alignment Vault for the specified ERC721 token and vault ID
    function deploy(address _erc721, uint256 _vaultId) external returns (address);

    // Deploys a deterministic Alignment Vault for the specified ERC721 token, vault ID, and salt
    function deployDeterministic(address _erc721, uint256 _vaultId, bytes32 _salt) external returns (address);

    // Returns the hash of the initialization code used in deterministic deployment
    function initCodeHash() external view returns (bytes32);

    // Predicts the address of a deterministic Alignment Vault using the specified salt
    function predictDeterministicAddress(bytes32 _salt) external view returns (address);
}
