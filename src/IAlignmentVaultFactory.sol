// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

/**
 * @title IAlignmentVaultFactory
 * @author Zodomo.eth (X: @0xZodomo, Telegram: @zodomo, Email: zodomo@proton.me)
 */
interface IAlignmentVaultFactory {
    function implementation() external view returns (address);
    function vaultDeployers(address _vault) external view returns (address);

    function updateImplementation(address _implementation) external;
    function deploy(address _erc721, uint256 _vaultId) external returns (address);
    function deployDeterministic(address _erc721, uint256 _vaultId, bytes32 _salt) external returns (address);
    function initCodeHash() external view returns (bytes32);
    function predictDeterministicAddress(bytes32 _salt) external view returns (address);
}