// SPDX-License-Identifier: VPL
pragma solidity ^0.8.20;

// Importing necessary contracts and interfaces
import "../solady/src/auth/Ownable.sol";
import "../openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../solidity-lib/contracts/libraries/TransferHelper.sol";
import "../v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "../v2-periphery/contracts/interfaces/IWETH.sol";
import "./UniswapV2Library.sol";

// Contract for providing helper functions for adding liquidity to Uniswap V2 pairs
contract UniswapV2LiquidityHelper is Ownable {
    // Immutable addresses for Uniswap V2 factory, router, and WETH
    address public immutable _uniswapV2FactoryAddress;
    address public immutable _uniswapV2Router02Address;
    address public immutable _wethAddress;

    // Constructor to set initial addresses
    constructor(
        address uniswapV2FactoryAddress,
        address uniswapV2Router02Address,
        address wethAddress
    ) payable {
        _uniswapV2FactoryAddress = uniswapV2FactoryAddress;
        _uniswapV2Router02Address = uniswapV2Router02Address;
        _wethAddress = wethAddress;
        _initializeOwner(msg.sender); // Initialize contract owner
    }

    // Fallback function to receive ether
    receive() external payable {}

    // Function to swap tokens and add liquidity to a Uniswap pair
    function swapAndAddLiquidityTokenAndToken(
        address tokenAddressA,
        address tokenAddressB,
        uint112 amountA,
        uint112 amountB,
        uint112 minLiquidityOut,
        address to
    ) external returns(uint liquidity) {
        // Ensure at least one token amount is positive
        require(amountA > 0 || amountB > 0, "amounts can not be both 0");

        // Transfer tokens from user to this contract
        if (amountA > 0) {
            TransferHelper.safeTransferFrom(tokenAddressA, msg.sender, address(this), uint(amountA));
        }
        if (amountB > 0) {
            TransferHelper.safeTransferFrom(tokenAddressB, msg.sender, address(this), uint(amountB));
        }

        // Call internal function to swap and add liquidity
        return _swapAndAddLiquidity(
            tokenAddressA,
            tokenAddressB,
            uint(amountA),
            uint(amountB),
            uint(minLiquidityOut),
            to
        );
    }

    // Internal function to swap tokens and add liquidity
    function _swapAndAddLiquidity(
        address tokenAddressA,
        address tokenAddressB,
        uint amountA,
        uint amountB,
        uint minLiquidityOut,
        address to
    ) internal returns(uint liquidity) {
        // Logic to swap tokens and add liquidity (omitted for brevity)
    }

    // Function to calculate the amount of tokenA to swap
    function calcAmountAToSwap(
        uint reserveA,
        uint reserveB,
        uint amountA,
        uint amountB
    ) public pure returns(uint amountAToSwap) {
        // Logic to calculate the amount of tokenA to swap (omitted for brevity)
    }

    // Function to withdraw ether in emergency situations
    function emergencyWithdrawEther() external onlyOwner {
        // Transfer all ether held by the contract to the owner
        (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
        require(success, "withdraw failure");
    }

    // Function to withdraw ERC20 tokens in emergency situations
    function emergencyWithdrawErc20(address tokenAddress) external onlyOwner {
        // Transfer all tokens of specified type held by the contract to the owner
        IERC20 token = IERC20(tokenAddress);
        TransferHelper.safeTransfer(tokenAddress, msg.sender, token.balanceOf(address(this)));
    }
}
