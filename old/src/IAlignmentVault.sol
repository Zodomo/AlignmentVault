// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

/**
 * @title IAlignmentVault
 * @dev Interface for interacting with an Alignment Vault contract.
 * @author Zodomo.eth (X: @0xZodomo, Telegram: @zodomo, Email: zodomo@proton.me)
 */
interface IAlignmentVault {
    // Returns the ID of the vault.
    function vaultId() external view returns (uint256);
    
    // Returns the number of NFTs held at a given index.
    function nftsHeld(uint256 _index) external view returns (uint256);

    // Initializes the vault with ERC721 token, owner address, and vault ID.
    function initialize(address _erc721, address _owner, uint256 _vaultId) external payable;
    
    // Disables initializers.
    function disableInitializers() external payable;

    // Aligns NFTs with the specified token IDs.
    function alignNfts(uint256[] memory _tokenIds) external payable;
    
    // Aligns tokens with the specified amount.
    function alignTokens(uint256 _amount) external payable;
    
    // Aligns maximum liquidity.
    function alignMaxLiquidity() external payable;
    
    // Claims yield and sends it to the specified recipient.
    function claimYield(address _recipient) external payable;

    // Checks inventory for the specified token IDs.
    function checkInventory(uint256[] memory _tokenIds) external payable;
    
    // Gets the inventory of the vault.
    function getInventory() external view returns (uint256[] memory);

    // Rescues ERC20 tokens and transfers them to the specified recipient.
    function rescueERC20(address _token, address _to) external payable returns (uint256);
    
    // Rescues ERC721 tokens and transfers them to the specified recipient.
    function rescueERC721(address _token, address _to, uint256 _tokenId) external payable;
}
