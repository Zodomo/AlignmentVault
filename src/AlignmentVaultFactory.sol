// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

// Importing necessary libraries
import "../lib/solady/src/utils/LibClone.sol";
import "../lib/solady/src/auth/Ownable.sol";

// Interface for Alignment Vault initialization
interface IAVInitialize {
    function initialize(address _erc721, address _owner, uint256 _vaultId) external;
    function disableInitializers() external;
}

/**
 * @title AlignmentVaultFactory
 * @notice This contract is used to deploy AlignmentVault contracts.
 * @dev This contract allows for both normal and deterministic deployment of AlignmentVault contracts.
 * @dev AlignmentVault contracts are used to store ERC721 tokens in a deterministic way.
 * @author Zodomo.eth (X: @0xZodomo, Telegram: @zodomo, GitHub: Zodomo, Email: zodomo@proton.me)
 */
contract AlignmentVaultFactory is Ownable {
    // Events
    event Deployed(address indexed deployer, address indexed vault);
    event Implementation(address indexed implementation);

    // State variables
    address public implementation; // Address of the implementation contract
    mapping(address => address) public vaultDeployers; // Mapping to track deployer of each vault

    // Constructor
    constructor(address _owner, address _implementation) payable {
        _initializeOwner(_owner);
        implementation = _implementation;
        emit Implementation(_implementation);
    }

    /**
     * @notice Updates the implementation address used for new clones.
     * @dev This function allows the contract owner to update the implementation contract.
     * @param _implementation The new implementation address for clones.
     */
    function updateImplementation(address _implementation) external virtual onlyOwner {
        if (_implementation == implementation) revert();
        implementation = _implementation;
        emit Implementation(_implementation);
    }

    /**
     * @notice Deploys a new AlignmentVault and fully initializes it.
     * @dev This function deploys a new AlignmentVault contract and initializes it with the provided parameters.
     * @param _erc721 Address of the ERC721 token associated with the vault.
     * @param _vaultId NFTX Vault ID associated with _erc721
     * @return deployment Address of the newly deployed AlignmentVault.
     */
    function deploy(address _erc721, uint256 _vaultId) external virtual returns (address deployment) {
        deployment = LibClone.clone(implementation);
        vaultDeployers[deployment] = msg.sender;
        IAVInitialize(deployment).initialize(_erc721, msg.sender, _vaultId);
        IAVInitialize(deployment).disableInitializers();
        emit Deployed(msg.sender, deployment);
    }

    /**
     * @notice Deploys a new AlignmentVault to a deterministic address based on the provided salt.
     * @dev This function allows deploying a new AlignmentVault to a deterministic address.
     * @param _erc721 Address of the ERC721 token associated with the vault.
     * @param _vaultId NFTX Vault ID associated with _erc721
     * @param _salt A unique salt to determine the address.
     * @return deployment Address of the newly deployed AlignmentVault.
     */
    function deployDeterministic(address _erc721, uint256 _vaultId, bytes32 _salt)
        external
        virtual
        returns (address deployment)
    {
        deployment = LibClone.cloneDeterministic(implementation, _salt);
        vaultDeployers[deployment] = msg.sender;
        IAVInitialize(deployment).initialize(_erc721, msg.sender, _vaultId);
        IAVInitialize(deployment).disableInitializers();
        emit Deployed(msg.sender, deployment);
    }

    /**
     * @notice Returns the initialization code hash of the clone of the implementation.
     * @dev This function returns the hash of the initialization code used in cloning.
     * @return codeHash The initialization code hash of the clone.
     */
    function initCodeHash() external view returns (bytes32 codeHash) {
        return LibClone.initCodeHash(implementation);
    }

    /**
     * @notice Predicts the address of the deterministic clone with the given salt.
     * @dev This function predicts the address of a deterministic clone using the provided salt.
     * @param _salt The unique salt used to determine the address.
     * @return addr Address of the deterministic clone.
     */
    function predictDeterministicAddress(bytes32 _salt) external view returns (address addr) {
        return LibClone.predictDeterministicAddress(implementation, _salt, address(this));
    }
}
