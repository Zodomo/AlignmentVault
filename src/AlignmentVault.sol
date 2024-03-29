// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {Ownable} from "../lib/solady/src/auth/Ownable.sol";
import {Initializable} from "../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {IAlignmentVault} from "./IAlignmentVault.sol";
import {EnumerableSet} from "../lib/openzeppelin-contracts-v5/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IERC721} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import {INFTXVaultFactoryV3} from "../lib/nftx-protocol-v3/src/interfaces/INFTXVaultFactoryV3.sol";
import {INFTXVaultV3} from "../lib/nftx-protocol-v3/src/interfaces/INFTXVaultV3.sol";
import {INFTXRouter} from "../lib/nftx-protocol-v3/src/interfaces/INFTXRouter.sol";
import {IWETH9} from "../lib/nftx-protocol-v3/src/uniswap/v3-periphery/interfaces/external/IWETH9.sol";

/**
 * @title AlignmentVault
 * @notice This allows anything to send ETH to a vault for the purpose of permanently deepening the floor liquidity of a target NFT collection.
 * While the liquidity is locked forever, the yield can be claimed indefinitely.
 * @dev You must initialize this contract once deployed! There is a factory for this, use it!
 * @author Zodomo.eth (Farcaster/Telegram/Discord/Github: @zodomo, X: @0xZodomo, Email: zodomo@proton.me)
 * @custom:github https://github.com/Zodomo/AlignmentVault
 * @custom:miyamaker https://miyamaker.com
 */
contract AlignmentVault is Ownable, Initializable, IAlignmentVault {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 private constant _NFTX_STANDARD_FEE = 30000000000000000;

    IWETH9 private constant _WETH = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    INFTXVaultFactoryV3 private constant _NFTX_VAULT_FACTORY = INFTXVaultFactoryV3(0xC255335bc5aBd6928063F5788a5E420554858f01);

    EnumerableSet.UintSet private _nftsHeld;

    uint256 public vaultId;
    address public alignedNft;

    constructor() payable {}

    function initialize(
        address _owner,
        address _alignedNft,
        uint256 _vaultId
    ) external payable virtual initializer {
        _initializeOwner(_owner);
        alignedNft = _alignedNft;
        if (_vaultId != 0) {
            try _NFTX_VAULT_FACTORY.vault(_vaultId) returns (address vaultNft) {
                if (INFTXVaultV3(vaultNft).assetAddress() != _alignedNft) revert AV_NFTX_InvalidVaultNft();
                vaultId = _vaultId;
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
                    _vaultId = INFTXVaultV3(vaults[i]).vaultId();
                    vaultId = _vaultId;
                    break;
                }
            }
            if (_vaultId == 0) revert AV_NFTX_NoStandardVault();
        }
    }

    function disableInitializers() external payable virtual {
        _disableInitializers();
    }

    function getInventory() external view virtual returns (uint256[] memory) {
        return _nftsHeld.values();
    }

    function wrapEth() public payable virtual {
        uint256 balance = address(this).balance;
        if (balance > 0) _WETH.deposit{value: balance}();
    }

    receive() external payable virtual {
        wrapEth();
    }

    fallback() external payable virtual {
        wrapEth();
    }

    function onERC721Received(address, address, uint256 _tokenId, bytes calldata) external virtual returns (bytes4 magicBytes) {
        if (msg.sender != alignedNft) revert AV_UnalignedNft();
        else {
            _nftsHeld.add(_tokenId);
            emit AV_ReceivedAlignedNft(_tokenId);
        }
        return AlignmentVault.onERC721Received.selector;
    }
}