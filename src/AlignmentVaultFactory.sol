// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "../lib/solady/src/utils/LibClone.sol";
import "../lib/solady/src/auth/Ownable.sol";

interface IInitialize {
    function initialize(address _erc721, address _owner, uint256 _vaultId) external;
    function disableInitializers() external;
}

/**
 * @title AlignmentVaultFactory
 * @notice This can be used by any EOA or contract to deploy an AlignmentVault owned by the deployer.
 * @dev deploy() will perform a normal deployment. deployDeterministic() allows you to mine a deployment address.
 * @author Zodomo.eth (X: @0xZodomo, Telegram: @zodomo, GitHub: Zodomo, Email: zodomo@proton.me)
 */
contract AlignmentVaultFactory is Ownable {
    event Deployed(address indexed deployer, address indexed vault);

    address public implementation;
    // Vault address => deployer address
    mapping(address => address) public vaultDeployers;

    constructor(address _owner, address _implementation) payable {
        _initializeOwner(_owner);
        implementation = _implementation;
    }

    /**
     * @notice Updates the implementation address used for new clones.
     * @dev Does not affect previously deployed clones.
     * @param _implementation The new implementation address for clones.
     */
    function updateImplementation(address _implementation) external virtual onlyOwner {
        if (_implementation == implementation) revert();
        implementation = _implementation;
    }

    /**
     * @notice Deploys a new AlignmentVault and fully initializes it.
     * @param _erc721 Address of the ERC721 token associated with the vault.
     * @param _vaultId NFTX Vault ID associated with _erc721
     * @return deployment Address of the newly deployed AlignmentVault.
     */
    function deploy(address _erc721, uint256 _vaultId) external virtual returns (address deployment) {
        deployment = LibClone.clone(implementation);
        vaultDeployers[deployment] = msg.sender;
        emit Deployed(msg.sender, deployment);

        IInitialize(deployment).initialize(_erc721, msg.sender, _vaultId);
        IInitialize(deployment).disableInitializers();
    }

    /**
     * @notice Deploys a new AlignmentVault to a deterministic address based on the provided salt.
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
        emit Deployed(msg.sender, deployment);

        IInitialize(deployment).initialize(_erc721, msg.sender, _vaultId);
        IInitialize(deployment).disableInitializers();
    }

    /**
     * @notice Returns the initialization code hash of the clone of the implementation.
     * @dev This is used primarily for tools like create2crunch to find vanity addresses.
     * @return codeHash The initialization code hash of the clone.
     */
    function initCodeHash() external view returns (bytes32 codeHash) {
        return LibClone.initCodeHash(implementation);
    }

    /**
     * @notice Predicts the address of the deterministic clone with the given salt.
     * @param _salt The unique salt used to determine the address.
     * @return addr Address of the deterministic clone.
     */
    function predictDeterministicAddress(bytes32 _salt) external view returns (address addr) {
        return LibClone.predictDeterministicAddress(implementation, _salt, address(this));
    }
}
