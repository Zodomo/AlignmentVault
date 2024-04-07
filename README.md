# AlignmentVault

The `AlignmentVault` contract is a powerful tool designed to align economic incentives in the world of NFTs by providing functionality to enhance liquidity for a target NFT collection. By permanently locking liquidity, it ensures sustained benefits for both the vault owner and the broader NFT community. Below, we'll delve into the core features and usage guidelines of the `AlignmentVault` contract.

## Overview

The `AlignmentVault` contract stands as a cornerstone of regenerative finance ("ReFi") for NFTs, fostering a symbiotic relationship between derivative NFT collections and their primary counterparts. Instead of passively hoping for derivative teams to preserve and enhance the value of primary collections, this contract actively aligns their interests by channeling capital towards deepening liquidity in a way that benefits all stakeholders.

## Key Features

- **Permanent Liquidity Enhancement:** Liquidity deposited into the vault is locked indefinitely, ensuring sustained benefits for the aligned NFT collection.
- **Yield Generation:** While the principal remains locked, the contract generates yield, which can be claimed indefinitely, providing a continuous source of income.
- **Integration with NFTX Protocol:** Seamless integration with the NFTX protocol allows for efficient liquidity management and yield generation through Uniswap.
- **ERC-1167 Factory Deployment:** A dedicated ERC-1167 factory simplifies deployment, reduces gas costs, and ensures Etherscan verification of deployed vaults.

## Contract Details

- **SPDX-License-Identifier:** AGPL-3.0
- **Solidity Version:** 0.8.20
- **Author:** Zodomo
- **Contact:** Zodomo.eth on ENS, @0xZodomo on Twitter, and zodomo@proton.me via email.

## Usage

1. **Deployment:** Utilize the ERC-1167 factory at `0xD7810e145F1A30C7d0B8C332326050Af5E067d43` (ETH mainnet) to deploy your own vault, specifying the target NFT and corresponding NFTX vault ID.
2. **Interaction:** Utilize the `IAlignmentVault` interface to interact with the deployed vault, depositing ETH, NFTs, or NFTX tokens.
3. **Liquidity Management:** Utilize functions like `alignMaxLiquidity()` to add all available liquidity to the NFTX LP, maximizing the floor liquidity of the aligned NFT.
4. **Yield Claiming:** Claim generated yield using the `claimYield()` function, compounding a portion of it while distributing the rest to the NFTX LP.
5. **Inventory Check:** Use `checkInventory()` to ensure the vault is aware of all NFTs transferred to it safely, optimizing liquidity management.

## Important Notes

- **Permanent Liquidity Lock:** Liquidity deposited into the vault is locked indefinitely, emphasizing the need for careful consideration before depositing.
- **Ownership Management:** While ownership is present, renouncing it is disabled to ensure proper control and governance.
- **Integration with NFTX:** Integration with the NFTX protocol facilitates efficient liquidity management and yield generation through Uniswap.
- **Utility Functions:** The contract provides utility functions for estimating floor prices, managing liquidity, and claiming yields.
- **ERC-1167 Factory Deployment:** Deployment via the ERC-1167 factory simplifies the process, reduces gas costs, and ensures Etherscan verification.

## Conclusion

The `AlignmentVault` contract represents a groundbreaking approach to aligning economic incentives in the NFT ecosystem, fostering collaboration and sustainability across collections. With its robust features, seamless integration with NFTX, and simplified deployment process, it serves as a cornerstone of regenerative finance for NFTs.

---

For a deeper understanding and detailed interactions, refer to the contract's codebase, associated comments, or reach out to Zodomo directly.
