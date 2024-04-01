// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "openzeppelin/interfaces/IERC20.sol"; // Import ERC20 interface
import "openzeppelin/interfaces/IERC721.sol"; // Import ERC721 interface
import "../src/AlignmentVault.sol"; // Import AlignmentVault contract

contract TestingAlignmentVault is AlignmentVault {
    constructor() {} // Constructor for TestingAlignmentVault contract
    
    // Function to call _estimateFloor() from AlignmentVault contract and return the result
    function call_estimateFloor() public view returns (uint256) {
        return _estimateFloor();
    }

    // Function to view the address of the liquidity helper contract
    function view_liqHelper() public view returns (address) {
        return (address(_liqHelper));
    }
}
