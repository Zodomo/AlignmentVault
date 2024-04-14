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
    function initialize(address _owner, address _alignedNft, uint256 _vaultId) external payable;
    function disableInitializers() external payable;
}

/**
 * @title AlignmentVaultFactory
 * @notice This can be used by any EOA or contract to deploy an AlignmentVault owned by the deployer.
 * @dev deploy() will perform a normal deployment. deployDeterministic() allows you to mine a deployment address.
 * @author Zodomo.eth
 * @custom:github https://github.com/Zodomo/AlignmentVault
 * @custom:miyamaker https://miyamaker.com
 */
contract AlignmentVaultFactory is Ownable, IAlignmentVaultFactory {
    // Events
    event ImplementationUpdated(address indexed newImplementation);
    event ETHWithdrawn(address indexed recipient, uint256 amount);
    event ERC20Withdrawn(
        address indexed token,
        address indexed recipient,
        uint256 amount
    );
    event ERC721Withdrawn(
        address indexed token,
        address indexed recipient,
        uint256 tokenId
    );
    event ERC1155Withdrawn(
        address indexed token,
        address indexed recipient,
        uint256 tokenId,
        uint256 amount
    );
    event ERC1155BatchWithdrawn(
        address indexed token,
        address indexed recipient,
        uint256[] tokenIds,
        uint256[] amounts
    );

    // Storage Variables
    mapping(address => address) public vaultDeployers;
    address public implementation;

    // Constructor
    constructor(address owner_, address implementation_) payable {
        _initializeOwner(owner_);
        implementation = implementation_;
        emit ImplementationUpdated(implementation_);
    }

    // Access control modifier
    modifier onlyAdmin() {
        require(
            msg.sender == owner() || msg.sender == address(this),
            "Only owner or factory can call this function"
        );
        _;
    }

    // Deployment Functions

    function deploy(
        address alignedNft,
        uint256 vaultId
    ) external payable virtual override returns (address deployment) {
        deployment = LibClone.clone(implementation);
        vaultDeployers[deployment] = msg.sender;
        IInitialize(deployment).initialize(msg.sender, alignedNft, vaultId);
        IInitialize(deployment).disableInitializers();
        emit AVF_Deployed(msg.sender, deployment);
    }

    function deployDeterministic(
        address alignedNft,
        uint256 vaultId,
        bytes32 salt
    ) external payable virtual override returns (address deployment) {
        deployment = LibClone.cloneDeterministic(implementation, salt);
        vaultDeployers[deployment] = msg.sender;
        IInitialize(deployment).initialize(msg.sender, alignedNft, vaultId);
        IInitialize(deployment).disableInitializers();
        emit AVF_Deployed(msg.sender, deployment);
    }

    function initCodeHash()
        external
        view
        virtual
        override
        returns (bytes32 codeHash)
    {
        return LibClone.initCodeHash(implementation);
    }

    function predictDeterministicAddress(
        bytes32 salt
    ) external view virtual override returns (address addr) {
        return
            LibClone.predictDeterministicAddress(
                implementation,
                salt,
                address(this)
            );
    }

    // Management Functions

    function updateImplementation(
        address newImplementation
    ) external payable virtual override onlyAdmin {
        if (newImplementation == implementation) return;
        implementation = newImplementation;
        emit ImplementationUpdated(newImplementation);
    }

    function withdrawEth(
        address recipient
    ) external payable virtual override onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(recipient).transfer(balance);
        emit ETHWithdrawn(recipient, balance);
    }

    function withdrawERC20(
        address token,
        address recipient
    ) external payable virtual override onlyAdmin {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No ERC20 balance to withdraw");
        IERC20(token).transfer(recipient, balance);
        emit ERC20Withdrawn(token, recipient, balance);
    }

    function withdrawERC721(
        address token,
        uint256 tokenId,
        address recipient
    ) external payable virtual override onlyAdmin {
        IERC721(token).transferFrom(address(this), recipient, tokenId);
        emit ERC721Withdrawn(token, recipient, tokenId);
    }


    function withdrawERC1155(
        address token,
        uint256 tokenId,
        uint256 amount,
        address recipient
    ) external payable virtual override onlyAdmin {
        IERC1155(token).safeTransferFrom(
            address(this),
            recipient,
            tokenId,
            amount,
            ""
        );
        emit ERC1155Withdrawn(token, recipient, tokenId, amount);
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

    ) external payable virtual override onlyAdmin {
        IERC1155(token).safeBatchTransferFrom(
            address(this),
            recipient,
            tokenIds,
            amounts,
            ""
        );
        emit ERC1155BatchWithdrawn(token, recipient, tokenIds, amounts);

    ) external payable virtual onlyOwner {
        IERC1155(token).safeBatchTransferFrom(address(this), recipient, tokenIds, amounts, "");

    }
}
