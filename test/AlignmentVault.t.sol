// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import "../lib/forge-std/src/Test.sol";
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
import {INonfungiblePositionManager} from
    "../lib/nftx-protocol-v3/src/uniswap/v3-periphery/interfaces/INonfungiblePositionManager.sol";
import {INFTXRouter} from "../lib/nftx-protocol-v3/src/interfaces/INFTXRouter.sol";
import {ISwapRouter} from "../lib/nftx-protocol-v3/src/uniswap/v3-periphery/interfaces/ISwapRouter.sol";

contract AlignmentVaultTest is Test {
    uint256 private constant NFTX_STANDARD_FEE = 30000000000000000;
    IWETH9 public constant WETH = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    //@audit  is upgradable
    //@audit pay attention to this integration
    INFTXVaultFactoryV3 public constant NFTX_VAULT_FACTORY =
        INFTXVaultFactoryV3(0xC255335bc5aBd6928063F5788a5E420554858f01);
    //@audit  is upgradable
    //@audit Allows users to stake vTokens to earn fees in vTokens and WETH. The position is minted as xNFT.
    INFTXInventoryStakingV3 public constant NFTX_INVENTORY_STAKING =
        INFTXInventoryStakingV3(0x889f313e2a3FDC1c9a45bC6020A8a18749CD6152);

    //@audit Wraps Uniswap V3 positions in the ERC721 non-fungible token interface
    INonfungiblePositionManager public constant NPM =
        INonfungiblePositionManager(0x26387fcA3692FCac1C1e8E4E2B22A6CF0d4b71bF);
    //@audit  Router to facilitate vault tokens minting/burning + addition/removal of concentrated liquidity
    INFTXRouter public constant NFTX_POSITION_ROUTER = INFTXRouter(0x70A741A12262d4b5Ff45C0179c783a380EebE42a);
    //@audit Router for stateless execution of swaps against Uniswap V3
    ISwapRouter public constant NFTX_SWAP_ROUTER = ISwapRouter(0x1703f8111B0E7A10e1d14f9073F53680d64277A3);

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

    address deployer;
    address attacker;

    function setUp() public virtual {
        vm.createSelectFork("mainnet");
        av = new AlignmentVault();
        vm.label(address(av), "AlignmentVault");
        vm.label(address(MILADY), "Milady NFT");
        vm.label(address(NFTX_VAULT_FACTORY), "NFTX Vault Factory");
        vm.label(address(NFTX_SWAP_ROUTER), "NFTX Swap Router");
        vm.label(address(NFTX_POSITION_ROUTER), "NFTX Position Router");
        vm.label(address(NFTX_INVENTORY_STAKING), "NFTX Inventory Staking");
        deployer = makeAddr("deployer");
        attacker = makeAddr("attacker");

        vm.deal(address(av), 10 ether);

        vm.startPrank(deployer);
        vault = av.vault();
        vaultId = VAULT_ID;
        alignedNft = MILADY;
        setApprovals();
        vm.stopPrank();
    }

    modifier prank(address who) {
        vm.startPrank(who);
        _;
        vm.stopPrank();
    }

    receive() external payable {}

    function setApprovals() public {
        IERC721(alignedNft).setApprovalForAll(vault, true);
    }

    function transferMilady(address recipient, uint256 tokenId) public {
        address target = IERC721(MILADY).ownerOf(tokenId);
        vm.prank(target);
        IERC721(MILADY).transferFrom(target, recipient, tokenId);
    }

    function mintVToken(uint256[] memory tokenIds, uint256[] memory amounts) public payable {
        uint256 tokenCount;
        for (uint256 i; i < tokenIds.length; ++i) {
            unchecked {
                tokenCount += amounts[i];
            }
        }
        uint256 ethRequired =
            FixedPointMathLib.fullMulDivUp(INFTXVaultV3(vault).vTokenToETH(tokenCount * 1 ether), 30000, 1000000);
        INFTXVaultV3(vault).mint{value: ethRequired}(tokenIds, amounts, address(this), address(this));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //                  INIT LOGIC
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function lazyInitialize(address alignedNft_) public {
        av = new AlignmentVault();
        alignedNft = alignedNft_;
        address[] memory vaults = NFTX_VAULT_FACTORY.vaultsForAsset(alignedNft_);
        if (vaults.length == 0) revert IAlignmentVault.AV_NFTX_NoVaultsExist();

        for (uint256 i; i < vaults.length; ++i) {
            (uint256 mintFee, uint256 redeemFee, uint256 swapFee) = INFTXVaultV3(vaults[i]).vaultFees();
            if (mintFee != NFTX_STANDARD_FEE || redeemFee != NFTX_STANDARD_FEE || swapFee != NFTX_STANDARD_FEE) {
                continue;
            } else if (INFTXVaultV3(vaults[i]).manager() != address(0)) {
                continue;
            } else {
                vaultId = INFTXVaultV3(vaults[i]).vaultId();
                vault = vaults[i];
                break;
            }
        }

        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_VaultInitialized(vault, vaultId);
        //@audit what does it mean when vault id is zero?
        av.initialize(address(this), alignedNft_, 0);
        av.disableInitializers();
        vm.deal(address(av), 10 ether);
        setApprovals();
    }

    function targetInitialize(address alignedNft_, uint256 vaultId_) public {
        console2.log("alignment vault: ", address(av));
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

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //                  RECEIVE LOGIC
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function testRescueERC20() public {
        av.rescueERC20(address(0), 1, address(0));
    }

    function testRescueERC1155() public {
        av.rescueERC1155(address(0), 1, 1, address(0));
    }

    function testRescueERC721() public {
        av.rescueERC721(address(0), 1, address(0));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //                  ALIGNED TOKEN MANAGEMENT
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function testBuyNftsFromPool() public {}
    function testMintVToken() public {}
    function testBuyVToken() public {}
    function testBuyVTokenExact() public {}
    function testSellVToken() public {}
    function testSellVTokenExact() public {}
    function testUnwrapEth() public {}

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //                  LIQUIDITY POSITION MANAGEMENT
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function testliquidityPositionCreatename() public {}
    function testliquidityPositionIncrease() public {}

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //                  INVENTORY POSITION MANAGEMENT
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function testInventoryPositionCreateVToken() public {}
    function testInventoryPositionCreateNfts() public {}
    function testInventoryPositionIncrease() public {}
    function testInventoryPositionWithdrawal() public {}
    function testInventoryPositionCombine() public {}
    function testInventoryPositionCollectFees() public {}
    function testInventoryPositionCollectAllFees() public {}

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //                  EXTERNAL DONATION MANAGEMENT
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function testDonateInventoryPositionIncrease() public {}
    function testDonateInventoryCombinePositions() public {}
    function testDonateLiquidityPositionIncrease() public {}
    function testDonateLiquidityCombinePositions() public {}
    function testDonateBuyNftsFromPool() public {}
    function testDonateMintVToken() public {}

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //                  VIEW FUNCTIONS
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function testGetInventoryPositionIds() public view {
        av.getInventoryPositionIds();
    }

    function testGetLiquidityPositionIds() public view {
        av.getLiquidityPositionIds();
    }

    function testGetSpecificInventoryPositionFees(uint256 posId) public view {
        av.getSpecificInventoryPositionFees(posId);
    }

    function testGetTotalInventoryPositionFees() public view {
        av.getTotalInventoryPositionFees();
    }

    function testGetSpecificLiquidityPositionFees(uint256 id) public view {
        av.getSpecificLiquidityPositionFees(id);
    }

    function testGetTotalLiquidityPositionFees() public view {
        av.getTotalLiquidityPositionFees();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //                  INIT LOGIC
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function testTargetInitialize() public {
        targetInitialize(MILADY, VAULT_ID);
        assertEq(av.vaultId(), VAULT_ID);
        assertEq(address(av.alignedNft()), MILADY);
    }

    function testLazyInitialize() public {
        lazyInitialize(MILADY);
        assertEq(av.vaultId(), VAULT_ID);
        assertEq(address(av.alignedNft()), MILADY);
    }
}
