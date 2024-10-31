// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {AlignmentVault} from "./AlignmentVault.sol";

contract AlignmentVaultImplementation is AlignmentVault {
    constructor() payable {
        _disableInitializers();
    }
}
