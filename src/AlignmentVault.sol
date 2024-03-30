// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

// Inheritance and Libraries
import {Ownable} from "../lib/solady/src/auth/Ownable.sol";
import {Initializable} from "../lib/openzeppelin-contracts-v5/contracts/proxy/utils/Initializable.sol";
import {ERC721Holder} from "../lib/openzeppelin-contracts-v5/contracts/token/ERC721/utils/ERC721Holder.sol";
import {ERC1155Holder} from "../lib/openzeppelin-contracts-v5/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {IAlignmentVault} from "./IAlignmentVault.sol";
import {EnumerableSet} from "../lib/openzeppelin-contracts-v5/contracts/utils/structs/EnumerableSet.sol";

// Interfaces
import {IWETH9} from "../lib/nftx-protocol-v3/src/uniswap/v3-periphery/interfaces/external/IWETH9.sol";
import {IERC20} from "../lib/openzeppelin-contracts-v5/contracts/interfaces/IERC20.sol";
import {IERC721} from "../lib/openzeppelin-contracts-v5/contracts/interfaces/IERC721.sol";
import {IERC1155} from "../lib/openzeppelin-contracts-v5/contracts/interfaces/IERC1155.sol";
import {INFTXVaultFactoryV3} from "../lib/nftx-protocol-v3/src/interfaces/INFTXVaultFactoryV3.sol";
import {INFTXVaultV3} from "../lib/nftx-protocol-v3/src/interfaces/INFTXVaultV3.sol";
import {INFTXInventoryStakingV3} from "../lib/nftx-protocol-v3/src/interfaces/INFTXInventoryStakingV3.sol";
import {INFTXRouter} from "../lib/nftx-protocol-v3/src/interfaces/INFTXRouter.sol";

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

    uint256 private constant _NFTX_STANDARD_FEE = 30000000000000000;

    IWETH9 private constant _WETH = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    INFTXVaultFactoryV3 private constant _NFTX_VAULT_FACTORY = INFTXVaultFactoryV3(0xC255335bc5aBd6928063F5788a5E420554858f01);
    INFTXInventoryStakingV3 private constant _NFTX_INVENTORY_STAKING = INFTXInventoryStakingV3(0x889f313e2a3FDC1c9a45bC6020A8a18749CD6152);
    IERC721 private constant _NFP = IERC721(0x26387fcA3692FCac1C1e8E4E2B22A6CF0d4b71bF); // NFTX NonfungiblePositionManager.sol

    EnumerableSet.UintSet private _nftsHeld;
    EnumerableSet.UintSet private _childInventoryPositionIds;
    mapping(uint256 tokenId => uint256 amount) private _erc1155Balances;

    uint256 public vaultId;
    uint256 public inventoryPositionId;
    IERC20 public vault;
    address public alignedNft;
    bool public is1155;

    constructor() payable {}

    function initialize(
        address _owner,
        address _alignedNft,
        uint256 _vaultId
    ) external payable virtual initializer {
        _initializeOwner(_owner);
        alignedNft = _alignedNft;
        if (_vaultId != 0) {
            try _NFTX_VAULT_FACTORY.vault(_vaultId) returns (address vaultAddr) {
                if (INFTXVaultV3(vaultAddr).assetAddress() != _alignedNft) revert AV_NFTX_InvalidVaultNft();
                if (INFTXVaultV3(vaultAddr).is1155()) {
                    is1155 = true;
                    IERC1155(_alignedNft).setApprovalForAll(address(_NFTX_INVENTORY_STAKING), true);
                }
                vaultId = _vaultId;
                vault = IERC20(vaultAddr);
                vault.approve(address(_NFTX_INVENTORY_STAKING), type(uint256).max);
                emit AV_VaultInitialized(vaultAddr, vaultId);
            } catch {
                revert AV_NFTX_InvalidVaultId();
            }
        } else {
            address[] memory vaults = _NFTX_VAULT_FACTORY.vaultsForAsset(_alignedNft);
            if (vaults.length == 0) revert AV_NFTX_NoVaultsExist();
            for (uint256 i; i < vaults.length; ++i) {
                (uint256 mintFee, uint256 redeemFee, uint256 swapFee) = INFTXVaultV3(vaults[i]).vaultFees();
                if (mintFee != _NFTX_STANDARD_FEE || redeemFee != _NFTX_STANDARD_FEE || swapFee != _NFTX_STANDARD_FEE) continue;
                else if (INFTXVaultV3(vaults[i]).manager() != address(0)) continue;
                else {
                    if (INFTXVaultV3(vaults[i]).is1155()) {
                        is1155 = true;
                        IERC1155(_alignedNft).setApprovalForAll(address(_NFTX_INVENTORY_STAKING), true);
                    }
                    _vaultId = INFTXVaultV3(vaults[i]).vaultId();
                    vaultId = _vaultId;
                    vault = IERC20(vaults[i]);
                    vault.approve(address(_NFTX_INVENTORY_STAKING), type(uint256).max);
                    emit AV_VaultInitialized(vaults[i], _vaultId);
                    break;
                }
            }
            if (_vaultId == 0) revert AV_NFTX_NoStandardVault();
        }
    }

    function disableInitializers() external payable virtual override {
        _disableInitializers();
    }

    function renounceOwnership() public payable virtual override(Ownable, IAlignmentVault) {}

    function getNftInventory() external view virtual returns (uint256[] memory tokenIds) {
        tokenIds = _nftsHeld.values();
    }

    function getNftInventoryAmounts() external view virtual returns (uint256[] memory tokenIds, uint256[] memory amounts) {
        bool _is1155 = is1155;
        address _alignedNft = alignedNft;
        tokenIds = _nftsHeld.values();
        amounts = new uint256[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; ++i) {
            if (!_is1155) amounts[i] = 1;
            else amounts[i] = IERC1155(_alignedNft).balanceOf(address(this), tokenIds[i]);
        }
    }

    function updateNftInventory(uint256[] calldata tokenIds) external {
        address _alignedNft = alignedNft;
        bool _is1155 = is1155;
        for (uint256 i; i < tokenIds.length; ++i) {
            if (!_is1155) {
                try IERC721(_alignedNft).ownerOf(tokenIds[i]) returns (address nftOwner) {
                    if (nftOwner != address(this)) continue;
                    else {
                        bool added = _nftsHeld.add(tokenIds[i]);
                        if (added) emit AV_ReceivedAlignedNft(tokenIds[i], 1);
                    }
                } catch {
                    continue;
                }
            } else {
                try IERC1155(_alignedNft).balanceOf(address(this), tokenIds[i]) returns (uint256 currentBalance) {
                    if (currentBalance == 0) continue;
                    else {            
                        _nftsHeld.add(tokenIds[i]);            
                        uint256 knownBalance = _erc1155Balances[tokenIds[i]];
                        uint256 difference;
                        unchecked {
                            difference = currentBalance - knownBalance;
                            if (difference > 0) {
                                _erc1155Balances[tokenIds[i]] += difference;
                                emit AV_ReceivedAlignedNft(tokenIds[i], difference);
                            }
                        }
                    }
                } catch {
                    continue;
                }
            }
        }
    }

    function getChildInventoryPositionIds() external view virtual returns (uint256[] memory childPositionIds) {
        childPositionIds = _childInventoryPositionIds.values();
    }

    function getSpecificInventoryPositionFees(uint256 positionId_) external view virtual returns (uint256 balance) {
        balance = _NFTX_INVENTORY_STAKING.wethBalance(positionId_);
    }

    function getTotalInventoryPositionFees() external view virtual returns (uint256 balance) {
        unchecked {
            if (inventoryPositionId != 0) balance += _NFTX_INVENTORY_STAKING.wethBalance(inventoryPositionId);
        }
        uint256[] memory childPositionIds = _childInventoryPositionIds.values();
        for (uint256 i; i < childPositionIds.length; ++i) {
            unchecked {
                balance += _NFTX_INVENTORY_STAKING.wethBalance(childPositionIds[i]);
            }
        }
    }

    function inventoryVTokenDeposit(uint256 vTokenAmount) external payable virtual onlyOwner {
        uint256 _positionId = _NFTX_INVENTORY_STAKING.deposit(
            vaultId,
            vTokenAmount,
            address(this),
            "",
            false,
            true
        );
        if (inventoryPositionId == 0) inventoryPositionId = _positionId;
        else _childInventoryPositionIds.add(_positionId);
    }

    function inventoryNftDeposit(uint256[] calldata tokenIds, uint256[] calldata amounts) external payable virtual onlyOwner {
        uint256 _positionId = _NFTX_INVENTORY_STAKING.depositWithNFT(vaultId, tokenIds, amounts, address(this));
        if (inventoryPositionId == 0) inventoryPositionId = _positionId;
        else _childInventoryPositionIds.add(_positionId);
    }

    function inventoryPositionIncrease(uint256 vTokenAmount) external payable virtual onlyOwner {
        uint256 _positionId = inventoryPositionId;
        if (_positionId == 0) revert AV_NoPosition();
        _NFTX_INVENTORY_STAKING.increasePosition(_positionId, vTokenAmount, "", false, true);
    }

    function inventoryPositionWithdrawal(uint256 positionId_, uint256 vTokenAmount, uint256[] calldata tokenIds, uint256 vTokenPremiumLimit) external payable virtual onlyOwner {
        _NFTX_INVENTORY_STAKING.withdraw(positionId_, vTokenAmount, tokenIds, vTokenPremiumLimit);
    }

    function inventoryCombinePositions(uint256[] calldata childPositionIds) external payable virtual onlyOwner {
        _NFTX_INVENTORY_STAKING.combinePositions(inventoryPositionId, childPositionIds);
    }

    function inventoryPositionCollectFees(uint256[] calldata positionIds) external payable virtual onlyOwner {
        _NFTX_INVENTORY_STAKING.collectWethFees(positionIds);
    }

    function inventoryPositionCollectAllFees() external payable virtual onlyOwner {
        uint256 _inventoryPositionId = inventoryPositionId;
        uint256[] memory childPositionIds = _childInventoryPositionIds.values();
        uint256 positionCount;
        unchecked {
            if (_inventoryPositionId != 0) ++positionCount;
            positionCount += childPositionIds.length;
        }
        uint256[] memory positionIds = new uint256[](positionCount);
        if (_inventoryPositionId != 0) positionIds[0] = _inventoryPositionId;
        for (uint256 i = 1; i < positionCount; ++i) {
            positionIds[i] = childPositionIds[i - 1];
        }
        _NFTX_INVENTORY_STAKING.collectWethFees(positionIds);
    }

    function rescueERC20(address token, uint256 amount, address recipient) external payable virtual onlyOwner {
        if (token == address(vault) || token == address(_WETH)) revert AV_ProhibitedWithdrawal();
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

    function wrapEth() external payable virtual {
        uint256 balance = address(this).balance;
        if (balance > 0) _WETH.deposit{value: balance}();
    }

    function onERC721Received(address, address, uint256 tokenId, bytes memory) public virtual override(ERC721Holder, IAlignmentVault) returns (bytes4 magicBytes) {
        if (msg.sender != alignedNft) revert AV_UnalignedNft();
        else {
            _nftsHeld.add(tokenId);
            emit AV_ReceivedAlignedNft(tokenId, 1);
        }
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256 tokenId,
        uint256 amount,
        bytes memory
    ) public virtual override(ERC1155Holder, IAlignmentVault) returns (bytes4) {
        if (msg.sender != alignedNft) revert AV_UnalignedNft();
        else {
            _nftsHeld.add(tokenId);
            unchecked {
                _erc1155Balances[tokenId] += amount;
            }
            emit AV_ReceivedAlignedNft(tokenId, amount);
        }
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory
    ) public virtual override(ERC1155Holder, IAlignmentVault) returns (bytes4) {
        if (msg.sender != alignedNft) revert AV_UnalignedNft();
        else {
            for (uint256 i; i < tokenIds.length; ++i) {
                _nftsHeld.add(tokenIds[i]);
                unchecked {
                    _erc1155Balances[tokenIds[i]] += amounts[i];
                }
                emit AV_ReceivedAlignedNft(tokenIds[i], amounts[i]);
            }
        }
        return this.onERC1155BatchReceived.selector;
    }

    receive() external payable virtual {
        _WETH.deposit{value: address(this).balance}();
    }

    fallback() external payable virtual {
        _WETH.deposit{value: address(this).balance}();
    }
}