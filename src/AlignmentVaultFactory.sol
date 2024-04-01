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

interface IInitialize {
    function initialize(
        address _owner,
        address _alignedNft,
        uint256 _vaultId
    ) external payable;
    function disableInitializers() external payable;
}

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

    // Mapping to store the deployer of each AlignmentVault
    mapping(address => address) public vaultDeployers;
    // Address of the implementation contract used for cloning AlignmentVault instances
    address public implementation;

    // >>>>>>>>>>>> [ CONSTRUCTOR ] <<<<<<<<<<<<

    /**
     * @notice Constructs the AlignmentVaultFactory contract.
     * @param owner_ Address of the initial owner of the factory.
     * @param implementation_ Address of the implementation contract for AlignmentVaults.
     */
    constructor(address owner_, address implementation_) payable {
        _initializeOwner(owner_);
        implementation = implementation_;
        emit AVF_ImplementationSet(implementation_);
    }

    // >>>>>>>>>>>> [ DEPLOYMENT FUNCTIONS ] <<<<<<<<<<<<

    /**
     * @notice Deploys a new AlignmentVault and fully initializes it.
     * @param alignedNft Address of the ERC721/1155 token associated with the vault.
     * @param vaultId NFTX Vault ID associated with alignedNft.
     * @return deployment Address of the newly deployed AlignmentVault.
     */
    function deploy(address alignedNft, uint256 vaultId) external payable virtual returns (address deployment) {
        // Clone the implementation contract
        deployment = LibClone.clone(implementation);
        // Record the deployer of the new vault
        vaultDeployers[deployment] = msg.sender;
        // Initialize the newly deployed vault
        IInitialize(deployment).initialize(msg.sender, alignedNft, vaultId);
        // Disable initializers
        IInitialize(deployment).disableInitializers();
        // Emit an event indicating the deployment
        emit AVF_Deployed(msg.sender, deployment);
    }

    /**
     * @notice Deploys a new AlignmentVault to a deterministic address based on the provided salt.
     * @param alignedNft Address of the ERC721/1155 token associated with the vault.
     * @param vaultId NFTX Vault ID associated with alignedNft.
     * @param salt A unique salt to determine the address.
     * @return deployment Address of the newly deployed AlignmentVault.
     */
    function deployDeterministic(address alignedNft, uint256 vaultId, bytes32 salt)
        external
        payable
        virtual
        returns (address deployment)
    {
        // Clone the implementation contract deterministically
        deployment = LibClone.cloneDeterministic(implementation, salt);
        // Record the deployer of the new vault
        vaultDeployers[deployment] = msg.sender;
        // Initialize the newly deployed vault
        IInitialize(deployment).initialize(msg.sender, alignedNft, vaultId);
        // Disable initializers
        IInitialize(deployment).disableInitializers();
        // Emit an event indicating the deployment
        emit AVF_Deployed(msg.sender, deployment);
    }

    /**
     * @notice Returns the initialization code hash of the clone of the implementation.
     * @dev This is used primarily for tools like create2crunch to find vanity addresses.
     * @return codeHash The initialization code hash of the clone.
     */
    function initCodeHash() external view virtual returns (bytes32 codeHash) {
        // Retrieve the initialization code hash of the implementation contract
        return LibClone.initCodeHash(implementation);
    }

    /**
     * @notice Predicts the address of the deterministic clone with the given salt.
     * @param salt The unique salt used to determine the address.
     * @return addr Address of the deterministic clone.
     */
    function predictDeterministicAddress(bytes32 salt) external view virtual returns (address addr) {
        // Predict the address of the deterministic clone using the salt and factory address
        return LibClone.predictDeterministicAddress(implementation, salt, address(this));
    }

    // >>>>>>>>>>>> [ MANAGEMENT FUNCTIONS ] <<<<<<<<<<<<

    /**
     * @notice Updates the implementation address used for new clones.
     * @dev Does not affect previously deployed clones.
     * @param newImplementation The new implementation address for clones.
     */
    function updateImplementation(address newImplementation) external payable virtual onlyOwner {
        // Ensure the new implementation address is different from the current one
        if (newImplementation == implementation) return;
        // Update the implementation address
        implementation = newImplementation;
        // Emit an event indicating the change
        emit AVF_ImplementationSet(newImplementation);
    }

    /**
     * @notice Used to withdraw any ETH sent to the factory
     * @param recipient Address to which ETH will be transferred.
     */
    function withdrawEth(address recipient) external payable virtual onlyOwner {
        // Transfer ETH to the recipient
        (bool success,) = payable(recipient).call{value: address(this).balance}("");
        if (!success) revert AVF_WithdrawalFailed();
    }

    /**
     * @notice Used to withdraw any ERC20 tokens sent to the factory
     * @param token Address of the ERC20 token to withdraw.
     * @param recipient Address to which ERC20 tokens will be transferred.
     */
    function withdrawERC20(address token, address recipient) external payable virtual onlyOwner {
        // Transfer ERC20 tokens to the recipient
        IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
    }

    /**
     * @notice Used to withdraw any ERC721 tokens sent to the factory
     * @param token Address of the ERC721 token to withdraw.
     * @param tokenId ID of the ERC721 token to withdraw.
     * @param recipient Address to which ERC721 tokens will be transferred.
     */
    function withdrawERC721(address token, uint256 tokenId, address recipient) external payable virtual onlyOwner {
        // Transfer ERC721 token to the recipient
        IERC721(token).transferFrom(address(this), recipient, tokenId);
    }

    /**
     * @notice Used to withdraw any ERC1155 tokens sent to the factory
     * @param token Address of the ERC1155 token to withdraw.
     * @param tokenId ID of the ERC1155 token to withdraw.
     * @param amount Amount of ERC1155 tokens to withdraw.
     * @param recipient Address to which ERC1155 tokens will be transferred.
     */
    function withdrawERC1155(address token, uint256 tokenId, uint256 amount, address recipient) external payable virtual onlyOwner {
        // Transfer ERC1155 tokens to the recipient
        IERC1155(token).safeTransferFrom(address(this), recipient, tokenId, amount, "");
    }

    /**
     * @notice Used to batch withdraw any ERC1155 tokens sent to the factory
     * @param token Address of the ERC1155 token to withdraw.
     * @param tokenIds Array of IDs of the ERC1155 tokens to withdraw.
     * @param amounts Array of amounts of ERC1155 tokens to withdraw corresponding to tokenIds.
     * @param recipient Address to which ERC1155 tokens will be transferred.
     */
    function withdrawERC1155Batch(address token, uint256[] calldata tokenIds, uint256[] calldata amounts, address recipient) external payable virtual onlyOwner {
        // Batch transfer ERC1155 tokens to the recipient
        IERC1155(token).safeBatchTransferFrom(address(this), recipient, tokenIds, amounts, "");
    }
}
