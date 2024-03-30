// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

interface IAlignmentVault {
    error AV_ERC721();
    error AV_ERC1155();
    error AV_NoPosition();
    error AV_UnalignedNft();
    error AV_ProhibitedWithdrawal();

    error AV_NFTX_NoVaultsExist();
    error AV_NFTX_InvalidVaultId();
    error AV_NFTX_InvalidVaultNft();
    error AV_NFTX_NoStandardVault();

    event AV_VaultInitialized(address indexed vault, uint256 indexed vaultId);
    event AV_ReceivedAlignedNft(uint256 indexed tokenId, uint256 indexed amount);

    function initialize(
        address _owner,
        address _alignedNft,
        uint256 _vaultId
    ) external payable;
    function disableInitializers() external payable;
    function renounceOwnership() external payable;

    function getInventory() external view returns (uint256[] memory tokenIds);
    function getInventoryAmounts() external view returns (uint256[] memory tokenIds, uint256[] memory amounts);
    function updateInventory(uint256[] calldata tokenIds) external;

    function getChildInventoryPositionIds() external view returns (uint256[] memory childPositionIds);
    function getInventoryPositionsWethBalance() external view returns (uint256 balance);

    function inventoryVTokenDeposit(uint256 amount) external payable;
    function inventoryNftDeposit(uint256[] calldata tokenIds, uint256[] calldata amounts) external payable;
    function inventoryPositionIncrease(uint256 amount) external payable;
    function claimYield(address recipient) external payable;

    function rescueERC20All(address token, address recipient) external payable;
    function rescueERC20(address token, uint256 amount, address recipient) external payable;
    function rescueERC721(address token, uint256 tokenId, address recipient) external payable;
    function rescueERC1155All(address token, uint256 tokenId, address recipient) external payable;
    function rescueERC1155(address token, uint256 tokenId, uint256 amount, address recipient) external payable;
    function rescueERC1155BatchAll(address token, uint256[] calldata tokenIds, address recipient) external payable;
    function rescueERC1155Batch(address token, uint256[] calldata tokenIds, uint256[] calldata amounts, address recipient) external payable;

    function wrapEth() external payable;
    function onERC721Received(address, address, uint256 _tokenId, bytes calldata) external returns (bytes4 magicBytes);
    function onERC1155Received(
        address,
        address,
        uint256 tokenId,
        uint256 amount,
        bytes memory
    ) external returns (bytes4);
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory
    ) external returns (bytes4);
}