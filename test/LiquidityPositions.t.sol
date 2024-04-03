// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import "./AlignmentVault.t.sol";

contract LiquidityPositionsTest is AlignmentVaultTest {
    
    // Function to set up the initial conditions for testing liquidity positions
    function setUp() public override {
        super.setUp();
        // Transfer 69 tokens to the contract
        transferMilady(address(this), 69);
        // Transfer 333 tokens to the AlignmentVault contract
        transferMilady(address(av), 333);
        // Transfer 420 tokens to the AlignmentVault contract
        transferMilady(address(av), 420);
    }

    // Test function to create a liquidity position with full range in ETH
    function testLiquidityPositionCreateFullRangeEth() public {
        // Creating a liquidity position with parameters:
        // Amount of 1 ether,
        // Lower bound of 0 (full range),
        // No lower tick constraint,
        // No upper tick constraint,
        // Fee growth below the position of -12600,
        // Fee growth above the position of 10320,
        // No initial fee growth
        av.liquidityPositionCreate(1 ether, 0, none, none, -12600, 10320, 0);
    }

    function testLiquidityPositionCreateEth() public {
        av.liquidityPositionCreate(1 ether, 0, none, none, 10000, -12240, 10920, 0);
    }

    function testLiquidityPositionCreateNfts() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 333;
        tokenIds[1] = 420;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;
        av.liquidityPositionCreate(0, 0, tokenIds, amounts, 10000, -6000, 10920, 0);
    }
}