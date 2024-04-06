// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

// Inheritance and Libraries
import {Ownable} from "../lib/solady/src/auth/Ownable.sol";
import {IAlignmentVaultFactory} from "./IAlignmentVaultFactory.sol";
import {LibClone} from "../lib/solady/src/utils/LibClone.sol";

// Interfaces
import {IERC20} from "../lib/openzeppelin-contracts-v5/contracts/interfaces/IERC20.sol";
import {IERC721} from "../lib/openzeppelin-contracts-v5/contracts/interfaces/IERC721.sol";
import {IERC1155} from "../lib/openzeppelin-contracts-v5/contracts/interfaces/IERC1155.sol";

import {IAlignmentVault} from "../src/IAlignmentVault.sol";
import {IWETH9} from "../lib/nftx-protocol-v3/src/uniswap/v3-periphery/interfaces/external/IWETH9.sol";

/**
 * @title AlignmentVaultFactory
 * @notice This can be used by any EOA or contract to deploy an AlignmentVault owned by the deployer.
 * @dev deploy() will perform a normal deployment. deployDeterministic() allows you to mine a deployment address.
 * @author Zodomo.eth (X: @0xZodomo, Telegram: @zodomo, GitHub: Zodomo, Email: zodomo@proton.me)
 * @custom:github https://github.com/Zodomo/AlignmentVault
 * @custom:miyamaker https://miyamaker.com
 */
contract AlignmentVaultFactory is Ownable, IAlignmentVaultFactory {
    // >>>>>>>>>>>> [ STORAGE VARIABLES ] <<<<<<<<<<<<

    IWETH9 private constant _WETH = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    mapping(address alignmentVault => address deployer) public vaultDeployers;
    address public implementation;

    // >>>>>>>>>>>> [ CONSTRUCTOR ] <<<<<<<<<<<<

    constructor(address owner_, address implementation_) payable {
        _initializeOwner(owner_);
        implementation = implementation_;
        emit AVF_ImplementationSet(implementation_);
    }

    // >>>>>>>>>>>> [ DEPLOYMENT FUNCTIONS ] <<<<<<<<<<<<

    /**
     * @notice Deploys a new AlignmentVault and fully initializes it.
     * @param alignedNft Address of the ERC721/1155 token associated with the vault.
     * @param vaultId NFTX Vault ID associated with alignedNft
     * @return deployment Address of the newly deployed AlignmentVault.
     */
    function deploy(address alignedNft, uint256 vaultId) external payable virtual returns (address deployment) {
        deployment = LibClone.clone(implementation);
        vaultDeployers[deployment] = msg.sender;
        IAlignmentVault(deployment).initialize(msg.sender, alignedNft, vaultId);
        IAlignmentVault(deployment).disableInitializers();
        emit AVF_Deployed(msg.sender, deployment);
    }

    /**
     * @notice Deploys a new AlignmentVault to a deterministic address based on the provided salt.
     * @param alignedNft Address of the ERC721/1155 token associated with the vault.
     * @param vaultId NFTX Vault ID associated with alignedNft
     * @param salt A unique salt to determine the address.
     * @return deployment Address of the newly deployed AlignmentVault.
     */
    function deployDeterministic(address alignedNft, uint256 vaultId, bytes32 salt)
        external
        payable
        virtual
        returns (address deployment)
    {
        deployment = LibClone.cloneDeterministic(implementation, salt);
        vaultDeployers[deployment] = msg.sender;
        IAlignmentVault(deployment).initialize(msg.sender, alignedNft, vaultId);
        IAlignmentVault(deployment).disableInitializers();
        emit AVF_Deployed(msg.sender, deployment);
    }

    /**
     * @notice Returns the initialization code hash of the clone of the implementation.
     * @dev This is used primarily for tools like create2crunch to find vanity addresses.
     * @return codeHash The initialization code hash of the clone.
     */
    function initCodeHash() external view virtual returns (bytes32 codeHash) {
        return LibClone.initCodeHash(implementation);
    }

    /**
     * @notice Predicts the address of the deterministic clone with the given salt.
     * @param salt The unique salt used to determine the address.
     * @return addr Address of the deterministic clone.
     */
    function predictDeterministicAddress(bytes32 salt) external view virtual returns (address addr) {
        return LibClone.predictDeterministicAddress(implementation, salt, address(this));
    }

    // >>>>>>>>>>>> [ MANAGEMENT FUNCTIONS ] <<<<<<<<<<<<

    /**
     * @notice Updates the implementation address used for new clones.
     * @dev Does not affect previously deployed clones.
     * @param newImplementation The new implementation address for clones.
     */
    function updateImplementation(address newImplementation) external payable virtual onlyOwner {
        if (newImplementation == implementation) return;
        implementation = newImplementation;
        emit AVF_ImplementationSet(newImplementation);
    }

    /**
     * @notice Used to withdraw any ETH sent to the factory
     */
    function withdrawEth(address recipient) external payable virtual onlyOwner {
        uint256 addressBal = address(this).balance;
        // the "WETH fallback" technique: if the call to transfer ETH failed, one can wrap the value in WETH. For example, from ZORA v3
        (bool success,) = payable(recipient).call{value: addressBal}("");
        if (!success) {
            _WETH.deposit{value: addressBal}();
            IERC20(address(_WETH)).transfer(recipient, addressBal);
        }
    }

    /**
     * @notice Used to withdraw any ERC20 tokens sent to the factory
     */
    function withdrawERC20(address token, address recipient) external payable virtual onlyOwner {
        IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
    }

    /**
     * @notice Used to withdraw any ERC721 tokens sent to the factory
     */
    function withdrawERC721(address token, uint256 tokenId, address recipient) external payable virtual onlyOwner {
        IERC721(token).transferFrom(address(this), recipient, tokenId);
    }

    /**
     * @notice Used to withdraw any ERC1155 tokens sent to the factory
     */
    function withdrawERC1155(address token, uint256 tokenId, uint256 amount, address recipient)
        external
        payable
        virtual
        onlyOwner
    {
        IERC1155(token).safeTransferFrom(address(this), recipient, tokenId, amount, "");
    }

    /**
     * @notice Used to batch withdraw any ERC1155 tokens sent to the factory
     */
    function withdrawERC1155Batch(
        address token,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        address recipient
    ) external payable virtual onlyOwner {
        IERC1155(token).safeBatchTransferFrom(address(this), recipient, tokenIds, amounts, "");
    }
}
