// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import "./AlignmentVault.t.sol";

contract LiquidityPositionsTest is AlignmentVaultTest {
    function setUp() public override {
        super.setUp();
        transferMilady(address(this), 69);
        transferMilady(address(av), 333);
        transferMilady(address(av), 420);
    }

    function testLiquidityPositionCreateEth() public prank(deployer) {
        av.liquidityPositionCreate(1 ether, 0, none, none, 10_000, 990_000, 0, 0, 0);
    }

    function testLiquidityPositionCreateNfts() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 333;
        tokenIds[1] = 420;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;
        av.liquidityPositionCreate(0, 0, tokenIds, amounts, 1_000_001, 5_000_000, 0, 0, 0);
    }
}
