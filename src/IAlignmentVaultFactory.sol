// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

interface IAlignmentVaultFactory {
    event AVF_ImplementationSet(address indexed implementation);
    event AVF_Deployed(address indexed deployer, address indexed deployment);

    error AVF_WithdrawalFailed();

    function updateImplementation(address newImplementation) external payable;

    function deploy(address alignedNft, uint256 vaultId) external payable returns (address deployment);
    function deployDeterministic(address alignedNft, uint256 vaultId, bytes32 salt) external payable returns (address deployment);

    function initCodeHash() external view returns (bytes32 codeHash);
    function predictDeterministicAddress(bytes32 salt) external view returns (address addr);

    function withdrawEth(address recipient) external payable;
    function withdrawERC20(address token, address recipient) external payable;
    function withdrawERC721(address token, uint256 tokenId, address recipient) external payable;
    function withdrawERC1155(address token, uint256 tokenId, uint256 amount, address recipient) external payable;
    function withdrawERC1155Batch(address token, uint256[] calldata tokenIds, uint256[] calldata amounts, address recipient) external payable;
}