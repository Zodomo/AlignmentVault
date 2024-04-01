// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

/**
 * @title IAlignmentVault
 * @notice This interface defines methods for managing an alignment vault, which is used for permanently deepening the floor liquidity of a target NFT collection. 
 * While the liquidity is locked forever, the yield can be claimed indefinitely.
 * @dev This interface must be initialized after deployment. Use the provided factory for initialization.
 * @author Zodomo.eth (Farcaster/Telegram/Discord/Github: @zodomo, X: @0xZodomo, Email: zodomo@proton.me)
 * @custom:github https://github.com/Zodomo/AlignmentVault
 * @custom:miyamaker https://miyamaker.com
 */
interface IAlignmentVault {
    // >>>>>>>>>>>> [ GENERAL ERRORS ] <<<<<<<<<<<<
    
    // Error thrown when attempting to interact with an unaligned NFT.
    error AV_UnalignedNft();
    // Error thrown when an invalid position is encountered.
    error AV_InvalidPosition();
    // Error thrown when a transaction fails.
    error AV_TransactionFailed();
    // Error thrown when a prohibited withdrawal is attempted.
    error AV_ProhibitedWithdrawal();

    // >>>>>>>>>>>> [ INITIALIZER ERRORS ] <<<<<<<<<<<<

    // Error thrown when no NFTX vaults exist.
    error AV_NFTX_NoVaultsExist();
    // Error thrown when an invalid NFTX vault ID is encountered.
    error AV_NFTX_InvalidVaultId();
    // Error thrown when an invalid NFTX vault NFT is encountered.
    error AV_NFTX_InvalidVaultNft();
    // Error thrown when no standard NFTX vault is found.
    error AV_NFTX_NoStandardVault();

    // >>>>>>>>>>>> [ GENERAL EVENTS ] <<<<<<<<<<<<

    // Event emitted when a vault is initialized.
    event AV_VaultInitialized(address indexed vault, uint256 indexed vaultId);
    // Event emitted when NFTs are purchased.
    event AV_NftsPurchased(uint256 indexed ethAmount, uint256[] indexed tokenIds);
    // Event emitted when vTokens are minted.
    event AV_MintVTokens(uint256[] indexed tokenIds, uint256[] indexed amounts);

    // >>>>>>>>>>>> [ INVENTORY MANAGEMENT EVENTS ] <<<<<<<<<<<<

    // Event emitted when an inventory position is created.
    event AV_InventoryPositionCreated(uint256 indexed positionId, uint256 indexed vTokenAmount);
    // Event emitted when an inventory position is increased.
    event AV_InventoryPositionIncreased(uint256 indexed positionId, uint256 indexed vTokenAmount);
    // Event emitted when an inventory position withdrawal occurs.
    event AV_InventoryPositionWithdrawal(uint256 indexed positionId, uint256 indexed vTokenAmount);
    // Event emitted when inventory positions are combined.
    event AV_InventoryPositionCombination(uint256 indexed positionId, uint256[] indexed childPositionIds);
    // Event emitted when inventory positions are collected.
    event AV_InventoryPositionsCollected(uint256[] indexed positionIds);

    // >>>>>>>>>>>> [ LIQUIDITY MANAGEMENT EVENTS ] <<<<<<<<<<<<

    // Event emitted when a liquidity position is created.
    event AV_LiquidityPositionCreated(uint256 indexed positionId);
    // Event emitted when a liquidity position is increased.
    event AV_LiquidityPositionIncreased(uint256 indexed positionId);
    // Event emitted when a liquidity position withdrawal occurs.
    event AV_LiquidityPositionWithdrawal(uint256 indexed positionId);
    // Event emitted when liquidity positions are combined.
    event AV_LiquidityPositionCombination(uint256 indexed positionId, uint256[] indexed childPositionIds);
    // Event emitted when liquidity positions are collected.
    event AV_LiquidityPositionsCollected(uint256[] indexed positionIds);

    // >>>>>>>>>>>> [ PUBLIC STORAGE ] <<<<<<<<<<<<

    // Returns the ID of the vault.
    function vaultId() external view returns (uint256);
    // Returns the address of the vault.
    function vault() external view returns (address);
    // Returns the address of the aligned NFT.
    function alignedNft() external view returns (address);
    // Checks if the NFT is ERC1155.
    function is1155() external view returns (bool);

    // >>>>>>>>>>>> [ VIEW FUNCTIONS ] <<<<<<<<<<<<

    // Returns an array of inventory position IDs.
    function getInventoryPositionIds() external view returns (uint256[] memory positionIds);
    // Returns an array of liquidity position IDs.
    function getLiquidityPositionIds() external view returns (uint256[] memory positionIds);
    // Returns the fee balance of a specific inventory position.
    function getSpecificInventoryPositionFees(uint256 positionId) external view returns (uint256 balance);
    // Returns the total fee balance of all inventory positions.
    function getTotalInventoryPositionFees() external view returns (uint256 balance);
    // Returns the fee balance of a specific liquidity position.
    function getSpecificLiquidityPositionFees(uint256 positionId) external view returns (uint128 token0Fees, uint128 token1Fees);
    // Returns the total fee balance of all liquidity positions.
    function getTotalLiquidityPositionFees() external view returns (uint128 token0Fees, uint128 token1Fees);

    // >>>>>>>>>>>> [ EXTERNAL DONATION MANAGEMENT ] <<<<<<<<<<<<

