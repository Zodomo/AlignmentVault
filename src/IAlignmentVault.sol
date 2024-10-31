// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

/**
 * @title IAlignmentVault
 * @notice This allows anything to send ETH to a vault for the purpose of permanently deepening the floor liquidity of a target NFT collection.
 * While the liquidity is locked forever, the yield can be claimed indefinitely.
 * @dev You must initialize this contract once deployed! There is a factory for this, use it!
 * @author Zodomo.eth (Farcaster/Telegram/Discord/Github: @zodomo, X: @0xZodomo, Email: zodomo@proton.me)
 * @custom:github https://github.com/Zodomo/AlignmentVault
 * @custom:miyamaker https://miyamaker.com
 */
interface IAlignmentVault {
    // >>>>>>>>>>>> [ GENERAL ERRORS ] <<<<<<<<<<<<

    error AV_UnalignedNft();
    error AV_ProhibitedWithdrawal();

    // >>>>>>>>>>>> [ INITIALIZER ERRORS ] <<<<<<<<<<<<

    error AV_NFTX_NoVaultsExist();
    error AV_NFTX_InvalidVaultId();
    error AV_NFTX_InvalidVaultNft();
    error AV_NFTX_NoStandardVault();

    // >>>>>>>>>>>> [ GENERAL EVENTS ] <<<<<<<<<<<<

    event AV_VaultInitialized(address indexed vault, uint256 indexed vaultId);
    event AV_NftsPurchased(uint256 indexed ethAmount, uint256[] indexed tokenIds);
    event AV_MintVTokens(uint256[] indexed tokenIds, uint256[] indexed amounts);
    event AV_DelegateSet(address indexed oldDelegate, address indexed newDelegate);

    // >>>>>>>>>>>> [ INVENTORY MANAGEMENT EVENTS ] <<<<<<<<<<<<

    event AV_InventoryPositionCreated(uint256 indexed positionId, uint256 indexed vTokenAmount);
    event AV_InventoryPositionIncreased(uint256 indexed positionId, uint256 indexed vTokenAmount);
    event AV_InventoryPositionWithdrawal(uint256 indexed positionId, uint256 indexed vTokenAmount);
    event AV_InventoryPositionCombination(uint256 indexed positionId, uint256[] indexed childPositionIds);
    event AV_InventoryPositionsCollected(uint256[] indexed positionIds, uint256 indexed amount);

    // >>>>>>>>>>>> [ LIQUIDITY MANAGEMENT EVENTS ] <<<<<<<<<<<<

    event AV_LiquidityPositionCreated(uint256 indexed positionId);
    event AV_LiquidityPositionIncreased(uint256 indexed positionId);
    event AV_LiquidityPositionWithdrawal(uint256 indexed positionId);
    event AV_LiquidityPositionsCollected(uint256[] indexed positionIds);

    // >>>>>>>>>>>> [ STRUCTS ] <<<<<<<<<<<<

    struct PositionData {
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        uint128 token0Fees;
        uint128 token1Fees;
    }

    // >>>>>>>>>>>> [ PUBLIC STORAGE ] <<<<<<<<<<<<

    function vaultId() external view returns (uint96);
    function vault() external view returns (address);
    function delegate() external view returns (address);
    function alignedNft() external view returns (address);
    function is1155() external view returns (bool);

    // >>>>>>>>>>>> [ INITIALIZER ] <<<<<<<<<<<<

    function initialize(address owner_, address alignedNft_, uint96 vaultId_) external payable;

    // >>>>>>>>>>>> [ MANAGEMENT FUNCTIONS ] <<<<<<<<<<<<

    function setDelegate(address newDelegate) external payable;

    // >>>>>>>>>>>> [ VIEW FUNCTIONS ] <<<<<<<<<<<<

