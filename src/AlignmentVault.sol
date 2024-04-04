// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

// >>>>>>>>>>>> [ IMPORTS ] <<<<<<<<<<<<

// Inheritance and Libraries
import {Ownable} from "../lib/solady/src/auth/Ownable.sol";
import {Initializable} from "../lib/openzeppelin-contracts-v5/contracts/proxy/utils/Initializable.sol";
import {ERC721Holder} from "../lib/openzeppelin-contracts-v5/contracts/token/ERC721/utils/ERC721Holder.sol";
import {ERC1155Holder} from "../lib/openzeppelin-contracts-v5/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {IAlignmentVault} from "./IAlignmentVault.sol";
import {EnumerableSet} from "../lib/openzeppelin-contracts-v5/contracts/utils/structs/EnumerableSet.sol";
import {FixedPointMathLib} from "../lib/solady/src/utils/FixedPointMathLib.sol";

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

// Temporary
import {console2} from "../lib/forge-std/src/console2.sol";

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

    uint256 private constant _NFTX_STANDARD_FEE = 30000000000000000;
    uint256 private constant _SLIPPAGE_DENOMINATOR = 1000000;
    uint256 private constant _ONE_PERCENT = 10000;
    uint24 private constant _POOL_FEE = 3000;

    // >>>>>>>>>>>> [ CONTRACT INTERFACES ] <<<<<<<<<<<<

    IWETH9 private constant _WETH = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    INFTXVaultFactoryV3 private constant _NFTX_VAULT_FACTORY =
        INFTXVaultFactoryV3(0xC255335bc5aBd6928063F5788a5E420554858f01);
    INFTXInventoryStakingV3 private constant _NFTX_INVENTORY_STAKING =
        INFTXInventoryStakingV3(0x889f313e2a3FDC1c9a45bC6020A8a18749CD6152);
    INonfungiblePositionManager private constant _NPM =
        INonfungiblePositionManager(0x26387fcA3692FCac1C1e8E4E2B22A6CF0d4b71bF);
    INFTXRouter private constant _NFTX_POSITION_ROUTER = INFTXRouter(0x70A741A12262d4b5Ff45C0179c783a380EebE42a);
    ISwapRouter private constant _NFTX_SWAP_ROUTER = ISwapRouter(0x1703f8111B0E7A10e1d14f9073F53680d64277A3);

    // >>>>>>>>>>>> [ PRIVATE STORAGE ] <<<<<<<<<<<<

    EnumerableSet.UintSet private _inventoryPositionIds;
    EnumerableSet.UintSet private _liquidityPositionIds;

    // >>>>>>>>>>>> [ PUBLIC STORAGE ] <<<<<<<<<<<<

    uint256 public vaultId;
    int24 public tickSpacing;
    address public vault;
    address public alignedNft;
    address public pool;
    bool public is1155;

    // >>>>>>>>>>>> [ CONSTRUCTOR / INITIALIZER FUNCTIONS ] <<<<<<<<<<<<

    constructor() payable {}

    function initialize(address owner_, address alignedNft_, uint256 vaultId_) external payable virtual initializer {
        _initializeOwner(owner_);
        alignedNft = alignedNft_;
        bool _is1155;
        if (vaultId_ != 0) {
            try _NFTX_VAULT_FACTORY.vault(vaultId_) returns (address vaultAddr) {
                console2.log("the vault address is", vaultAddr);
                if (INFTXVaultV3(vaultAddr).assetAddress() != alignedNft_) revert AV_NFTX_InvalidVaultNft();
                if (INFTXVaultV3(vaultAddr).is1155()) {
                    _is1155 = true;
                    is1155 = true;
                }
                vaultId = vaultId_;
                vault = vaultAddr;
                address _pool = _NFTX_POSITION_ROUTER.getPool(vaultAddr, _POOL_FEE);
                pool = _pool;
                tickSpacing = IUniswapV3Pool(_pool).tickSpacing();
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
                    if (INFTXVaultV3(vaults[i]).is1155()) {
                        _is1155 = true;
                        is1155 = true;
                    }
                    vaultId_ = INFTXVaultV3(vaults[i]).vaultId();
                    vaultId = vaultId_;
                    vault = vaults[i];
                    address _pool = _NFTX_POSITION_ROUTER.getPool(vaults[i], _POOL_FEE);
                    pool = _pool;
                    tickSpacing = IUniswapV3Pool(_pool).tickSpacing();
                    emit AV_VaultInitialized(vaults[i], vaultId_);
                    break;
                }
            }
            if (vaultId_ == 0) revert AV_NFTX_NoStandardVault();
        }
        if (!_is1155) {
            IERC721(alignedNft_).setApprovalForAll(address(_NFTX_INVENTORY_STAKING), true);
            IERC721(alignedNft_).setApprovalForAll(address(_NFTX_POSITION_ROUTER), true);
            IERC721(alignedNft_).setApprovalForAll(address(_NPM), true);
            IERC721(alignedNft_).setApprovalForAll(vault, true);
        } else {
            IERC1155(alignedNft_).setApprovalForAll(address(_NFTX_INVENTORY_STAKING), true);
            IERC1155(alignedNft_).setApprovalForAll(address(_NFTX_POSITION_ROUTER), true);
            IERC1155(alignedNft_).setApprovalForAll(address(_NPM), true);
            IERC1155(alignedNft_).setApprovalForAll(vault, true);
        }
        IERC20(vault).approve(address(_NFTX_INVENTORY_STAKING), type(uint256).max);
        IERC20(vault).approve(address(_NFTX_POSITION_ROUTER), type(uint256).max);
        IERC20(vault).approve(address(_NPM), type(uint256).max);
        _WETH.approve(address(_NFTX_SWAP_ROUTER), type(uint256).max);
    }

    function disableInitializers() external payable virtual {
        _disableInitializers();
    }

    function renounceOwnership() public payable virtual override(Ownable) onlyOwner {}

    // >>>>>>>>>>>> [ VIEW FUNCTIONS ] <<<<<<<<<<<<

    function getInventoryPositionIds() external view virtual returns (uint256[] memory positionIds) {
        positionIds = _inventoryPositionIds.values();
    }

    // TODO: Test
    function getLiquidityPositionIds() external view virtual returns (uint256[] memory positionIds) {
        positionIds = _liquidityPositionIds.values();
    }

    // TODO: Test
    function getSpecificInventoryPositionFees(uint256 positionId) external view virtual returns (uint256 balance) {
        balance = _NFTX_INVENTORY_STAKING.wethBalance(positionId);
    }

    // TODO: Test
    function getTotalInventoryPositionFees() external view virtual returns (uint256 balance) {
        uint256[] memory positionIds = _inventoryPositionIds.values();
        for (uint256 i; i < positionIds.length; ++i) {
            unchecked {
                balance += _NFTX_INVENTORY_STAKING.wethBalance(positionIds[i]);
            }
        }
    }

    // TODO: Test
    function getSpecificLiquidityPositionFees(uint256 positionId)
        external
        view
        virtual
        returns (uint128 token0Fees, uint128 token1Fees)
    {
        (,,,,,,,,,, token0Fees, token1Fees) = _NPM.positions(positionId);
    }

    // TODO: Test
    function getTotalLiquidityPositionFees() external view virtual returns (uint128 token0Fees, uint128 token1Fees) {
        uint256[] memory positionIds = _liquidityPositionIds.values();
        for (uint256 i; i < positionIds.length; ++i) {
            unchecked {
                (,,,,,,,,,, uint128 _token0Fees, uint128 _token1Fees) = _NPM.positions(positionIds[i]);
                token0Fees += _token0Fees;
                token1Fees += _token1Fees;
            }
        }
    }

    // TODO: Test
    // >>>>>>>>>>>> [ EXTERNAL DONATION MANAGEMENT ] <<<<<<<<<<<<

    function donateInventoryPositionIncrease(uint256 positionId, uint256 vTokenAmount)
        external
        payable
        virtual
        onlyOwner
    {
        if (!_inventoryPositionIds.contains(positionId)) revert AV_InvalidPosition();
        IERC20(vault).transferFrom(msg.sender, address(this), vTokenAmount);
        _NFTX_INVENTORY_STAKING.increasePosition(positionId, vTokenAmount, "", false, true);
        emit AV_InventoryPositionIncreased(positionId, vTokenAmount);
    }

    function donateInventoryCombinePositions(uint256 positionId, uint256[] calldata childPositionIds)
        external
        payable
        virtual
        onlyOwner
    {
        if (!_inventoryPositionIds.contains(positionId)) revert AV_InvalidPosition();
        for (uint256 i; i < childPositionIds.length; ++i) {
            _NFTX_INVENTORY_STAKING.transferFrom(msg.sender, address(this), childPositionIds[i]);
        }
        _NFTX_INVENTORY_STAKING.combinePositions(positionId, childPositionIds);
        emit AV_InventoryPositionCombination(positionId, childPositionIds);
    }

    function donateLiquidityPositionIncrease(
        uint256 positionId,
        uint256 vTokenAmount,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint24 slippage
    ) external payable virtual onlyOwner {
        uint256 tokenCount;
        for (uint256 i; i < tokenIds.length; ++i) {
            unchecked {
                tokenCount += amounts[i];
            }
        }
        if (!_liquidityPositionIds.contains(positionId)) revert AV_InvalidPosition();
        if (vTokenAmount > 0) IERC20(vault).transferFrom(msg.sender, address(this), vTokenAmount);
        if (tokenIds.length > 0) {
            if (!is1155) {
                for (uint256 i; i < tokenIds.length; ++i) {
                    IERC721(alignedNft).transferFrom(msg.sender, address(this), tokenIds[i]);
                }
            } else {
                IERC1155(alignedNft).safeBatchTransferFrom(msg.sender, address(this), tokenIds, amounts, "");
            }
        }
        INFTXRouter.IncreaseLiquidityParams memory params;
        unchecked {
            params = INFTXRouter.IncreaseLiquidityParams({
                positionId: positionId,
                vaultId: vaultId,
                vTokensAmount: vTokenAmount,
                nftIds: tokenIds,
                nftAmounts: amounts,
                vTokenMin: (vTokenAmount + (tokenCount * 1 ether))
                    - FixedPointMathLib.fullMulDiv(vTokenAmount + (tokenCount * 1 ether), slippage, _SLIPPAGE_DENOMINATOR),
                wethMin: msg.value - FixedPointMathLib.fullMulDiv(msg.value, slippage, _SLIPPAGE_DENOMINATOR),
                deadline: block.timestamp,
                forceTimelock: true
            });
        }
        _NFTX_POSITION_ROUTER.increaseLiquidity{value: msg.value}(params);
        emit AV_LiquidityPositionIncreased(positionId);
    }

    function donateLiquidityCombinePositions(uint256 positionId, uint256[] calldata childPositionIds)
        external
        payable
        virtual
        onlyOwner
    {
        if (!_inventoryPositionIds.contains(positionId)) revert AV_InvalidPosition();
        uint256 ethBalance = address(this).balance;
        uint256 vTokenBalance = IERC20(vault).balanceOf(address(this));
        uint256[] memory none = new uint256[](0);
        INFTXRouter.RemoveLiquidityParams memory removeParams;
        for (uint256 i; i < childPositionIds.length; ++i) {
            _NPM.transferFrom(msg.sender, address(this), childPositionIds[i]);
            (,,,,,,, uint128 liquidity,,,,) = _NPM.positions(childPositionIds[i]);
            removeParams = INFTXRouter.RemoveLiquidityParams({
                positionId: childPositionIds[i],
                vaultId: vaultId,
                nftIds: none,
                vTokenPremiumLimit: type(uint256).max,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });
            _NFTX_POSITION_ROUTER.removeLiquidity(removeParams);
        }
        INFTXRouter.IncreaseLiquidityParams memory increaseParams;
        unchecked {
            increaseParams = INFTXRouter.IncreaseLiquidityParams({
                positionId: positionId,
                vaultId: vaultId,
                vTokensAmount: IERC20(vault).balanceOf(address(this)) - vTokenBalance,
                nftIds: none,
                nftAmounts: none,
                vTokenMin: 0,
                wethMin: 0,
                deadline: block.timestamp,
                forceTimelock: true
            });
        }
        _NFTX_POSITION_ROUTER.increaseLiquidity{value: address(this).balance - ethBalance}(increaseParams);
        uint256 wethBalance = _WETH.balanceOf(address(this));
        if (wethBalance > 0) _WETH.withdraw(wethBalance);
        emit AV_LiquidityPositionCombination(positionId, childPositionIds);
    }

    function donateBuyNftsFromPool(
        uint256[] calldata tokenIds,
        uint256 vTokenPremiumLimit,
        uint24 fee,
        uint160 sqrtPriceLimitX96
    ) external payable virtual onlyOwner {
        if (vTokenPremiumLimit == 0) vTokenPremiumLimit = type(uint256).max;
        if (sqrtPriceLimitX96 == 0) sqrtPriceLimitX96 = type(uint160).max;
        INFTXRouter.BuyNFTsParams memory params = INFTXRouter.BuyNFTsParams({
            vaultId: vaultId,
            nftIds: tokenIds,
            vTokenPremiumLimit: vTokenPremiumLimit,
            deadline: block.timestamp,
            fee: fee,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });
        uint256 balance = address(this).balance - msg.value;
        _NFTX_POSITION_ROUTER.buyNFTs{value: msg.value}(params);
        if (address(this).balance > balance) {
            (bool success,) = payable(msg.sender).call{value: address(this).balance - balance}("");
            if (!success) revert AV_TransactionFailed();
        }
        emit AV_NftsPurchased(address(this).balance - balance, tokenIds);
    }

    function donateMintVToken(uint256[] calldata tokenIds, uint256[] calldata amounts) external payable onlyOwner {
        uint256 balance = address(this).balance - msg.value;
        INFTXVaultV3(vault).mint{value: msg.value}(tokenIds, amounts, msg.sender, address(this));
        if (address(this).balance > balance) {
            (bool success,) = payable(msg.sender).call{value: address(this).balance - balance}("");
            if (!success) revert AV_TransactionFailed();
        }
        emit AV_MintVTokens(tokenIds, amounts);
    }

    // >>>>>>>>>>>> [ INVENTORY POSITION MANAGEMENT ] <<<<<<<<<<<<

    function inventoryPositionCreateVToken(uint256 vTokenAmount)
        external
        payable
        virtual
        onlyOwner
        returns (uint256 positionId)
    {
        positionId = _NFTX_INVENTORY_STAKING.deposit(vaultId, vTokenAmount, address(this), "", false, true);
        _inventoryPositionIds.add(positionId);
        emit AV_InventoryPositionCreated(positionId, vTokenAmount);
    }

    function inventoryPositionCreateNfts(uint256[] calldata tokenIds, uint256[] calldata amounts)
        external
        payable
        virtual
        onlyOwner
        returns (uint256 positionId)
    {
        uint256 tokenCount;
        for (uint256 i; i < tokenIds.length; ++i) {
            unchecked {
                tokenCount += amounts[i];
            }
        }
        positionId = _NFTX_INVENTORY_STAKING.depositWithNFT(vaultId, tokenIds, amounts, address(this));
        _inventoryPositionIds.add(positionId);
        emit AV_InventoryPositionCreated(positionId, tokenCount * 1 ether);
    }

    // Only works on inventory positions created with vTokens
    function inventoryPositionIncrease(uint256 positionId, uint256 vTokenAmount) external payable virtual onlyOwner {
        _NFTX_INVENTORY_STAKING.increasePosition(positionId, vTokenAmount, "", false, true);
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
        _NFTX_INVENTORY_STAKING.withdraw(positionId, vTokenAmount, tokenIds, vTokenPremiumLimit);
        emit AV_InventoryPositionWithdrawal(positionId, vTokenAmount);
    }

    function inventoryPositionCombine(uint256 positionId, uint256[] calldata childPositionIds)
        external
        payable
        virtual
        onlyOwner
    {
        _NFTX_INVENTORY_STAKING.combinePositions(positionId, childPositionIds);
        emit AV_InventoryPositionCombination(positionId, childPositionIds);
    }

    // TODO: Test
    function inventoryPositionCollectFees(uint256[] calldata positionIds) external payable virtual onlyOwner {
        _NFTX_INVENTORY_STAKING.collectWethFees(positionIds);
        emit AV_InventoryPositionsCollected(positionIds);
    }

    // TODO: Test
    function inventoryPositionCollectAllFees() external payable virtual onlyOwner {
        uint256[] memory positionIds = _inventoryPositionIds.values();
        _NFTX_INVENTORY_STAKING.collectWethFees(positionIds);
        emit AV_InventoryPositionsCollected(positionIds);
    }

    // TODO: Test
    // >>>>>>>>>>>> [ LIQUIDITY POSITION MANAGEMENT ] <<<<<<<<<<<<

    function liquidityPositionCreate(
        uint256 ethAmount,
        uint256 vTokenAmount,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        int24 tickLower,
        int24 tickUpper,
        uint160 sqrtPriceX96
    ) external payable virtual onlyOwner returns (uint256 positionId) {
        uint256 tokenCount;
        for (uint256 i; i < tokenIds.length; ++i) {
            unchecked {
                tokenCount += amounts[i];
            }
        }
        (uint160 _sqrtPriceX96,,,,,,) = IUniswapV3Pool(pool).slot0();
        if (_sqrtPriceX96 == 0) _sqrtPriceX96 = sqrtPriceX96;
        INFTXRouter.AddLiquidityParams memory params;
        unchecked {
            params = INFTXRouter.AddLiquidityParams({
                vaultId: vaultId,
                vTokensAmount: vTokenAmount,
                nftIds: tokenIds,
                nftAmounts: amounts,
                tickLower: int24(FixedPointMathLib.rawSDiv(tickLower, tickSpacing)) * tickSpacing,
                tickUpper: int24(FixedPointMathLib.rawSDiv(tickUpper, tickSpacing)) * tickSpacing,
                fee: _POOL_FEE,
                sqrtPriceX96: _sqrtPriceX96,
                vTokenMin: (vTokenAmount + (tokenCount * 1 ether))
                    - FixedPointMathLib.fullMulDiv(vTokenAmount + (tokenCount * 1 ether), _ONE_PERCENT, _SLIPPAGE_DENOMINATOR),
                wethMin: ethAmount - FixedPointMathLib.fullMulDiv(ethAmount, _ONE_PERCENT, _SLIPPAGE_DENOMINATOR),
                deadline: block.timestamp,
                forceTimelock: true,
                recipient: address(this)
            });
        }
        positionId = _NFTX_POSITION_ROUTER.addLiquidity{value: ethAmount}(params);
        _liquidityPositionIds.add(positionId);
        emit AV_LiquidityPositionCreated(positionId);
    }

    function liquidityPositionIncrease(
        uint256 positionId,
        uint256 ethAmount,
        uint256 vTokenAmount,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external payable virtual onlyOwner {
        INFTXRouter.IncreaseLiquidityParams memory params;
        unchecked {
            params = INFTXRouter.IncreaseLiquidityParams({
                positionId: positionId,
                vaultId: vaultId,
                vTokensAmount: vTokenAmount,
                nftIds: tokenIds,
                nftAmounts: amounts,
                vTokenMin: 0,
                wethMin: 0,
                deadline: block.timestamp,
                forceTimelock: true
            });
        }
        _NFTX_POSITION_ROUTER.increaseLiquidity{value: ethAmount}(params);
        emit AV_LiquidityPositionIncreased(positionId);
    }

    function liquidityPositionWithdrawal(
        uint256 positionId,
        uint256[] calldata tokenIds,
        uint256 vTokenPremiumLimit,
        uint128 liquidity
    ) external payable virtual onlyOwner {
        if (vTokenPremiumLimit == 0) vTokenPremiumLimit = type(uint256).max;
        INFTXRouter.RemoveLiquidityParams memory params = INFTXRouter.RemoveLiquidityParams({
            positionId: positionId,
            vaultId: vaultId,
            nftIds: tokenIds,
            vTokenPremiumLimit: vTokenPremiumLimit,
            liquidity: liquidity,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        });
        _NFTX_POSITION_ROUTER.removeLiquidity(params);
        uint256 wethBalance = _WETH.balanceOf(address(this));
        if (wethBalance > 0) _WETH.withdraw(wethBalance);
        emit AV_LiquidityPositionWithdrawal(positionId);
    }

    function liquidityPositionCombine(uint256 positionId, uint256[] calldata childPositionIds)
        external
        payable
        virtual
        onlyOwner
    {
        uint256 ethBalance = address(this).balance;
        uint256 vTokenBalance = IERC20(vault).balanceOf(address(this));
        uint256[] memory none = new uint256[](0);
        INFTXRouter.RemoveLiquidityParams memory removeParams;
        for (uint256 i; i < childPositionIds.length; ++i) {
            (,,,,,,, uint128 liquidity,,,,) = _NPM.positions(childPositionIds[i]);
            removeParams = INFTXRouter.RemoveLiquidityParams({
                positionId: childPositionIds[i],
                vaultId: vaultId,
                nftIds: none,
                vTokenPremiumLimit: type(uint256).max,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });
            _NFTX_POSITION_ROUTER.removeLiquidity(removeParams);
        }
        INFTXRouter.IncreaseLiquidityParams memory increaseParams;
        unchecked {
            increaseParams = INFTXRouter.IncreaseLiquidityParams({
                positionId: positionId,
                vaultId: vaultId,
                vTokensAmount: IERC20(vault).balanceOf(address(this)) - vTokenBalance,
                nftIds: none,
                nftAmounts: none,
                vTokenMin: 0,
                wethMin: 0,
                deadline: block.timestamp,
                forceTimelock: true
            });
        }
        _NFTX_POSITION_ROUTER.increaseLiquidity{value: address(this).balance - ethBalance}(increaseParams);
        uint256 wethBalance = _WETH.balanceOf(address(this));
        if (wethBalance > 0) _WETH.withdraw(wethBalance);
        emit AV_LiquidityPositionCombination(positionId, childPositionIds);
    }

    function liquidityPositionCollectFees(uint256[] calldata positionIds) external payable virtual onlyOwner {
        for (uint256 i; i < positionIds.length; ++i) {
            INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
                tokenId: positionIds[i],
                recipient: msg.sender,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });
            _NPM.collect(params);
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
            _NPM.collect(params);
        }
        emit AV_LiquidityPositionsCollected(positionIds);
    }

    // TODO: Test
    // >>>>>>>>>>>> [ ALIGNED TOKEN MANAGEMENT ] <<<<<<<<<<<<

    function buyNftsFromPool(
        uint256 ethAmount,
        uint256[] calldata tokenIds,
        uint256 vTokenPremiumLimit,
        uint24 fee,
        uint160 sqrtPriceLimitX96
    ) external payable virtual onlyOwner {
        if (vTokenPremiumLimit == 0) vTokenPremiumLimit = type(uint256).max;
        if (sqrtPriceLimitX96 == 0) sqrtPriceLimitX96 = type(uint160).max;
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
        uint256 tokenCount;
        for (uint256 i; i < tokenIds.length; ++i) {
            unchecked {
                tokenCount += amounts[i];
            }
        }
        uint256 ethRequired =
            FixedPointMathLib.fullMulDivUp(INFTXVaultV3(vault).vTokenToETH(tokenCount * 1 ether), 30000, 1000000);
        INFTXVaultV3(vault).mint{value: ethRequired}(tokenIds, amounts, address(this), address(this));
        emit AV_MintVTokens(tokenIds, amounts);
    }

    function buyVToken(uint256 ethAmount, uint24 fee, uint24 slippage, uint160 sqrtPriceLimitX96)
        external
        payable
        onlyOwner
    {
        if (sqrtPriceLimitX96 == 0) sqrtPriceLimitX96 = type(uint160).max;
        _WETH.deposit{value: ethAmount}();
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(_WETH),
            tokenOut: vault,
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: ethAmount,
            amountOutMinimum: FixedPointMathLib.fullMulDiv(ethAmount, slippage, _SLIPPAGE_DENOMINATOR),
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });
        _NFTX_SWAP_ROUTER.exactInputSingle(params);
        _WETH.withdraw(_WETH.balanceOf(address(this)));
    }

    function buyVTokenExact(uint256 ethAmount, uint256 vTokenAmount, uint24 fee, uint160 sqrtPriceLimitX96)
        external
        payable
        onlyOwner
    {
        if (sqrtPriceLimitX96 == 0) sqrtPriceLimitX96 = type(uint160).max;
        _WETH.deposit{value: ethAmount}();
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: address(_WETH),
            tokenOut: vault,
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountOut: vTokenAmount,
            amountInMaximum: ethAmount,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });
        _NFTX_SWAP_ROUTER.exactOutputSingle(params);
        _WETH.withdraw(_WETH.balanceOf(address(this)));
    }

    function sellVToken(uint256 vTokenAmount, uint24 fee, uint24 slippage, uint160 sqrtPriceLimitX96)
        external
        payable
        onlyOwner
    {
        if (sqrtPriceLimitX96 == 0) sqrtPriceLimitX96 = type(uint160).max;
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: vault,
            tokenOut: address(_WETH),
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: vTokenAmount,
            amountOutMinimum: FixedPointMathLib.fullMulDiv(vTokenAmount, slippage, _SLIPPAGE_DENOMINATOR),
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });
        _NFTX_SWAP_ROUTER.exactInputSingle(params);
        _WETH.withdraw(_WETH.balanceOf(address(this)));
    }

    function sellVTokenExact(uint256 vTokenAmount, uint256 ethAmount, uint24 fee, uint160 sqrtPriceLimitX96)
        external
        payable
        onlyOwner
    {
        if (sqrtPriceLimitX96 == 0) sqrtPriceLimitX96 = type(uint160).max;
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: vault,
            tokenOut: address(_WETH),
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountOut: ethAmount,
            amountInMaximum: vTokenAmount,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });
        _NFTX_SWAP_ROUTER.exactOutputSingle(params);
        _WETH.withdraw(_WETH.balanceOf(address(this)));
    }

    // TODO: Test
    // >>>>>>>>>>>> [ MISCELLANEOUS TOKEN MANAGEMENT ] <<<<<<<<<<<<

    function rescueERC20(address token, uint256 amount, address recipient) external payable virtual onlyOwner {
        if (token == vault || token == address(_WETH)) revert AV_ProhibitedWithdrawal();
        IERC20(token).transfer(recipient, amount);
    }

    function rescueERC721(address token, uint256 tokenId, address recipient) external payable virtual onlyOwner {
        if (token == alignedNft || token == address(_NPM)) revert AV_ProhibitedWithdrawal();
        IERC721(token).transferFrom(address(this), recipient, tokenId);
    }

    function rescueERC1155(address token, uint256 tokenId, uint256 amount, address recipient)
        external
        payable
        virtual
        onlyOwner
    {
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

    function unwrapEth() external payable virtual onlyOwner {
        _WETH.withdraw(_WETH.balanceOf(address(this)));
    }

    // >>>>>>>>>>>> [ RECEIVE LOGIC ] <<<<<<<<<<<<

    function onERC721Received(address, address, uint256, bytes memory)
        public
        virtual
        override(ERC721Holder, IAlignmentVault)
        returns (bytes4)
    {
        console2.log(msg.sender);
        if (msg.sender != alignedNft && msg.sender != address(_NFTX_INVENTORY_STAKING) && msg.sender != address(_NPM)) {
            revert AV_UnalignedNft();
        }
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory)
        public
        virtual
        override(ERC1155Holder, IAlignmentVault)
        returns (bytes4)
    {
        if (msg.sender != alignedNft) revert AV_UnalignedNft();
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        public
        virtual
        override(ERC1155Holder, IAlignmentVault)
        returns (bytes4)
    {
        if (msg.sender != alignedNft) revert AV_UnalignedNft();
        return this.onERC1155BatchReceived.selector;
    }

    receive() external payable virtual {}
    fallback() external payable virtual {}
}
