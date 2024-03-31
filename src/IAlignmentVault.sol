// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

interface IAlignmentVault {
    error AV_UnalignedNft();
    error AV_ProhibitedWithdrawal();

    error AV_NFTX_NoVaultsExist();
    error AV_NFTX_InvalidVaultId();
    error AV_NFTX_InvalidVaultNft();
    error AV_NFTX_NoStandardVault();

    event AV_VaultInitialized(address indexed vault, uint256 indexed vaultId);
    event AV_NftsPurchased(uint256 indexed ethAmount, uint256[] indexed tokenIds);
    event AV_MintVTokens(uint256[] indexed tokenIds, uint256[] indexed amounts);

    event AV_InventoryPositionCreated(uint256 indexed positionId, uint256 indexed vTokenAmount);
    event AV_InventoryPositionIncreased(uint256 indexed positionId, uint256 indexed vTokenAmount);
    event AV_InventoryPositionWithdrawal(uint256 indexed positionId, uint256 indexed vTokenAmount);
    event AV_InventoryPositionCombination(uint256 indexed positionId, uint256[] indexed childPositionIds);
    event AV_InventoryPositionsCollected(uint256[] indexed positionIds);

    event AV_LiquidityPositionCreated(uint256 indexed positionId);
    event AV_LiquidityPositionIncreased(uint256 indexed positionId);
    event AV_LiquidityPositionWithdrawal(uint256 indexed positionId);
    event AV_LiquidityPositionsCollected(uint256[] indexed positionIds);

    function vaultId() external view returns (uint256);
    function vault() external view returns (address);
    function alignedNft() external view returns (address);
    function is1155() external view returns (bool);

    function getInventoryPositionIds() external view returns (uint256[] memory positionIds);
    function getLiquidityPositionIds() external view returns (uint256[] memory positionIds);
    function getSpecificInventoryPositionFees(uint256 positionId) external view returns (uint256 balance);
    function getTotalInventoryPositionFees() external view returns (uint256 balance);
    function getSpecificLiquidityPositionFees(uint256 positionId) external view returns (uint128 token0Fees, uint128 token1Fees);
    function getTotalLiquidityPositionFees() external view returns (uint128 token0Fees, uint128 token1Fees);

    function inventoryPositionCreateVToken(uint256 vTokenAmount) external payable;
    function inventoryPositionCreateNfts(uint256[] calldata tokenIds, uint256[] calldata amounts) external payable;
    function inventoryPositionIncrease(uint256 positionId, uint256 vTokenAmount) external payable;
    function inventoryPositionWithdrawal(uint256 positionId_, uint256 vTokenAmount, uint256[] calldata tokenIds, uint256 vTokenPremiumLimit) external payable;
    function inventoryCombinePositions(uint256 positionId, uint256[] calldata childPositionIds) external payable;
    function inventoryPositionCollectFees(uint256[] calldata positionIds) external payable;
    function inventoryPositionCollectAllFees() external payable;

    function liquidityPositionCreate(uint256 ethAmount, uint256 vTokenAmount, uint256[] calldata tokenIds, uint256[] calldata amounts, int24 tickLower, int24 tickUpper, uint24 fee, uint160 sqrtPriceX96, uint16 slippage) external payable;
    function liquidityPositionIncrease(uint256 positionId, uint256 ethAmount, uint256 vTokenAmount, uint256[] calldata tokenIds, uint256[] calldata amounts, uint16 slippage) external payable;
    function liquidityPositionCollectFees(uint256[] calldata positionIds) external payable;
    function liquidityPositionCollectAllFees() external payable;

    function buyNftsFromPool(uint256 ethAmount, uint256[] calldata tokenIds, uint256 vTokenPremiumLimit, uint24 fee, uint160 sqrtPriceLimitX96) external payable;
    function mintVToken(uint256 ethAmount, uint256[] calldata tokenIds, uint256[] calldata amounts) external payable;

    function rescueERC20(address token, uint256 amount, address recipient) external payable;
    function rescueERC721(address token, uint256 tokenId, address recipient) external payable;
    function rescueERC1155(address token, uint256 tokenId, uint256 amount, address recipient) external payable;
    function rescueERC1155Batch(address token, uint256[] calldata tokenIds, uint256[] calldata amounts, address recipient) external payable;
    function unwrapEth() external payable;

    function onERC721Received(address, address, uint256, bytes memory) external returns (bytes4);
    function onERC1155Received(address, address, uint256, uint256, bytes memory) external returns (bytes4);
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) external returns (bytes4);
}