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
}
