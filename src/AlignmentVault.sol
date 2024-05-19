// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

// >>>>>>>>>>>> [ IMPORTS ] <<<<<<<<<<<<

// Inheritance and Libraries
import {Ownable} from "../lib/solady/src/auth/Ownable.sol";
import {Initializable} from "../lib/solady/src/utils/Initializable.sol";
import {ERC721Holder} from "../lib/openzeppelin-contracts-v5/contracts/token/ERC721/utils/ERC721Holder.sol";
import {ERC1155Holder} from "../lib/openzeppelin-contracts-v5/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {IAlignmentVault} from "./IAlignmentVault.sol";
import {EnumerableSet} from "../lib/openzeppelin-contracts-v5/contracts/utils/structs/EnumerableSet.sol";
import {FixedPointMathLib} from "../lib/solady/src/utils/FixedPointMathLib.sol";
import {Tick} from "../lib/nftx-protocol-v3/src/uniswap/v3-core/libraries/Tick.sol";

// Interfaces
import {IWETH9} from "../lib/nftx-protocol-v3/src/uniswap/v3-periphery/interfaces/external/IWETH9.sol";
import {IERC20} from "../lib/openzeppelin-contracts-v5/contracts/interfaces/IERC20.sol";
import {IERC721} from "../lib/openzeppelin-contracts-v5/contracts/interfaces/IERC721.sol";
import {IERC1155} from "../lib/openzeppelin-contracts-v5/contracts/interfaces/IERC1155.sol";
import {INFTXVaultFactoryV3} from "../lib/nftx-protocol-v3/src/interfaces/INFTXVaultFactoryV3.sol";
import {INFTXVaultV3} from "../lib/nftx-protocol-v3/src/interfaces/INFTXVaultV3.sol";
import {INFTXInventoryStakingV3} from "../lib/nftx-protocol-v3/src/interfaces/INFTXInventoryStakingV3.sol";
import {INonfungiblePositionManager} from
    "../lib/nftx-protocol-v3/src/uniswap/v3-periphery/interfaces/INonfungiblePositionManager.sol";
import {INFTXRouter} from "../lib/nftx-protocol-v3/src/interfaces/INFTXRouter.sol";
import {ISwapRouter} from "../lib/nftx-protocol-v3/src/uniswap/v3-periphery/interfaces/ISwapRouter.sol";
import {IUniswapV3Pool} from "../lib/nftx-protocol-v3/src/uniswap/v3-core/interfaces/IUniswapV3Pool.sol";
import {IDelegateRegistry} from "../lib/delegate-registry/src/IDelegateRegistry.sol";

// Temporary
import {console2} from "../lib/forge-std/src/console2.sol";

interface IUniswapPool {
    function ticks(int24 tick) external view returns (Tick.Info memory);
}

/**
 * @title AlignmentVault
 * @notice This allows anything to send ETH to a vault for the purpose of permanently deepening the floor liquidity of a target NFT collection.
 * While the liquidity is locked forever, the yield can be claimed indefinitely.
 * @dev You must initialize this contract once deployed! There is a factory for this, use it!
 * @author Zodomo.eth (Farcaster/Telegram/Discord/Github: @zodomo, X: @0xZodomo, Email: zodomo@proton.me)
 * @custom:github https://github.com/Zodomo/AlignmentVault
 * @custom:miyamaker https://miyamaker.com
 */
