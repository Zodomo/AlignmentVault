// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

// Importing necessary interfaces and contracts
import "openzeppelin/interfaces/IERC20.sol";
import "openzeppelin/interfaces/IERC721.sol";
import "../src/AlignmentVault.sol";

// Contract for testing specific functionalities of AlignmentVault
contract TestingAlignmentVault is AlignmentVault {
    // Constructor
    constructor() {}

    // Function to call _estimateFloor function from AlignmentVault
    function call_estimateFloor() public view returns (uint256) {
        return _estimateFloor(); // Call _estimateFloor function to estimate the floor price
    }

    // Function to view the address of the liquidity helper contract
    function view_liqHelper() public view returns (address) {
        return (address(_liqHelper)); // Return the address of the liquidity helper contract used by AlignmentVault
    }
}
