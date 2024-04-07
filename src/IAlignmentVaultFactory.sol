// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

/**
 * @title IAlignmentVaultFactory
 * @notice This can be used by any EOA or contract to deploy an AlignmentVault owned by the deployer.
 * @dev deploy() will perform a normal deployment. deployDeterministic() allows you to mine a deployment address.
 * @author Zodomo.eth (X: @0xZodomo, Telegram: @zodomo, GitHub: Zodomo, Email: zodomo@proton.me)
 * @custom:github https://github.com/Zodomo/AlignmentVault
 * @custom:miyamaker https://miyamaker.com
 */
interface IAlignmentVaultFactory {
    // Errors
    error AVF_WithdrawalFailed();

    // Events
    event AVF_ImplementationSet(address indexed implementation);
    event AVF_Deployed(address indexed deployer, address indexed deployment);

    // Deployment Functions
    function deploy(
        address alignedNft,
        uint256 vaultId
    ) external payable returns (address deployment);
    function deployDeterministic(
        address alignedNft,
        uint256 vaultId,
        bytes32 salt
    ) external payable returns (address deployment);

    function initCodeHash() external view returns (bytes32 codeHash);
    function predictDeterministicAddress(
        bytes32 salt
    ) external view returns (address addr);

    // Management Functions
    function updateImplementation(address newImplementation) external payable;
    function withdrawEth(address recipient) external payable;
    function withdrawERC20(address token, address recipient) external payable;
    function withdrawERC721(
        address token,
        uint256 tokenId,
        address recipient
    ) external payable;
    function withdrawERC1155(
        address token,
        uint256 tokenId,
        uint256 amount,
        address recipient
    ) external payable;
    function withdrawERC1155Batch(
        address token,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        address recipient
    ) external payable;
}
