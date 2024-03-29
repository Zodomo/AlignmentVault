// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {Ownable} from "../lib/solady/src/auth/Ownable.sol";
import {Initializable} from "../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IERC721} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import {INFTXVaultFactoryV3} from "../lib/nftx-protocol-v3/src/interfaces/INFTXVaultFactoryV3.sol";
import {INFTXVaultV3} from "../lib/nftx-protocol-v3/src/interfaces/INFTXVaultV3.sol";

/**
 * @title AlignmentVault
 * @notice This allows anything to send ETH to a vault for the purpose of permanently deepening the floor liquidity of a target NFT collection.
 * While the liquidity is locked forever, the yield can be claimed indefinitely.
 * @dev You must initialize this contract once deployed! There is a factory for this, use it!
 * @author Zodomo.eth (Farcaster/Telegram/Discord/Github: @zodomo, X: @0xZodomo, Email: zodomo@proton.me)
 * @custom:github https://github.com/Zodomo/AlignmentVault
 * @custom:miyamaker https://miyamaker.com
 */
contract AlignmentVault is Ownable, Initializable {
    error AV_NFTX_NoVaultsExist();
    error AV_NFTX_InvalidVaultId();
    error AV_NFTX_InvalidVaultNFT();
    error AV_NFTX_NoStandardVault();

    uint256 private constant NFTX_STANDARD_FEE = 30000000000000000;

    INFTXVaultFactoryV3 private constant NFTX_VAULT_FACTORY = INFTXVaultFactoryV3(0xC255335bc5aBd6928063F5788a5E420554858f01);

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
            try NFTX_VAULT_FACTORY.vault(_vaultId) {
                address vaultNft = NFTX_VAULT_FACTORY.vault(_vaultId);
                if (vaultNft != _alignedNft) revert AV_NFTX_InvalidVaultNFT();
                vaultId = _vaultId;
            } catch {
                revert AV_NFTX_InvalidVaultId();
            }
        } else {
            address[] memory vaults = NFTX_VAULT_FACTORY.vaultsForAsset(_alignedNft);
            if (vaults.length == 0) revert AV_NFTX_NoVaultsExist();
            for (uint256 i; i < vaults.length; ++i) {
                (uint256 mintFee, uint256 redeemFee, uint256 swapFee) = INFTXVaultV3(vaults[i]).vaultFees();
                if (mintFee != NFTX_STANDARD_FEE || redeemFee != NFTX_STANDARD_FEE || swapFee != NFTX_STANDARD_FEE) continue;
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
}