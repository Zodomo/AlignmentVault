// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

interface IAlignmentVault {
    error AV_ERC721();
    error AV_ERC1155();
    error AV_NoPosition();
    error AV_UnalignedNft();
    error AV_PositionExists();
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

    function getNftInventory() external view returns (uint256[] memory tokenIds);
    function getNftInventoryAmounts() external view returns (uint256[] memory tokenIds, uint256[] memory amounts);
    function updateNftInventory(uint256[] calldata tokenIds) external;

    function getChildInventoryPositionIds() external view returns (uint256[] memory childPositionIds);
    function getSpecificInventoryPositionFees(uint256 positionId_) external view returns (uint256 balance);
    function getTotalInventoryPositionFees() external view returns (uint256 balance);

    function inventoryVTokenDeposit(uint256 vTokenAmount) external payable;
    function inventoryNftDeposit(uint256[] calldata tokenIds, uint256[] calldata amounts) external payable;
    function inventoryPositionIncrease(uint256 vTokenAmount) external payable;
    function inventoryPositionWithdrawal(uint256 positionId_, uint256 vTokenAmount, uint256[] calldata tokenIds, uint256 vTokenPremiumLimit) external payable;
    function inventoryCombinePositions(uint256[] calldata childPositionIds) external payable;
    function inventoryPositionCollectFees(uint256[] calldata positionIds) external payable;
    function inventoryPositionCollectAllFees() external payable;
    function liquidityPositionCreate(uint256 vTokenAmount, uint256 ethAmount, uint256[] calldata tokenIds, uint256[] calldata amounts) external payable;
    function liquidityPositionIncrease(uint256 vTokenAmount, uint256 ethAmount, uint256[] calldata tokenIds, uint256[] calldata amounts) external payable;
    function liquidityPositionCollectFees() external;

    function rescueERC20(address token, uint256 amount, address recipient) external payable;
    function rescueERC721(address token, uint256 tokenId, address recipient) external payable;
    function rescueERC1155(address token, uint256 tokenId, uint256 amount, address recipient) external payable;
    function rescueERC1155Batch(address token, uint256[] calldata tokenIds, uint256[] calldata amounts, address recipient) external payable;

    function unwrapEth() external;
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