contract AlignmentVault is Ownable, Initializable, ERC721Holder, ERC1155Holder, IAlignmentVault {
    using EnumerableSet for EnumerableSet.UintSet;

    // >>>>>>>>>>>> [ CONSTANTS ] <<<<<<<<<<<<

    uint256 private constant _NFTX_STANDARD_FEE = 30_000_000_000_000_000;
    uint256 private constant _DENOMINATOR = 1_000_000;
    uint24 private constant _POOL_FEE = 3000;
    int24 private constant _MIN_TICK = -887272;
    int24 private constant _MAX_TICK = -_MIN_TICK;
    uint256 private constant _Q128 = 0x100000000000000000000000000000000;

    // >>>>>>>>>>>> [ CONTRACT INTERFACES ] <<<<<<<<<<<<

    IWETH9 private constant _WETH = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    INFTXVaultFactoryV3 private constant _NFTX_VAULT_FACTORY =
        INFTXVaultFactoryV3(0xC255335bc5aBd6928063F5788a5E420554858f01);
    INFTXInventoryStakingV3 private constant _NFTX_INVENTORY =
        INFTXInventoryStakingV3(0x889f313e2a3FDC1c9a45bC6020A8a18749CD6152);
    INonfungiblePositionManager private constant _NFTX_LIQUIDITY =
        INonfungiblePositionManager(0x26387fcA3692FCac1C1e8E4E2B22A6CF0d4b71bF);
    INFTXRouter private constant _NFTX_POSITION_ROUTER = INFTXRouter(0x70A741A12262d4b5Ff45C0179c783a380EebE42a);
    ISwapRouter private constant _NFTX_SWAP_ROUTER = ISwapRouter(0x1703f8111B0E7A10e1d14f9073F53680d64277A3);
    IDelegateRegistry private constant _DELEGATE_REGISTRY =
        IDelegateRegistry(0x00000000000000447e69651d841bD8D104Bed493);

    // >>>>>>>>>>>> [ PRIVATE STORAGE ] <<<<<<<<<<<<

    EnumerableSet.UintSet private _inventoryPositionIds;
    EnumerableSet.UintSet private _liquidityPositionIds;

    // >>>>>>>>>>>> [ PUBLIC STORAGE ] <<<<<<<<<<<<

    uint96 public vaultId;
    address public vault;
    address public delegate;
    address public alignedNft;
    bool public is1155;

    // >>>>>>>>>>>> [ CONSTRUCTOR / INITIALIZER FUNCTIONS ] <<<<<<<<<<<<

    constructor() payable {}

    function initialize(address owner_, address alignedNft_, uint96 vaultId_) public payable virtual initializer {
        _initializeOwner(owner_);
        alignedNft = alignedNft_;
        if (vaultId_ != 0) {
            try _NFTX_VAULT_FACTORY.vault(vaultId_) returns (address vaultAddr) {
                if (INFTXVaultV3(vaultAddr).assetAddress() != alignedNft_) revert AV_NFTX_InvalidVaultNft();
                if (INFTXVaultV3(vaultAddr).is1155()) is1155 = true;
                vaultId = vaultId_;
                vault = vaultAddr;
                emit AV_VaultInitialized(vaultAddr, vaultId_);
            } catch {
                revert AV_NFTX_InvalidVaultId();
            }
        } else {
            address[] memory vaults = _NFTX_VAULT_FACTORY.vaultsForAsset(alignedNft_);
            if (vaults.length == 0) revert AV_NFTX_NoVaultsExist();
            for (uint256 i; i < vaults.length; ++i) {
                (uint256 mintFee, uint256 redeemFee, uint256 swapFee) = INFTXVaultV3(vaults[i]).vaultFees();
                if (mintFee != _NFTX_STANDARD_FEE || redeemFee != _NFTX_STANDARD_FEE || swapFee != _NFTX_STANDARD_FEE) {
                    continue;
                } else if (INFTXVaultV3(vaults[i]).manager() != address(0)) {
                    continue;
                } else {
                    if (INFTXVaultV3(vaults[i]).is1155()) is1155 = true;
                    vaultId_ = uint96(INFTXVaultV3(vaults[i]).vaultId());
                    vaultId = vaultId_;
                    vault = vaults[i];
                    emit AV_VaultInitialized(vaults[i], vaultId_);
                    break;
                }
            }
            if (vaultId_ == 0) revert AV_NFTX_NoStandardVault();
        }

        IERC721(alignedNft_).setApprovalForAll(address(_NFTX_INVENTORY), true);
        IERC721(alignedNft_).setApprovalForAll(address(_NFTX_POSITION_ROUTER), true);
        IERC721(alignedNft_).setApprovalForAll(address(_NFTX_LIQUIDITY), true);
        IERC721(alignedNft_).setApprovalForAll(vault, true);
 
        IERC20(vault).approve(address(_NFTX_INVENTORY), type(uint256).max);
        IERC20(vault).approve(address(_NFTX_POSITION_ROUTER), type(uint256).max);
        IERC20(vault).approve(address(_NFTX_LIQUIDITY), type(uint256).max);
        IERC20(vault).approve(address(_NFTX_SWAP_ROUTER), type(uint256).max);
        _WETH.approve(address(_NFTX_SWAP_ROUTER), type(uint256).max);
    }

    function disableInitializers() external payable virtual {
        _disableInitializers();
    }

    // >>>>>>>>>>>> [ MANAGEMENT FUNCTIONS ] <<<<<<<<<<<<

    function renounceOwnership() public payable virtual override(Ownable) onlyOwner {}

    function setDelegate(address newDelegate) external payable virtual onlyOwner {
        address _delegate = delegate;
        if (_delegate != address(0)) _DELEGATE_REGISTRY.delegateAll(_delegate, "", false);
        _DELEGATE_REGISTRY.delegateAll(newDelegate, "", true);
        emit AV_DelegateSet(_delegate, newDelegate);
    }

    // >>>>>>>>>>>> [ PRIVATE FUNCTIONS ] <<<<<<<<<<<<

    function _countTokens(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) private pure returns (uint256 totalCount) {
        for (uint256 i; i < tokenIds.length; ++i) {
            unchecked {
                totalCount += amounts[i];
            }
        }
    }

    function _getFeeGrowthInside(
        Tick.Info memory lower,
        Tick.Info memory upper,
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128
    ) private pure returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) {
        unchecked {
            // calculate fee growth below
            uint256 feeGrowthBelow0X128;
            uint256 feeGrowthBelow1X128;
            if (tickCurrent >= tickLower) {
                feeGrowthBelow0X128 = lower.feeGrowthOutside0X128;
                feeGrowthBelow1X128 = lower.feeGrowthOutside1X128;
            } else {
                feeGrowthBelow0X128 = feeGrowthGlobal0X128 - lower.feeGrowthOutside0X128;
                feeGrowthBelow1X128 = feeGrowthGlobal1X128 - lower.feeGrowthOutside1X128;
            }

            // calculate fee growth above
            uint256 feeGrowthAbove0X128;
            uint256 feeGrowthAbove1X128;
            if (tickCurrent < tickUpper) {
                feeGrowthAbove0X128 = upper.feeGrowthOutside0X128;
                feeGrowthAbove1X128 = upper.feeGrowthOutside1X128;
            } else {
                feeGrowthAbove0X128 = feeGrowthGlobal0X128 - upper.feeGrowthOutside0X128;
                feeGrowthAbove1X128 = feeGrowthGlobal1X128 - upper.feeGrowthOutside1X128;
            }

            feeGrowthInside0X128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
            feeGrowthInside1X128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;
        }
    }

    function _getLiquidityPositionFees(
        uint256 id,
        IUniswapPool pool,
        int24 tick, 
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128
    ) private view returns (uint128 , uint128 ) {
        PositionData memory position;
        (
            ,,,,,
            position.tickLower,
            position.tickUpper,
            position.liquidity,
            position.feeGrowthInside0LastX128,
            position.feeGrowthInside1LastX128,
            position.token0Fees,
            position.token1Fees
        ) = _NFTX_LIQUIDITY.positions(id);

        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = _getFeeGrowthInside(
            pool.ticks(position.tickLower),
            pool.ticks(position.tickUpper),
            position.tickLower,
            position.tickUpper,
            tick,
            feeGrowthGlobal0X128,
            feeGrowthGlobal1X128
        );

        position.token0Fees += uint128((feeGrowthInside0X128 - position.feeGrowthInside0LastX128) * position.liquidity / _Q128);
        position.token1Fees += uint128((feeGrowthInside1X128 - position.feeGrowthInside1LastX128) * position.liquidity / _Q128);

        return (position.token0Fees, position.token1Fees);
    }

    function _getPool() private view returns (address pool) {
        pool = _NFTX_POSITION_ROUTER.getPool(vault, _POOL_FEE);
    }

    function _buildAddLiquidityParams(
        uint256 vTokenAmount,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        int24 tickLower,
        int24 tickUpper,
        uint256 ethMin,
        uint256 vTokenMin,
        uint160 sqrtPriceX96
    ) internal view returns (INFTXRouter.AddLiquidityParams memory params) {
        (tickLower, tickUpper) = _formatTicks(tickLower, tickUpper);

        params = INFTXRouter.AddLiquidityParams({
            vaultId: vaultId,
            vTokensAmount: vTokenAmount,
            nftIds: tokenIds,
            nftAmounts: amounts,
            tickLower: tickLower,
            tickUpper: tickUpper,
            fee: _POOL_FEE,
            sqrtPriceX96: sqrtPriceX96,
            vTokenMin: vTokenMin,
            wethMin: ethMin,
            deadline: block.timestamp,
            forceTimelock: true,
            recipient: address(this)
        });
    }

    function _buildIncreaseLiquidityParams(
        uint256 positionId,
        uint256 vTokenAmount,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256 ethMin,
        uint256 vTokenMin
    ) internal view returns (INFTXRouter.IncreaseLiquidityParams memory params) {
        params = INFTXRouter.IncreaseLiquidityParams({
            positionId: positionId,
            vaultId: vaultId,
            vTokensAmount: vTokenAmount,
            nftIds: tokenIds,
            nftAmounts: amounts,
            vTokenMin: vTokenMin,
            wethMin: ethMin,
            deadline: block.timestamp,
            forceTimelock: true
        });
    }

    function _buildRemoveLiquidityParams(
        uint256 positionId,
        uint256[] memory tokenIds,
        uint256 vTokenPremiumLimit,
        uint128 liquidity,
        uint256 amount0Min,
        uint256 amount1Min
    ) internal view returns (INFTXRouter.RemoveLiquidityParams memory params) {
        params = INFTXRouter.RemoveLiquidityParams({
            positionId: positionId,
            vaultId: vaultId,
            nftIds: tokenIds,
            vTokenPremiumLimit: vTokenPremiumLimit,
            liquidity: liquidity,
            amount0Min: amount0Min,
            amount1Min: amount1Min,
            deadline: block.timestamp
        });
    }

    function _formatTicks(int24 tickLower, int24 tickUpper) internal view returns (int24, int24) {
        (tickLower, tickUpper) = tickLower < tickUpper ? (tickLower, tickUpper) : (tickUpper, tickLower);

        if (tickLower < _MIN_TICK) tickLower = _MIN_TICK;
        if (tickUpper > _MAX_TICK) tickUpper = _MAX_TICK;

        int24 tickSpacing = IUniswapV3Pool(_getPool()).tickSpacing();

        if (tickLower % tickSpacing != 0) tickLower -= (tickLower % tickSpacing);
        if (tickUpper % tickSpacing != 0) tickUpper -= (tickUpper % tickSpacing);

        return (tickLower, tickUpper);
    }

    // >>>>>>>>>>>> [ VIEW FUNCTIONS ] <<<<<<<<<<<<

    function getUniswapPoolValues() external view returns (address pool, uint160 sqrtPriceX96, int24 tick) {
        pool = _getPool();
        (sqrtPriceX96, tick,,,,,) = IUniswapV3Pool(pool).slot0();
    }

    function getInventoryPositionIds() external view virtual returns (uint256[] memory positionIds) {
        positionIds = _inventoryPositionIds.values();
    }

    function getLiquidityPositionIds() external view virtual returns (uint256[] memory positionIds) {
        positionIds = _liquidityPositionIds.values();
    }

    function getSpecificInventoryPositionFees(uint256 positionId) external view virtual returns (uint256 balance) {
        balance = _NFTX_INVENTORY.wethBalance(positionId);
    }

    function getTotalInventoryPositionFees() external view virtual returns (uint256 balance) {
        uint256[] memory positionIds = _inventoryPositionIds.values();
        for (uint256 i; i < positionIds.length; ++i) {
            unchecked {
                balance += _NFTX_INVENTORY.wethBalance(positionIds[i]);
            }
        }
    }

    function getSpecificLiquidityPositionFees(uint256 positionId)
        external
        view
        virtual
        returns (uint128 token0Fees, uint128 token1Fees)
    {
        IUniswapV3Pool pool = IUniswapV3Pool(_getPool());
        (, int24 currentTick,,,,,) = pool.slot0();
        uint256 feeGrowthGlobal0X128 = pool.feeGrowthGlobal0X128();
        uint256 feeGrowthGlobal1X128 = pool.feeGrowthGlobal1X128();

        return _getLiquidityPositionFees(
            positionId, IUniswapPool(address(pool)), currentTick, feeGrowthGlobal0X128, feeGrowthGlobal1X128
        );
    }

    function getTotalLiquidityPositionFees() external view virtual returns (uint128 token0Fees, uint128 token1Fees) {
        IUniswapV3Pool pool = IUniswapV3Pool(_getPool());
        (, int24 currentTick,,,,,) = pool.slot0();
        uint256 feeGrowthGlobal0X128 = pool.feeGrowthGlobal0X128();
        uint256 feeGrowthGlobal1X128 = pool.feeGrowthGlobal1X128();

        uint256[] memory positionIds = _liquidityPositionIds.values();
        uint256 length = positionIds.length;

        uint128 _token0Fees;
        uint128 _token1Fees;

        for (uint256 i; i < length; ++i) {
            unchecked {
                (_token0Fees, _token1Fees) = _getLiquidityPositionFees(
                    positionIds[i], IUniswapPool(address(pool)), currentTick, feeGrowthGlobal0X128, feeGrowthGlobal1X128
                );

                token0Fees += _token0Fees;
                token1Fees += _token1Fees;
            }
        }
    }

    // >>>>>>>>>>>> [ INVENTORY POSITION MANAGEMENT ] <<<<<<<<<<<<

    function inventoryPositionCreateVToken(uint256 vTokenAmount)
        external
        payable
        virtual
        onlyOwner
        returns (uint256 positionId)
    {
        positionId = _NFTX_INVENTORY.deposit(vaultId, vTokenAmount, address(this), "", false, true);
        _inventoryPositionIds.add(positionId);
        emit AV_InventoryPositionCreated(positionId, vTokenAmount);
    }

    function inventoryPositionCreateNfts(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external payable virtual onlyOwner returns (uint256 positionId) {
        positionId = _NFTX_INVENTORY.depositWithNFT(vaultId, tokenIds, amounts, address(this));
        _inventoryPositionIds.add(positionId);
        emit AV_InventoryPositionCreated(positionId, _countTokens(tokenIds, amounts) * 1 ether);
    }

    // Only works on inventory positions created with vTokens
    function inventoryPositionIncrease(uint256 positionId, uint256 vTokenAmount) external payable virtual onlyOwner {
        _NFTX_INVENTORY.increasePosition(positionId, vTokenAmount, "", false, true);
        emit AV_InventoryPositionIncreased(positionId, vTokenAmount);
    }

    // vTokenAmount must include `tokenIds.length * 1 ether` if any NFTs are to be withdrawn
    function inventoryPositionWithdrawal(
        uint256 positionId,
        uint256 vTokenAmount,
        uint256[] calldata tokenIds,
        uint256 vTokenPremiumLimit
    ) external payable virtual onlyOwner {
        if (vTokenPremiumLimit == 0) vTokenPremiumLimit = type(uint256).max;
        _NFTX_INVENTORY.withdraw(positionId, vTokenAmount, tokenIds, vTokenPremiumLimit);
        emit AV_InventoryPositionWithdrawal(positionId, vTokenAmount);
    }

    function inventoryPositionCombine(
        uint256 positionId,
        uint256[] calldata childPositionIds
    ) external payable virtual onlyOwner {
        _NFTX_INVENTORY.combinePositions(positionId, childPositionIds);
        emit AV_InventoryPositionCombination(positionId, childPositionIds);
    }

    function inventoryPositionCollectFees(address recipient, uint256[] calldata positionIds) external payable virtual onlyOwner {
        uint256 balance = _WETH.balanceOf(address(this));
        _NFTX_INVENTORY.collectWethFees(positionIds);
        uint256 difference = _WETH.balanceOf(address(this)) - balance;
        if (difference > 0) {
            _WETH.transfer(recipient, difference);
            emit AV_InventoryPositionsCollected(positionIds, difference);
        }
    }

    function inventoryPositionCollectAllFees(address recipient) external payable virtual onlyOwner {
        uint256 balance = _WETH.balanceOf(address(this));
        uint256[] memory positionIds = _inventoryPositionIds.values();
        _NFTX_INVENTORY.collectWethFees(positionIds);
        uint256 difference = _WETH.balanceOf(address(this)) - balance;
        if (difference > 0) {
            _WETH.transfer(recipient, difference);
            emit AV_InventoryPositionsCollected(positionIds, difference);
        }
    }

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
    ) external payable virtual onlyOwner returns (uint256 positionId) {
        (uint160 _sqrtPriceX96,,,,,,) = IUniswapV3Pool(_getPool()).slot0();
        if (sqrtPriceX96 == 0) sqrtPriceX96 = _sqrtPriceX96;
        positionId = _NFTX_POSITION_ROUTER.addLiquidity{value: ethAmount}(
            _buildAddLiquidityParams(
                vTokenAmount, tokenIds, amounts, tickLower, tickUpper, ethMin, vTokenMin, sqrtPriceX96
            )
        );
        _liquidityPositionIds.add(positionId);
        emit AV_LiquidityPositionCreated(positionId);
    }

    function liquidityPositionIncrease(
        uint256 positionId,
        uint256 ethAmount,
        uint256 vTokenAmount,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256 ethMin,
        uint256 vTokenMin
    ) external payable virtual onlyOwner {
        _NFTX_POSITION_ROUTER.increaseLiquidity{value: ethAmount}(
            _buildIncreaseLiquidityParams(positionId, vTokenAmount, tokenIds, amounts, ethMin, vTokenMin)
        );
        emit AV_LiquidityPositionIncreased(positionId);
    }

    function liquidityPositionWithdrawal(
        uint256 positionId,
        uint256[] calldata tokenIds,
        uint256 vTokenPremiumLimit,
        uint128 liquidity,
        uint256 amount0Min,
        uint256 amount1Min
    ) external payable virtual onlyOwner {
        if (vTokenPremiumLimit == 0) vTokenPremiumLimit = type(uint256).max;
        _NFTX_POSITION_ROUTER.removeLiquidity(
            _buildRemoveLiquidityParams(positionId, tokenIds, vTokenPremiumLimit, liquidity, amount0Min, amount1Min)
        );
        _WETH.withdraw(_WETH.balanceOf(address(this)));
        emit AV_LiquidityPositionWithdrawal(positionId);
    }

    // TODO: Test
    function liquidityPositionCollectFees(uint256[] calldata positionIds) external payable virtual onlyOwner {
        for (uint256 i; i < positionIds.length; ++i) {
            INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
                tokenId: positionIds[i],
                recipient: msg.sender,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });
            _NFTX_LIQUIDITY.collect(params);
        }
        emit AV_LiquidityPositionsCollected(positionIds);
    }

    function liquidityPositionCollectAllFees() external payable virtual onlyOwner {
        uint256[] memory positionIds = _liquidityPositionIds.values();
        for (uint256 i; i < positionIds.length; ++i) {
            INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
                tokenId: positionIds[i],
                recipient: msg.sender,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });
            _NFTX_LIQUIDITY.collect(params);
        }
        emit AV_LiquidityPositionsCollected(positionIds);
    }

    // >>>>>>>>>>>> [ ALIGNED TOKEN MANAGEMENT ] <<<<<<<<<<<<

    // TODO: Test
    function buyNftsFromPool(
        uint256 ethAmount,
        uint256[] calldata tokenIds,
        uint256 vTokenPremiumLimit,
        uint24 fee,
        uint160 sqrtPriceLimitX96
    ) external payable virtual onlyOwner {
        INFTXRouter.BuyNFTsParams memory params = INFTXRouter.BuyNFTsParams({
            vaultId: vaultId,
            nftIds: tokenIds,
            vTokenPremiumLimit: vTokenPremiumLimit,
            deadline: block.timestamp,
            fee: fee,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });
        uint256 balance = address(this).balance;
        _NFTX_POSITION_ROUTER.buyNFTs{value: ethAmount}(params);
        emit AV_NftsPurchased(balance - address(this).balance, tokenIds);
    }

    function mintVToken(uint256[] calldata tokenIds, uint256[] calldata amounts) external payable onlyOwner {
        uint256 ethRequired = FixedPointMathLib.fullMulDivUp(
            INFTXVaultV3(vault).vTokenToETH(_countTokens(tokenIds, amounts) * 1 ether), 30_000, _DENOMINATOR
        );
        INFTXVaultV3(vault).mint{value: ethRequired}(tokenIds, amounts, address(this), address(this));
        emit AV_MintVTokens(tokenIds, amounts);
    }

    function buyVToken(uint256 ethAmount, uint24 fee, uint256 amountOutMinimum, uint160 sqrtPriceLimitX96) external payable onlyOwner {
        uint256 wethBalance = _WETH.balanceOf(address(this));
        if (ethAmount > wethBalance) _WETH.deposit{value: ethAmount - wethBalance}();
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(_WETH),
            tokenOut: vault,
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: ethAmount,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });
        _NFTX_SWAP_ROUTER.exactInputSingle(params);
        _WETH.withdraw(_WETH.balanceOf(address(this)));
    }

    function buyVTokenExact(uint256 ethAmount, uint24 fee, uint256 amountOutExact, uint160 sqrtPriceLimitX96) external payable onlyOwner {
        uint256 wethBalance = _WETH.balanceOf(address(this));
        if (ethAmount > wethBalance) _WETH.deposit{value: ethAmount - wethBalance}();
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: address(_WETH),
            tokenOut: vault,
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountOut: amountOutExact,
            amountInMaximum: ethAmount,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });
        _NFTX_SWAP_ROUTER.exactOutputSingle(params);
        _WETH.withdraw(_WETH.balanceOf(address(this)));
    }

    function sellVToken(uint256 vTokenAmount, uint24 fee, uint256 amountOutMinimum, uint160 sqrtPriceLimitX96) external payable onlyOwner {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: vault,
            tokenOut: address(_WETH),
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: vTokenAmount,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });
        _NFTX_SWAP_ROUTER.exactInputSingle(params);
        _WETH.withdraw(_WETH.balanceOf(address(this)));
    }

    function sellVTokenExact(uint256 vTokenAmount, uint24 fee, uint256 amountOutExact, uint160 sqrtPriceLimitX96) external payable onlyOwner {
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: vault,
            tokenOut: address(_WETH),
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountOut: amountOutExact,
            amountInMaximum: vTokenAmount,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });
        _NFTX_SWAP_ROUTER.exactOutputSingle(params);
        _WETH.withdraw(_WETH.balanceOf(address(this)));
    }

    // >>>>>>>>>>>> [ MISCELLANEOUS TOKEN MANAGEMENT ] <<<<<<<<<<<<

    function rescueERC20(address token, uint256 amount, address recipient) external payable virtual onlyOwner {
        if (token == vault || token == address(_WETH)) revert AV_ProhibitedWithdrawal();
        IERC20(token).transfer(recipient, amount);
    }

    function rescueERC721(address token, uint256 tokenId, address recipient) external payable virtual onlyOwner {
        if (token == alignedNft || token == address(_NFTX_INVENTORY) || token == address(_NFTX_LIQUIDITY)) {
            revert AV_ProhibitedWithdrawal();
        }
        IERC721(token).transferFrom(address(this), recipient, tokenId);
    }

    function rescueERC1155(
        address token,
        uint256 tokenId,
        uint256 amount,
        address recipient
    ) external payable virtual onlyOwner {
        if (token == alignedNft) revert AV_ProhibitedWithdrawal();
        IERC1155(token).safeTransferFrom(address(this), recipient, tokenId, amount, "");
    }

    function rescueERC1155Batch(
        address token,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        address recipient
    ) external payable virtual onlyOwner {
        if (token == alignedNft) revert AV_ProhibitedWithdrawal();
        IERC1155(token).safeBatchTransferFrom(address(this), recipient, tokenIds, amounts, "");
    }

    function wrapEth(uint256 amount) external payable virtual onlyOwner {
        _WETH.deposit{value: amount}();
    }

    function unwrapEth(uint256 amount) external payable virtual onlyOwner {
        _WETH.withdraw(amount);
    }

    // >>>>>>>>>>>> [ RECEIVE LOGIC ] <<<<<<<<<<<<

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes memory
    ) public virtual override(ERC721Holder) returns (bytes4) {
        if (
            msg.sender != alignedNft && msg.sender != address(_NFTX_INVENTORY) && msg.sender != address(_NFTX_LIQUIDITY)
        ) {
            revert AV_UnalignedNft();
        }
        if (msg.sender == address(_NFTX_INVENTORY)) _inventoryPositionIds.add(tokenId);
        else if (msg.sender == address(_NFTX_LIQUIDITY)) _liquidityPositionIds.add(tokenId);
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override(ERC1155Holder) returns (bytes4) {
        if (msg.sender != alignedNft) revert AV_UnalignedNft();
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override(ERC1155Holder) returns (bytes4) {
        if (msg.sender != alignedNft) revert AV_UnalignedNft();
        return this.onERC1155BatchReceived.selector;
    }

    receive() external payable virtual {}
    fallback() external payable virtual {}
}
