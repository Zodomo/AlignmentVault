// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {Script, console2} from "../lib/forge-std/src/Script.sol";
import {TestNft} from "../src/testnet/TestNft.sol";

contract TestNftScript is Script {
    uint256 deployerPrivateKey;
    address deployer;

    TestNft public nft = TestNft(0xAFbCA3cCEDB2dFf9A1F4Ec1d6fac72933F22Cf4c);

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.addr(deployerPrivateKey);

        vm.createSelectFork("sepolia");
    }

    function deploy() public {
        vm.startBroadcast(deployerPrivateKey);
        nft = new TestNft();
        vm.stopBroadcast();

        console2.log("TestNft deployed at:", address(nft));
    }

    function mint() public {
        vm.startBroadcast(deployerPrivateKey);
        nft.mint(deployer, 50);
        vm.stopBroadcast();
    }
}
