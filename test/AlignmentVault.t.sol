// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

// Import statements for external contracts and libraries
import {Test, console2} from "../lib/forge-std/src/Test.sol";
import {AlignmentVault} from "../src/AlignmentVault.sol";
import {IAlignmentVault} from "../src/IAlignmentVault.sol";
import {FixedPointMathLib} from "../lib/solady/src/utils/FixedPointMathLib.sol";
import {IWETH9} from "../lib/nftx-protocol-v3/src/uniswap/v3-periphery/interfaces/external/IWETH9.sol";
import {IERC20} from "../lib/openzeppelin-contracts-v5/contracts/interfaces/IERC20.sol";
import {IERC721} from "../lib/openzeppelin-contracts-v5/contracts/interfaces/IERC721.sol";
import {IERC721Enumerable} from "../lib/openzeppelin-contracts-v5/contracts/interfaces/IERC721Enumerable.sol";
import {IERC1155} from "../lib/openzeppelin-contracts-v5/contracts/interfaces/IERC1155.sol";
import {INFTXVaultFactoryV3} from "../lib/nftx-protocol-v3/src/interfaces/INFTXVaultFactoryV3.sol";
import {INFTXVaultV3} from "../lib/nftx-protocol-v3/src/interfaces/INFTXVaultV3.sol";
import {INFTXInventoryStakingV3} from "../lib/nftx-protocol-v3/src/interfaces/INFTXInventoryStakingV3.sol";
import {INonfungiblePositionManager} from "../lib/nftx-protocol-v3/src/uniswap/v3-periphery/interfaces/INonfungiblePositionManager.sol";
import {INFTXRouter} from "../lib/nftx-protocol-v3/src/interfaces/INFTXRouter.sol";
import {ISwapRouter} from "../lib/nftx-protocol-v3/src/uniswap/v3-periphery/interfaces/ISwapRouter.sol";

contract AlignmentVaultTest is Test {
    // Constants declaration
    uint256 private constant NFTX_STANDARD_FEE = 30000000000000000;
    IWETH9 public constant WETH = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    INFTXVaultFactoryV3 public constant NFTX_VAULT_FACTORY = INFTXVaultFactoryV3(0xC255335bc5aBd6928063F5788a5E420554858f01);
    INFTXInventoryStakingV3 public constant NFTX_INVENTORY_STAKING = INFTXInventoryStakingV3(0x889f313e2a3FDC1c9a45bC6020A8a18749CD6152);
    INonfungiblePositionManager public constant NPM = INonfungiblePositionManager(0x26387fcA3692FCac1C1e8E4E2B22A6CF0d4b71bF);
    INFTXRouter public constant NFTX_POSITION_ROUTER = INFTXRouter(0x70A741A12262d4b5Ff45C0179c783a380EebE42a);
    ISwapRouter public constant NFTX_SWAP_ROUTER = ISwapRouter(0x1703f8111B0E7A10e1d14f9073F53680d64277A3);

    // State variables declaration
    AlignmentVault public av;
    address public vault;
    uint256 public vaultId;
    address public alignedNft;

    uint256[] public none = new uint256[](0);
    int24 public constant MIN_TICK = -887272;
    int24 public constant MAX_TICK = 887272;
    uint24 public constant STANDARD_FEE = 3000;
    uint24 public constant FIVE_PERCENT = 50000;
    address public constant MILADY = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5;
    uint256 public constant VAULT_ID = 5;

    // Function to set up test environment
    function setUp() public virtual {
        av = new AlignmentVault();
        av.initialize(address(this), MILADY, VAULT_ID);
        av.disableInitializers();
        vm.deal(address(av), 10 ether);
        vault = av.vault();
        vaultId = VAULT_ID;
        alignedNft = MILADY;
        setApprovals();
    }

    // Fallback function to receive Ether
    receive() external payable {}

    // Function to set approvals
    function setApprovals() public {
        IERC721(alignedNft).setApprovalForAll(vault, true);
    }

    // Function to initialize the contract with specified parameters
    function targetInitialize(address alignedNft_, uint256 vaultId_) public {
        av = new AlignmentVault();
        vault = NFTX_VAULT_FACTORY.vault(vaultId_);
        vaultId = vaultId_;
        alignedNft = alignedNft_;

        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_VaultInitialized(vault, vaultId_);
        av.initialize(address(this), alignedNft_, vaultId_);
        av.disableInitializers();
        vm.deal(address(av), 10 ether);
        setApprovals();
    }

    // Function for lazy initialization based on provided alignedNft
    function lazyInitialize(address alignedNft_) public {
        av = new AlignmentVault();
        alignedNft = alignedNft_;
        address[] memory vaults = NFTX_VAULT_FACTORY.vaultsForAsset(alignedNft_);
        if (vaults.length == 0) revert IAlignmentVault.AV_NFTX_NoVaultsExist();

        for (uint256 i; i < vaults.length; ++i) {
            (uint256 mintFee, uint256 redeemFee, uint256 swapFee) = INFTXVaultV3(vaults[i]).vaultFees();
            if (mintFee != NFTX_STANDARD_FEE || redeemFee != NFTX_STANDARD_FEE || swapFee != NFTX_STANDARD_FEE) continue;
            else if (INFTXVaultV3(vaults[i]).manager() != address(0)) continue;
            else {
                vaultId = INFTXVaultV3(vaults[i]).vaultId();
                vault = vaults[i];
                break;
            }
        }

        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_VaultInitialized(vault, vaultId);
        av.initialize(address(this), alignedNft_, 0);
        av.disableInitializers();
        vm.deal(address(av), 10 ether);
        setApprovals();
    }

    // Function to transfer MILADY NFT from one address to another
    function transferMilady(address recipient, uint256 tokenId) public {
        address target = IERC721(MILADY).ownerOf(tokenId);
        vm.prank(target);
        IERC721(MILADY).transferFrom(target, recipient, tokenId);
    }

    // Function to mint vTokens
    function mintVToken(uint256[] memory tokenIds, uint256[] memory amounts) public payable {
        uint256 tokenCount;
        for (uint256 i; i < tokenIds.length; ++i) {
            unchecked {
                tokenCount += amounts[i];
            }
        }
        uint256 ethRequired = FixedPointMathLib.fullMulDivUp(INFTXVaultV3(vault).vTokenToETH(tokenCount * 1 ether), 30000, 1000000);
        INFTXVaultV3(vault).mint{value: ethRequired}(tokenIds, amounts, address(this), address(this));
    }

    // Function to test target initialization
    function testTargetInitialize() public {
        targetInitialize(MILADY, VAULT_ID);
        assertEq(av.vaultId(), VAULT_ID);
        assertEq(address(av.alignedNft()), MILADY);
    }

    // Function to test lazy initialization
    function testLazyInitialize() public {
        lazyInitialize(MILADY);
        assertEq(av.vaultId(), VAULT_ID);
        assertEq(address(av.alignedNft()), MILADY);
    }
}
