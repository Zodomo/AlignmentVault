// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {Script, console2} from "../lib/forge-std/src/Script.sol";
import {AlignmentVault} from "../src/AlignmentVault.sol";
import {AlignmentVaultImplementation} from "../src/AlignmentVaultImplementation.sol";
import {AlignmentVaultFactory} from "../src/AlignmentVaultFactory.sol";
import {AlignmentVault as AVTest} from "../src/testnet/AlignmentVault.sol";
import {AlignmentVaultImplementation as AVITest} from "../src/testnet/AlignmentVaultImplementation.sol";
import {AlignmentVaultFactory as AVFTest} from "../src/testnet/AlignmentVaultFactory.sol";

interface IInitialize {
    function initialize(address owner, address alignedNft, uint256 vaultId) external payable;
    function disableInitializers() external payable;
}

contract DeployScript is Script {
    AlignmentVault public av;
    AlignmentVaultImplementation public avi;
    AlignmentVaultFactory public avf;
    AVTest public avtest;
    AVITest public avitest;
    AVFTest public avftest;
    uint256 deployerPrivateKey;
    address deployer;

    address deployedFactoryTestnet = 0xD1ac539e856F8C86c7bf2217eC4b70D0D1c0D82C; // Set this for upgradeTestnetImplementation()
    address deployedFactoryMainnet; // Set this for upgradeMainnetImplementation();
    address alignedNftTestnet = 0xeA9aF8dBDdE2A8d3515C3B4E446eCd41afEdB1C6; // Set this for deployTestnetVault()
    address alignedNftMainnet = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5; // Set this for deployMainnetVault()
    uint96 vaultIdTestnet = 21; // Set this for deployTestnetVault() if you want to select an NFTX Vault
    uint96 vaultIdMainnet = 5; // Set this for deployMainnetVault() if you want to select an NFTX Vault

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.addr(deployerPrivateKey);
    }

    function deployTestnetVault() public {
        vm.createSelectFork("sepolia");
        vm.startBroadcast(deployerPrivateKey);
        avtest = new AVTest();
        avtest.initialize(deployer, alignedNftTestnet, vaultIdTestnet);
        vm.stopBroadcast();
        console2.log("Testnet AlignmentVault:", address(avtest));
    }

    function deployTestnetFactory() public {
        vm.createSelectFork("sepolia");
        vm.startBroadcast(deployerPrivateKey);
        avitest = new AVITest();
        avftest = new AVFTest(deployer, address(avitest));
        vm.stopBroadcast();
        console2.log("Testnet AlignmentVault Implementation:", address(avitest));
        console2.log("Testnet AlignmentVaultFactory:", address(avftest));
    }

    function upgradeTestnetImplementation() public {
        vm.createSelectFork("sepolia");
        vm.startBroadcast(deployerPrivateKey);
        avitest = new AVITest();
        AVFTest(deployedFactoryTestnet).updateImplementation(address(avitest));
        vm.stopBroadcast();
        console2.log("Testnet AlignmentVault Implementation:", address(avitest));
    }

    function deployMainnetVault() public {
        vm.createSelectFork("mainnet");
        vm.startBroadcast(deployerPrivateKey);
        av = new AlignmentVault();
        av.initialize(deployer, alignedNftMainnet, vaultIdMainnet);
        vm.stopBroadcast();
        console2.log("Mainnet AlignmentVault:", address(av));
    }

    function deployMainnetFactory() public {
        vm.createSelectFork("mainnet");
        vm.startBroadcast(deployerPrivateKey);
        avi = new AlignmentVaultImplementation();
        avf = new AlignmentVaultFactory(deployer, address(avi));
        vm.stopBroadcast();
        console2.log("Mainnet AlignmentVault Implementation:", address(avi));
        console2.log("Mainnet AlignmentVaultFactory:", address(avf));
    }

    function upgradeMainnetImplementation() public {
        vm.createSelectFork("mainnet");
        vm.startBroadcast(deployerPrivateKey);
        avi = new AlignmentVaultImplementation();
        AlignmentVaultFactory(deployedFactoryMainnet).updateImplementation(address(avi));
        vm.stopBroadcast();
        console2.log("Mainnet AlignmentVault Implementation:", address(avi));
    }
}
