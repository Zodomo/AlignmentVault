// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

/**
 * @title IAlignmentVaultFactory
 * @notice This interface defines methods for deploying and managing AlignmentVault contracts.
 * @dev This interface allows for deploying AlignmentVault contracts and managing their implementations and assets.
 * @author Zodomo.eth (X: @0xZodomo, Telegram: @zodomo, GitHub: Zodomo, Email: zodomo@proton.me)
 * @custom:github https://github.com/Zodomo/AlignmentVault
 * @custom:miyamaker https://miyamaker.com
 */
interface IAlignmentVaultFactory {
    // >>>>>>>>>>>> [ ERRORS ] <<<<<<<<<<<<

    // Error indicating failed withdrawal from AlignmentVault
    error AVF_WithdrawalFailed();

    // >>>>>>>>>>>> [ EVENTS ] <<<<<<<<<<<<

    // Event emitted when setting a new implementation for AlignmentVault
    event AVF_ImplementationSet(address indexed implementation);

    // Event emitted when deploying a new AlignmentVault contract
    event AVF_Deployed(address indexed deployer, address indexed deployment);

    // >>>>>>>>>>>> [ DEPLOYMENT FUNCTIONS ] <<<<<<<<<<<<

    // Deploys a new AlignmentVault contract and returns its address
    function deploy(address alignedNft, uint256 vaultId) external payable returns (address deployment);

    // Deploys a new AlignmentVault contract at a deterministic address and returns its address
    function deployDeterministic(address alignedNft, uint256 vaultId, bytes32 salt) external payable returns (address deployment);

    // Returns the initialization code hash of AlignmentVault
    function initCodeHash() external view returns (bytes32 codeHash);

    // Predicts the address of a deterministically deployed AlignmentVault
    function predictDeterministicAddress(bytes32 salt) external view returns (address addr);

    // >>>>>>>>>>>> [ MANAGEMENT FUNCTIONS ] <<<<<<<<<<<<

    // Updates the implementation address of AlignmentVault
    function updateImplementation(address newImplementation) external payable;

    // Withdraws Ether from the contract and sends it to the specified recipient
    function withdrawEth(address recipient) external payable;

    // Withdraws ERC20 tokens from the contract and sends them to the specified recipient
    function withdrawERC20(address token, address recipient) external payable;

    // Withdraws ERC721 tokens from the contract and sends them to the specified recipient
    function withdrawERC721(address token, uint256 tokenId, address recipient) external payable;

    // Withdraws ERC1155 tokens from the contract and sends them to the specified recipient
    function withdrawERC1155(address token, uint256 tokenId, uint256 amount, address recipient) external payable;

    // Withdraws ERC1155 tokens in batch from the contract and sends them to the specified recipient
    function withdrawERC1155Batch(address token, uint256[] calldata tokenIds, uint256[] calldata amounts, address recipient) external payable;
}
