// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

/**
 * @title IAlignmentVault
 * @dev Interface for the Alignment Vault contract.
 *      This interface defines functions for managing Alignment Vaults, which are used to store ERC721 tokens in a deterministic way.
 *      Each Alignment Vault is associated with a specific ERC721 contract and a unique vault ID.
 *      The owner of the Alignment Vault can align (deposit) ERC721 tokens, claim yield, and rescue ERC20/ERC721 tokens.
 * @author Zodomo.eth (X: @0xZodomo, Telegram: @zodomo, Email: zodomo@proton.me)
 */
interface IAlignmentVault {
    // Returns the vault ID of the Alignment Vault
    function vaultId() external view returns (uint256);

    // Returns the number of ERC721 tokens held by the Alignment Vault at the specified index
    function nftsHeld(uint256 _index) external view returns (uint256);

    // Initializes the Alignment Vault with the specified ERC721 contract address, owner address, and vault ID
    function initialize(address _erc721, address _owner, uint256 _vaultId) external payable;

    // Disables the initialization function to prevent further initialization
    function disableInitializers() external payable;

    // Aligns (deposits) ERC721 tokens specified by their token IDs into the Alignment Vault
    function alignNfts(uint256[] memory _tokenIds) external payable;

    // Aligns (deposits) ERC20 tokens into the Alignment Vault
    function alignTokens(uint256 _amount) external payable;

    // Aligns (deposits) the maximum available liquidity into the Alignment Vault
    function alignMaxLiquidity() external payable;

    // Claims yield accrued by the Alignment Vault and transfers it to the specified recipient address
    function claimYield(address _recipient) external payable;

    // Checks if the specified ERC721 tokens specified by their token IDs are held by the Alignment Vault
    function checkInventory(uint256[] memory _tokenIds) external payable;

    // Returns an array of ERC721 token IDs held by the Alignment Vault
    function getInventory() external view returns (uint256[] memory);

    // Rescues ERC20 tokens from the Alignment Vault to the specified recipient address
    function rescueERC20(address _token, address _to) external payable returns (uint256);

    // Rescues ERC721 tokens from the Alignment Vault to the specified recipient address
    function rescueERC721(address _token, address _to, uint256 _tokenId) external payable;
}