    function getUniswapPoolValues() external view returns (address pool, uint160 sqrtPriceX96, int24 tick);
    function getInventoryPositionIds() external view returns (uint256[] memory positionIds);
    function getLiquidityPositionIds() external view returns (uint256[] memory positionIds);
    function getSpecificInventoryPositionFees(uint256 positionId) external view returns (uint256 balance);
    function getTotalInventoryPositionFees() external view returns (uint256 balance);
    function getSpecificLiquidityPositionFees(uint256 positionId)
        external
        view
        returns (uint128 token0Fees, uint128 token1Fees);
    function getTotalLiquidityPositionFees() external view returns (uint128 token0Fees, uint128 token1Fees);

    // >>>>>>>>>>>> [ INVENTORY POSITION MANAGEMENT ] <<<<<<<<<<<<

    function inventoryPositionCreateVToken(uint256 vTokenAmount) external payable returns (uint256 positionId);
    function inventoryPositionCreateNfts(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external payable returns (uint256 positionId);
    function inventoryPositionIncrease(uint256 positionId, uint256 vTokenAmount) external payable;
    function inventoryPositionWithdrawal(
        uint256 positionId_,
        uint256 vTokenAmount,
        uint256[] calldata tokenIds,
        uint256 vTokenPremiumLimit
    ) external payable;
    function inventoryPositionCombine(uint256 positionId, uint256[] calldata childPositionIds) external payable;
    function inventoryPositionCollectFees(address recipient, uint256[] calldata positionIds) external payable;
    function inventoryPositionCollectAllFees(address recipient) external payable;

    // >>>>>>>>>>>> [ LIQUIDITY POSITION MANAGEMENT ] <<<<<<<<<<<<

    function liquidityPositionCreate(
        uint256 ethAmount,
        uint256 vTokenAmount,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        int24 tickLower,
        int24 tickUpper,
        uint160 sqrtPriceX96,
        uint256 ethMin,
        uint256 vTokenMin
    ) external payable returns (uint256 positionId);
    function liquidityPositionIncrease(
        uint256 positionId,
        uint256 ethAmount,
        uint256 vTokenAmount,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256 ethMin,
        uint256 vTokenMin
    ) external payable;
    function liquidityPositionWithdrawal(
        uint256 positionId,
        uint256[] calldata tokenIds,
        uint256 vTokenPremiumLimit,
        uint128 liquidity,
        uint256 amount0Min,
        uint256 amount1Min
    ) external payable;
    function liquidityPositionCollectFees(address recipient, uint256[] calldata positionIds) external payable;
    function liquidityPositionCollectAllFees(address recipient) external payable;

    // >>>>>>>>>>>> [ ALIGNED TOKEN MANAGEMENT ] <<<<<<<<<<<<

    function buyNftsFromPool(
        uint256 ethAmount,
        uint256[] calldata tokenIds,
        uint256 vTokenPremiumLimit,
        uint24 fee,
        uint160 sqrtPriceLimitX96
    ) external payable;
    function mintVToken(uint256[] calldata tokenIds, uint256[] calldata amounts) external payable;
    function buyVToken(
        uint256 ethAmount,
        uint24 fee,
        uint256 amountOutMinimum,
        uint160 sqrtPriceLimitX96
    ) external payable;
    function buyVTokenExact(
        uint256 ethAmount,
        uint24 fee,
        uint256 amountOutExact,
        uint160 sqrtPriceLimitX96
    ) external payable;
    function sellVToken(
        uint256 vTokenAmount,
        uint24 fee,
        uint256 amountOutMinimum,
        uint160 sqrtPriceLimitX96
    ) external payable;
    function sellVTokenExact(
        uint256 vTokenAmount,
        uint24 fee,
        uint256 amountOutExact,
        uint160 sqrtPriceLimitX96
    ) external payable;

    // >>>>>>>>>>>> [ MISCELLANEOUS TOKEN MANAGEMENT ] <<<<<<<<<<<<

    function rescueERC20(address token, uint256 amount, address recipient) external payable;
    function rescueERC721(address token, uint256 tokenId, address recipient) external payable;
    function rescueERC1155(address token, uint256 tokenId, uint256 amount, address recipient) external payable;
    function rescueERC1155Batch(
        address token,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        address recipient
    ) external payable;
    function wrapEth(uint256 amount) external payable;
    function unwrapEth(uint256 amount) external payable;
}
