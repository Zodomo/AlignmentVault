// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

// >>>>>>>>>>>> [ IMPORTS ] <<<<<<<<<<<<

// Contracts
import {AlignmentVault} from "../src/AlignmentVault.sol";
import {FixedPointMathLib} from "../lib/solady/src/utils/FixedPointMathLib.sol";
import {AlignmentVaultFactory} from "./../src/AlignmentVaultFactory.sol";

// Libraries
import "../lib/forge-std/src/Test.sol";
import {Position} from "../lib/nftx-protocol-v3/src/uniswap/v3-core/libraries/Position.sol";
import {TickMath} from "../lib/nftx-protocol-v3/src/uniswap/v3-core/libraries/TickMath.sol";
import {LiquidityAmounts} from "../lib/nftx-protocol-v3/src/uniswap/v3-periphery/libraries/LiquidityAmounts.sol";
import {FullMath} from "../lib/nftx-protocol-v3/src/uniswap/v3-core/libraries/FullMath.sol";

// Interfaces
import {IAlignmentVault} from "../src/IAlignmentVault.sol";
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
import {IUniswapV3Pool} from "../lib/nftx-protocol-v3/src/uniswap/v3-core/interfaces/IUniswapV3Pool.sol";


contract AlignmentVaultTest is Test {
    uint256 public constant NFTX_STANDARD_FEE = 30_000_000_000_000_000;
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

    AlignmentVaultFactory public avf;
    AlignmentVault public av;
    address public vault;
    uint256 public vaultId;
    address public alignedNft;
    bytes32 public positionKey;
    address public positionManager;
    IUniswapV3Pool public pool;
    

    uint256[] public none = new uint256[](0);
    uint24 public constant STANDARD_FEE = 3000;
    uint24 public constant FIVE_PERCENT = 50_000;
    address public constant MILADY = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5;
    uint96 public constant VAULT_ID = 5;
    uint256 public constant FUNDING_AMOUNT = 100 ether;

    address deployer;
    address attacker;

    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);
    event AV_LiquidityPositionCreated(uint256 indexed positionId);

    function setUp() public virtual {
        vm.createSelectFork("mainnet");

        deployer = makeAddr("deployer");
        attacker = makeAddr("attacker");

        avf = new AlignmentVaultFactory(deployer, address(new AlignmentVault()));
        av = AlignmentVault(payable(avf.deploy(deployer, MILADY, VAULT_ID)));

        vm.label(address(av), "AlignmentVault");
        vm.label(address(MILADY), "Milady NFT");
        vm.label(address(NFTX_VAULT_FACTORY), "NFTX Vault Factory");
        vm.label(address(NFTX_SWAP_ROUTER), "NFTX Swap Router");
        vm.label(address(NFTX_POSITION_ROUTER), "NFTX Position Router");
        vm.label(address(NFTX_INVENTORY_STAKING), "NFTX Inventory Staking");

        vm.deal(address(av), FUNDING_AMOUNT);
        vm.deal(deployer, FUNDING_AMOUNT);
        vm.deal(address(this), FUNDING_AMOUNT);

        vault = av.vault();
        vaultId = VAULT_ID;
        alignedNft = MILADY;
        positionManager = address(NFTX_POSITION_ROUTER.positionManager());
        pool = _getPool();

        setApprovals();
    }

    modifier prank(address who) {
        vm.startPrank(who);
        _;
        vm.stopPrank();
    }

    receive() external payable {}

    function setApprovals() public prank(deployer) {
        IERC721(alignedNft).setApprovalForAll(vault, true);
    }

    function transferMilady(address recipient, uint256 tokenId) public {
        address target = IERC721(MILADY).ownerOf(tokenId);
        vm.prank(target);
        IERC721(MILADY).transferFrom(target, recipient, tokenId);
    }

    function mintVToken(
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        address depositor,
        address to
    ) public payable {
        uint256 tokenCount;
        for (uint256 i; i < tokenIds.length; ++i) {
            unchecked {
                tokenCount += amounts[i];
            }
        }
        uint256 ethRequired =
            FixedPointMathLib.fullMulDivUp(INFTXVaultV3(vault).vTokenToETH(tokenCount * 1 ether), 30_000, 1_000_000);
        INFTXVaultV3(vault).mint{value: ethRequired}(tokenIds, amounts, to, depositor);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //                   HELPER FUNCTIONS
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    /// @dev foundry's changePrank() is deprecated :(
    function _changePrank(address who) internal {
        vm.stopPrank();
        vm.startPrank(who);
    }

    function _getPool() internal view returns (IUniswapV3Pool) {
        (address poolAddress,,) = av.getUniswapPoolValues();

        return IUniswapV3Pool(poolAddress);
    }

    function _getCurrentTick() internal view returns (int24 tick) {
        (, tick,,,,,) = IUniswapV3Pool(pool).slot0();
    }

    function _getUpperLowerTicks() internal view returns (int24 tickUpper, int24 tickLower) {
        int24 tick = _getCurrentTick();
        int24 tick1 = tick + (tick / 10);
        int24 tick2 = tick - (tick / 10);

        tick1 = _conformTickSpacing(tick1);
        tick2 = _conformTickSpacing(tick2);

        (tickUpper, tickLower) = tick1 > tick2 ? (tick1, tick2) : (tick2, tick1);
    }

    function _conformTickSpacing(int24 tick) internal view returns (int24) {
        int24 spacing = pool.tickSpacing();
        return tick % spacing == 0 ? tick : tick - (tick % spacing);
    }

    function _getLiquidity(uint256 id) internal view returns (uint128 liquidity) {
        (,,,,,,, liquidity,,,,) = INonfungiblePositionManager(positionManager).positions(id);
    }

    function _getPositionTicks(uint256 id) internal view returns (int24 tickLower, int24 tickUpper) {
        (,,,,, tickLower, tickUpper,,,,,) = INonfungiblePositionManager(positionManager).positions(id);
    }

    function _buyVTokenFromPool(address trader, uint256 amount) internal {
        deal(address(WETH), trader, amount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(WETH),
            tokenOut: vault,
            fee: STANDARD_FEE,
            recipient: trader,
            deadline: block.timestamp,
            amountIn: amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        _changePrank(trader);
        WETH.approve(address(NFTX_SWAP_ROUTER), amount);
        NFTX_SWAP_ROUTER.exactInputSingle(params);
    }

    function _buyWethFromPool(address trader, uint256 amount) internal {
        deal(vault, trader, amount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: vault,
            tokenOut: address(WETH),
            fee: STANDARD_FEE,
            recipient: trader,
            deadline: block.timestamp,
            amountIn: amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        _changePrank(trader);
        IERC20(vault).approve(address(NFTX_SWAP_ROUTER), amount);
        NFTX_SWAP_ROUTER.exactInputSingle(params);
    }

    function _getLiquidityForAmounts(
        uint256 ethAmount,
        uint256 vTokenAmount,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (uint128 liquidity) {
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);

        (uint256 amount0, uint256 amount1) =
            address(vault) < address(WETH) ? (vTokenAmount, ethAmount) : (ethAmount, vTokenAmount);

        liquidity =
            LiquidityAmounts.getLiquidityForAmounts(sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96, amount0, amount1);
    }

    /// @dev refreshes position to get updated fee growth
    function _refreshPosition(int24 tickLower, int24 tickUpper) internal {
        _changePrank(positionManager);
        pool.burn(tickLower, tickUpper, 0);
    }
}