    // Increases the inventory position with a donation.
    function donateInventoryPositionIncrease(uint256 positionId, uint256 vTokenAmount) external payable;
    // Combines multiple inventory positions with a donation.
    function donateInventoryCombinePositions(uint256 positionId, uint256[] calldata childPositionIds) external payable;
    // Increases the liquidity position with a donation.
    function donateLiquidityPositionIncrease(uint256 positionId, uint256 vTokenAmount, uint256[] calldata tokenIds, uint256[] calldata amounts, uint24 slippage) external payable;
    // Combines multiple liquidity positions with a donation.
    function donateLiquidityCombinePositions(uint256 positionId, uint256[] calldata childPositionIds) external payable;
    // Buys NFTs from the pool with a donation.
    function donateBuyNftsFromPool(uint256[] calldata tokenIds, uint256 vTokenPremiumLimit, uint24 fee, uint160 sqrtPriceLimitX96) external payable;
    // Mints vTokens with a donation.
    function donateMintVToken(uint256[] calldata tokenIds, uint256[] calldata amounts) external payable;

    // >>>>>>>>>>>> [ INVENTORY POSITION MANAGEMENT ] <<<<<<<<<<<<

    // Creates vToken for an inventory position with a donation.
    function inventoryPositionCreateVToken(uint256 vTokenAmount) external payable returns (uint256 positionId);
    // Creates NFTs for an inventory position with a donation.
    function inventoryPositionCreateNfts(uint256[] calldata tokenIds, uint256[] calldata amounts) external payable returns (uint256 positionId);
    // Increases an inventory position with a donation.
    function inventoryPositionIncrease(uint256 positionId, uint256 vTokenAmount) external payable;
    // Withdraws from an inventory position with a donation.
    function inventoryPositionWithdrawal(uint256 positionId_, uint256 vTokenAmount, uint256[] calldata tokenIds, uint256 vTokenPremiumLimit) external payable;
    // Combines multiple inventory positions with a donation.
    function inventoryPositionCombine(uint256 positionId, uint256[] calldata childPositionIds) external payable;
    // Collects fees from inventory positions with a donation.
    function inventoryPositionCollectFees(uint256[] calldata positionIds) external payable;
    // Collects fees from all inventory positions with a donation.
    function inventoryPositionCollectAllFees() external payable;

    // >>>>>>>>>>>> [ LIQUIDITY POSITION MANAGEMENT ] <<<<<<<<<<<<

    // Creates a liquidity position with a donation.
    function liquidityPositionCreate(uint256 ethAmount, uint256 vTokenAmount, uint256[] calldata tokenIds, uint256[] calldata amounts, int24 tickLower, int24 tickUpper, uint160 sqrtPriceX96) external payable returns (uint256 positionId);
    // Increases a liquidity position with a donation.
    function liquidityPositionIncrease(uint256 positionId, uint256 ethAmount, uint256 vTokenAmount, uint256[] calldata tokenIds, uint256[] calldata amounts) external payable;
    // Withdraws from a liquidity position with a donation.
    function liquidityPositionWithdrawal(uint256 positionId, uint256[] calldata tokenIds, uint256 vTokenPremiumLimit, uint128 liquidity) external payable;
    // Combines multiple liquidity positions with a donation.
    function liquidityPositionCombine(uint256 positionId, uint256[] calldata childPositionIds) external payable;
    // Collects fees from liquidity positions with a donation.
    function liquidityPositionCollectFees(uint256[] calldata positionIds) external payable;
    // Collects fees from all liquidity positions with a donation.
    function liquidityPositionCollectAllFees() external payable;

    // >>>>>>>>>>>> [ ALIGNED TOKEN MANAGEMENT ] <<<<<<<<<<<<

    // Buys NFTs from the pool with a donation.
    function buyNftsFromPool(uint256 ethAmount, uint256[] calldata tokenIds, uint256 vTokenPremiumLimit, uint24 fee, uint160 sqrtPriceLimitX96) external payable;
    // Mints vTokens with a donation.
    function mintVToken(uint256[] calldata tokenIds, uint256[] calldata amounts) external payable;
    // Buys vToken with a donation.
    function buyVToken(uint256 ethAmount, uint24 fee, uint24 slippage, uint160 sqrtPriceLimitX96) external payable;
    // Buys exact vToken with a donation.
    function buyVTokenExact(uint256 ethAmount, uint256 vTokenAmount, uint24 fee, uint160 sqrtPriceLimitX96) external payable;
    // Sells vToken with a donation.
    function sellVToken(uint256 vTokenAmount, uint24 fee, uint24 slippage, uint160 sqrtPriceLimitX96) external payable;
    // Sells exact vToken with a donation.
    function sellVTokenExact(uint256 vTokenAmount, uint256 ethAmount, uint24 fee, uint160 sqrtPriceLimitX96) external payable;

    // >>>>>>>>>>>> [ MISCELLANEOUS TOKEN MANAGEMENT ] <<<<<<<<<<<<

    // Recovers ERC20 tokens with a donation.
    function rescueERC20(address token, uint256 amount, address recipient) external payable;
    // Recovers ERC721 tokens with a donation.
    function rescueERC721(address token, uint256 tokenId, address recipient) external payable;
    // Recovers ERC1155 tokens with a donation.
    function rescueERC1155(address token, uint256 tokenId, uint256 amount, address recipient) external payable;
    // Recovers batch of ERC1155 tokens with a donation.
    function rescueERC1155Batch(address token, uint256[] calldata tokenIds, uint256[] calldata amounts, address recipient) external payable;
    // Unwraps ETH with a donation.
    function unwrapEth() external payable;

    // >>>>>>>>>>>> [ RECEIVE LOGIC ] <<<<<<<<<<<<

    // ERC721 token receive function.
    function onERC721Received(address, address, uint256, bytes memory) external returns (bytes4);
    // ERC1155 token receive function.
    function onERC1155Received(address, address, uint256, uint256, bytes memory) external returns (bytes4);
    // ERC1155 batch token receive function.
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) external returns (bytes4);
}
