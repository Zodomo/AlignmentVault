// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {Script, console2} from "../lib/forge-std/src/Script.sol";
import {AlignmentVault} from "../src/AlignmentVault.sol";

interface IInitialize {
    function initialize(
        address _owner,
        address _alignedNft,
        uint256 _vaultId
    ) external payable;
    function disableInitializers() external payable;
}

contract DeployScript is Script {

}