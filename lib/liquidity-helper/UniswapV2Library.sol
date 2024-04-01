// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

// Importing necessary interfaces
import '../v2-core/contracts/interfaces/IUniswapV2Pair.sol';

// Library for interacting with Uniswap V2 pairs
library UniswapV2Library {
    // Function to sort token addresses
    // Used to handle return values from pairs sorted in a specific order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES'); // Ensure tokens are not identical
        // Sort tokens lexicographically
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS'); // Ensure token0 address is not zero
    }

    // Function to calculate the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        // Sort tokens
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        // Calculate pair address using CREATE2
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // SushiSwap init code hash
            )))));
    }

    // Function to fetch and sort the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        // Get reserves from the pair
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        // Sort reserves based on token order
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
}
