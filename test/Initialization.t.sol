// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import "./AlignmentVault.t.sol";

contract InitializationTest is AlignmentVaultTest {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //                  INIT LOGIC TESTS
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function testTargetInitialize() public {
        targetInitialize(MILADY, VAULT_ID);
        assertEq(av.vaultId(), VAULT_ID);
        assertEq(address(av.alignedNft()), MILADY);
    }

    function testLazyInitialize() public {
        lazyInitialize(MILADY);
        assertEq(av.vaultId(), VAULT_ID);
        assertEq(address(av.alignedNft()), MILADY);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //                      INIT LOGIC
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function lazyInitialize(address alignedNft_) public {
        vm.startPrank(deployer);
        bytes32 salt = keccak256('deterministic salt');
        av = AlignmentVault(payable(avf.predictDeterministicAddress(salt)));
        alignedNft = alignedNft_;
        address[] memory vaults = NFTX_VAULT_FACTORY.vaultsForAsset(alignedNft_);
        if (vaults.length == 0) revert IAlignmentVault.AV_NFTX_NoVaultsExist();

        for (uint256 i; i < vaults.length; ++i) {
            (uint256 mintFee, uint256 redeemFee, uint256 swapFee) = INFTXVaultV3(vaults[i]).vaultFees();
            if (mintFee != NFTX_STANDARD_FEE || redeemFee != NFTX_STANDARD_FEE || swapFee != NFTX_STANDARD_FEE) {
                continue;
            } else if (INFTXVaultV3(vaults[i]).manager() != address(0)) {
                continue;
            } else {
                vaultId = INFTXVaultV3(vaults[i]).vaultId();
                vault = vaults[i];
                break;
            }
        }

        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_VaultInitialized(vault, vaultId);
        //@audit what does it mean when vault id is zero?
        //@response The initializer just wants it pointed at a standard 3/3/3 tax and finalized NFTX vault, if any exist
        avf.deployDeterministic(deployer, alignedNft_, 0, salt);
        vm.deal(address(av), FUNDING_AMOUNT);
        setApprovals();
        vm.stopPrank();
    }

    function targetInitialize(address alignedNft_, uint96 vaultId_) public {
        bytes32 salt = keccak256('deterministic salt');
        av = AlignmentVault(payable(avf.predictDeterministicAddress(salt)));
        vault = NFTX_VAULT_FACTORY.vault(vaultId_);
        vaultId = vaultId_;
        alignedNft = alignedNft_;

        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_VaultInitialized(vault, vaultId_);
        avf.deployDeterministic(deployer, alignedNft_, vaultId_, salt);
        vm.deal(address(av), FUNDING_AMOUNT);
        setApprovals();
    }
}