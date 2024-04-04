// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {AlignmentVaultTest} from "./AlignmentVault.t.sol";

contract LiquidityPositionsTest is AlignmentVaultTest {
    function setUp() public override {
        super.setUp();
        transferMilady(address(this), 69);
        transferMilady(address(av), 333);
        transferMilady(address(av), 420);
    }

    function testLiquidityPositionCreateFullRangeEth() public {
        av.liquidityPositionCreate(1 ether, 0, none, none, -12600, 10320, 0);
    }
}
