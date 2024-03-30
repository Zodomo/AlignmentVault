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
import {INFTXRouter} from "../lib/nftx-protocol-v3/src/interfaces/INFTXRouter.sol";
import {INonfungiblePositionManager} from "../lib/nftx-protocol-v3/src/uniswap/v3-periphery/interfaces/INonfungiblePositionManager.sol";

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

    // >>>>>>>>>>>> [ CONTRACT INTERFACES ] <<<<<<<<<<<<

    IWETH9 private constant _WETH = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    INFTXVaultFactoryV3 private constant _NFTX_VAULT_FACTORY = INFTXVaultFactoryV3(0xC255335bc5aBd6928063F5788a5E420554858f01);
    INFTXInventoryStakingV3 private constant _NFTX_INVENTORY_STAKING = INFTXInventoryStakingV3(0x889f313e2a3FDC1c9a45bC6020A8a18749CD6152);
    INFTXRouter private constant _NFTX_ROUTER = INFTXRouter(0x70A741A12262d4b5Ff45C0179c783a380EebE42a);
    INonfungiblePositionManager private constant _NFP = INonfungiblePositionManager(0x26387fcA3692FCac1C1e8E4E2B22A6CF0d4b71bF);

    // >>>>>>>>>>>> [ PRIVATE STORAGE ] <<<<<<<<<<<<

    EnumerableSet.UintSet private _inventoryPositionIds;
    EnumerableSet.UintSet private _liquidityPositionIds;

    // >>>>>>>>>>>> [ PUBLIC STORAGE ] <<<<<<<<<<<<

    uint256 public vaultId;
    address public vault;
    address public alignedNft;
    bool public is1155;

    // >>>>>>>>>>>> [ CONSTRUCTOR / INITIALIZER FUNCTIONS ] <<<<<<<<<<<<

    constructor() payable {}

    function initialize(
        address owner_,
        address alignedNft_,
        uint256 vaultId_
    ) external payable virtual initializer {
        _initializeOwner(owner_);
        alignedNft = alignedNft_;
        bool _is1155;
        if (vaultId_ != 0) {
            try _NFTX_VAULT_FACTORY.vault(vaultId_) returns (address vaultAddr) {
                if (INFTXVaultV3(vaultAddr).assetAddress() != alignedNft_) revert AV_NFTX_InvalidVaultNft();
                if (INFTXVaultV3(vaultAddr).is1155()) {
                    _is1155 = true;
                    is1155 = true;
                }
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
                if (mintFee != _NFTX_STANDARD_FEE || redeemFee != _NFTX_STANDARD_FEE || swapFee != _NFTX_STANDARD_FEE) continue;
                else if (INFTXVaultV3(vaults[i]).manager() != address(0)) continue;
                else {
                    if (INFTXVaultV3(vaults[i]).is1155()) {
                        _is1155 = true;
                        is1155 = true;
                    }
                    vaultId_ = INFTXVaultV3(vaults[i]).vaultId();
                    vaultId = vaultId_;
                    vault = vaults[i];
                    emit AV_VaultInitialized(vaults[i], vaultId_);
                    break;
                }
            }
            if (vaultId_ == 0) revert AV_NFTX_NoStandardVault();
        }
        if (!_is1155) {
            IERC721(alignedNft_).setApprovalForAll(address(_NFTX_INVENTORY_STAKING), true);
            IERC721(alignedNft_).setApprovalForAll(address(_NFTX_ROUTER), true);
            IERC721(alignedNft_).setApprovalForAll(address(_NFP), true);
            IERC721(alignedNft_).setApprovalForAll(vault, true);
        } else {
            IERC1155(alignedNft_).setApprovalForAll(address(_NFTX_INVENTORY_STAKING), true);
            IERC1155(alignedNft_).setApprovalForAll(address(_NFTX_ROUTER), true);
            IERC1155(alignedNft_).setApprovalForAll(address(_NFP), true);
            IERC1155(alignedNft_).setApprovalForAll(vault, true);
        }
        IERC20(vault).approve(address(_NFTX_INVENTORY_STAKING), type(uint256).max);
        IERC20(vault).approve(address(_NFTX_ROUTER), type(uint256).max);
        IERC20(vault).approve(address(_NFP), type(uint256).max);
    }

    function disableInitializers() external payable virtual {
        _disableInitializers();
    }

    function renounceOwnership() public payable virtual override(Ownable) onlyOwner {}

    // >>>>>>>>>>>> [ VIEW FUNCTIONS ] <<<<<<<<<<<<

    function getInventoryPositionIds() external view virtual returns (uint256[] memory positionIds) {
        positionIds = _inventoryPositionIds.values();
    }

    function getLiquidityPositionIds() external view virtual returns (uint256[] memory positionIds) {
        positionIds = _liquidityPositionIds.values();
    }

    function getSpecificInventoryPositionFees(uint256 positionId) external view virtual returns (uint256 balance) {
        balance = _NFTX_INVENTORY_STAKING.wethBalance(positionId);
    }

    function getTotalInventoryPositionFees() external view virtual returns (uint256 balance) {
        uint256[] memory positionIds = _inventoryPositionIds.values();
        for (uint256 i; i < positionIds.length; ++i) {
            unchecked {
                balance += _NFTX_INVENTORY_STAKING.wethBalance(positionIds[i]);
            }
        }
    }

    function getSpecificLiquidityPositionFees(uint256 positionId) external view virtual returns (uint128 token0Fees, uint128 token1Fees) {
        (,,,,,,,,,, token0Fees, token1Fees) = _NFP.positions(positionId);
    }

    function getTotalLiquidityPositionFees() external view virtual returns (uint128 token0Fees, uint128 token1Fees) {
        uint256[] memory positionIds = _liquidityPositionIds.values();
        for (uint256 i; i < positionIds.length; ++i) {
            unchecked {
                (,,,,,,,,,, uint128 _token0Fees, uint128 _token1Fees) = _NFP.positions(positionIds[i]);
                token0Fees += _token0Fees;
                token1Fees += _token1Fees;
            }
        }
    }

    // >>>>>>>>>>>> [ INVENTORY POSITION MANAGEMENT ] <<<<<<<<<<<<

    function inventoryPositionCreateVToken(uint256 vTokenAmount) external payable virtual onlyOwner {
        uint256 positionId = _NFTX_INVENTORY_STAKING.deposit(
            vaultId,
            vTokenAmount,
            address(this),
            "",
            false,
            true
        );
        _inventoryPositionIds.add(positionId);
        emit AV_InventoryPositionCreated(positionId, vTokenAmount);
    }

    function inventoryPositionCreateNfts(uint256[] calldata tokenIds, uint256[] calldata amounts) external payable virtual onlyOwner {
        uint256 positionId = _NFTX_INVENTORY_STAKING.depositWithNFT(vaultId, tokenIds, amounts, address(this));
        _inventoryPositionIds.add(positionId);
        emit AV_InventoryPositionCreated(positionId, tokenIds.length * 10e18);
    }

    function inventoryPositionIncrease(uint256 positionId, uint256 vTokenAmount) external payable virtual onlyOwner {
        _NFTX_INVENTORY_STAKING.increasePosition(positionId, vTokenAmount, "", false, true);
        emit AV_InventoryPositionIncreased(positionId, vTokenAmount);
    }

    function inventoryPositionWithdrawal(uint256 positionId, uint256 vTokenAmount, uint256[] calldata tokenIds, uint256 vTokenPremiumLimit) external payable virtual onlyOwner {
        if (vTokenPremiumLimit == 0) vTokenPremiumLimit = type(uint256).max;
        _NFTX_INVENTORY_STAKING.withdraw(positionId, vTokenAmount, tokenIds, vTokenPremiumLimit);
        emit AV_InventoryPositionWithdrawal(positionId, vTokenAmount);
    }

    function inventoryCombinePositions(uint256 positionId, uint256[] calldata childPositionIds) external payable virtual onlyOwner {
        _NFTX_INVENTORY_STAKING.combinePositions(positionId, childPositionIds);
        emit AV_InventoryPositionCombination(positionId, childPositionIds);
    }

    function inventoryPositionCollectFees(uint256[] calldata positionIds) external payable virtual onlyOwner {
        _NFTX_INVENTORY_STAKING.collectWethFees(positionIds);
        emit AV_InventoryPositionsCollected(positionIds);
    }

    function inventoryPositionCollectAllFees() external payable virtual onlyOwner {
        uint256[] memory positionIds = _inventoryPositionIds.values();
        _NFTX_INVENTORY_STAKING.collectWethFees(positionIds);
        emit AV_InventoryPositionsCollected(positionIds);
    }

    // >>>>>>>>>>>> [ LIQUIDITY POSITION MANAGEMENT ] <<<<<<<<<<<<

    function liquidityPositionCreate(uint256 ethAmount, uint256 vTokenAmount, uint256[] calldata tokenIds, uint256[] calldata amounts, int24 tickLower, int24 tickUpper, uint24 fee, uint160 sqrtPriceX96, uint16 slippage) external payable virtual onlyOwner {
        INFTXRouter.AddLiquidityParams memory params;
        unchecked {
            params = INFTXRouter.AddLiquidityParams({
                vaultId: vaultId,
                vTokensAmount: vTokenAmount,
                nftIds: tokenIds,
                nftAmounts: amounts,
                tickLower: tickLower,
                tickUpper: tickUpper,
                fee: fee,
                sqrtPriceX96: sqrtPriceX96,
                vTokenMin: (vTokenAmount + (tokenIds.length * 10e18)) - FixedPointMathLib.fullMulDiv(vTokenAmount + (tokenIds.length * 10e18), slippage, _SLIPPAGE_DENOMINATOR),
                wethMin: ethAmount - FixedPointMathLib.fullMulDiv(ethAmount, slippage, _SLIPPAGE_DENOMINATOR),
                deadline: block.timestamp,
                forceTimelock: true,
                recipient: address(this)
            });
        }
        uint256 positionId = _NFTX_ROUTER.addLiquidity{value: ethAmount}(params);
        _liquidityPositionIds.add(positionId);
        emit AV_LiquidityPositionCreated(positionId, ethAmount, vTokenAmount + tokenIds.length * 10e18);
    }

    function liquidityPositionIncrease(uint256 positionId, uint256 ethAmount, uint256 vTokenAmount, uint256[] calldata tokenIds, uint256[] calldata amounts, uint16 slippage) external payable virtual onlyOwner {
        INFTXRouter.IncreaseLiquidityParams memory params;
        unchecked {
            params = INFTXRouter.IncreaseLiquidityParams({
                positionId: positionId,
                vaultId: vaultId,
                vTokensAmount: vTokenAmount,
                nftIds: tokenIds,
                nftAmounts: amounts,
                vTokenMin: (vTokenAmount + (tokenIds.length * 10e18)) - FixedPointMathLib.fullMulDiv(vTokenAmount + (tokenIds.length * 10e18), slippage, _SLIPPAGE_DENOMINATOR),
                wethMin: ethAmount - FixedPointMathLib.fullMulDiv(ethAmount, slippage, _SLIPPAGE_DENOMINATOR),
                deadline: block.timestamp,
                forceTimelock: true
            });
        }
        _NFTX_ROUTER.increaseLiquidity{value: ethAmount}(params);
        emit AV_LiquidityPositionIncreased(positionId, ethAmount, vTokenAmount + tokenIds.length * 10e18);
    }

    function liquidityPositionCollectFees(uint256[] calldata positionIds) external payable virtual onlyOwner {
        for (uint256 i; i < positionIds.length; ++i) {
            INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
                tokenId: positionIds[i],
                recipient: msg.sender,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });
            _NFP.collect(params);
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
            _NFP.collect(params);
        }
        emit AV_LiquidityPositionsCollected(positionIds);
    }

    // >>>>>>>>>>>> [ VTOKEN MANAGEMENT ] <<<<<<<<<<<<

    function buyNftsFromPool(uint256 ethAmount, uint256[] calldata tokenIds, uint256 vTokenPremiumLimit, uint24 fee, uint160 sqrtPriceLimitX96) external payable virtual onlyOwner {
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
        _NFTX_ROUTER.buyNFTs{value: ethAmount}(params);
        emit AV_NftsPurchased(balance - address(this).balance, tokenIds);
    }

    function mintVToken(uint256 ethAmount, uint256[] calldata tokenIds, uint256[] calldata amounts) external payable onlyOwner {
        INFTXVaultV3(vault).mint{value: ethAmount}(tokenIds, amounts, address(this), address(this));
        emit AV_MintVTokens(tokenIds, amounts);
    }

    // >>>>>>>>>>>> [ MISCELLANEOUS TOKEN MANAGEMENT ] <<<<<<<<<<<<

    function rescueERC20(address token, uint256 amount, address recipient) external payable virtual onlyOwner {
        if (token == vault || token == address(_WETH)) revert AV_ProhibitedWithdrawal();
        IERC20(token).transfer(recipient, amount);
    }

    function rescueERC721(address token, uint256 tokenId, address recipient) external payable virtual onlyOwner {
        if (token == alignedNft || token == address(_NFP)) revert AV_ProhibitedWithdrawal();
        IERC721(token).transferFrom(address(this), recipient, tokenId);
    }

    function rescueERC1155(address token, uint256 tokenId, uint256 amount, address recipient) external payable virtual onlyOwner {
        if (token == alignedNft) revert AV_ProhibitedWithdrawal();
        IERC1155(token).safeTransferFrom(address(this), recipient, tokenId, amount, "");
    }

    function rescueERC1155Batch(address token, uint256[] calldata tokenIds, uint256[] calldata amounts, address recipient) external payable virtual onlyOwner {
        if (token == alignedNft) revert AV_ProhibitedWithdrawal();
        IERC1155(token).safeBatchTransferFrom(address(this), recipient, tokenIds, amounts, "");
    }

    function unwrapEth() external payable virtual onlyOwner {
        _WETH.withdraw(_WETH.balanceOf(address(this)));
    }

    // >>>>>>>>>>>> [ RECEIVE LOGIC ] <<<<<<<<<<<<

    function onERC721Received(address, address, uint256, bytes memory) public virtual override(ERC721Holder, IAlignmentVault) returns (bytes4) {
        if (msg.sender != alignedNft || msg.sender != address(_NFTX_INVENTORY_STAKING) || msg.sender != address(_NFP)) revert AV_UnalignedNft();
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override(ERC1155Holder, IAlignmentVault) returns (bytes4) {
        if (msg.sender != alignedNft) revert AV_UnalignedNft();
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override(ERC1155Holder, IAlignmentVault) returns (bytes4) {
        if (msg.sender != alignedNft) revert AV_UnalignedNft();
        return this.onERC1155BatchReceived.selector;
    }

    receive() external payable virtual {}
    fallback() external payable virtual {}
}