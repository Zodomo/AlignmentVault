<a id="readme-top"></a>

<a href="https://soliditylang.org/">
    <img alt="Languages" src="https://img.shields.io/github/languages/top/Zodomo/AlignmentVault?logo=solidity&style=flat" />
</a>
<a href="https://github.com/Zodomo/AlignmentVault/issues">
    <img alt="Issues" src="https://img.shields.io/github/issues/Zodomo/AlignmentVault?style=flat&color=0088ff" />
</a>
<a href="https://github.com/Zodomo/LayerZeroQuoter/pulls">
    <img alt="Pull Request" src="https://img.shields.io/github/issues-pr/Zodomo/AlignmentVault?style=flat&color=0088ff" />
</a>
<a href="https://github.com/Zodomo/AlignmentVault/graphs/contributors">
    <img alt="Contributors" src="https://img.shields.io/github/contributors/Zodomo/AlignmentVault?style=flat" />
</a>
<a href="">
    <img alt="Stars" src="https://img.shields.io/github/stars/Zodomo/AlignmentVault" />
</a>
<a href="">
    <img alt="Forks" src="https://img.shields.io/github/forks/Zodomo/AlignmentVault" />
</a>

<br />
<br />

    .-----------------------------------------------------------------------------.
    |            _ _                                  ___      __         _ _     |
    |      /\   | (_)                                | \ \    / /        | | |    |
    |     /  \  | |_  __ _ _ __  _ __ ___   ___ _ __ | |\ \  / /_ _ _   _| | |_   |
    |    / /\ \ | | |/ _` | '_ \| '_ ` _ \ / _ \ '_ \| __\ \/ / _` | | | | | __|  |
    |   / ____ \| | | (_| | | | | | | | | |  __/ | | | |_ \  / (_| | |_| | | |_   |
    |  /_/    \_\_|_|\__, |_| |_|_| |_| |_|\___|_| |_|\__| \/ \__,_|\__,_|_|\__|  |
    |                 __/ |                                                       |
    |                |___/                                                        |
    '-----------------------------------------------------------------------------'

# Table of Contents

  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
    </li>
    <li>
      <a href="#contract-details">Contract Details</a>
    </li>
    <li><a href="#contract-initialization">Contract Initialization</a></li>
    <li><a href="#ownership-management">Ownership Management</a></li>
    <li><a href="#view-functions">View Functions</a></li>
    <li><a href="#inventory-position-management">Inventory Position Management</a></li>
    <li><a href="#liquidity-position-management">Liquidity Position Management</a></li>
    <li><a href="#aligned-token-management">Aligned Token Management</a></li>
    <li><a href="#miscellaneous-token-management">Miscellaneous Token Management</a></li>
    <li><a href="#usage">Usage</a></li>
  </ol>

# About The Project

The **`AlignmentVault`** primitive is a smart contract that allows locking ETH, WETH, NFTs, NFTX vTokens, and NFTX liquidity to deepen the floor liquidity of a target NFT collection using NFTX V3 (Uniswap V3). The liquidity is locked forever, but the yield generated can be claimed indefinitely. Because of the nature of Uniswap V3, this vault primitive essentially allows you to market make a NFT collection with permanently locked liquidity.

This contract harnesses the economic velocity of derivative collections and directs it towards boosting a primary collection. It forces alignment of derivative teams in a way that is beneficial and allows them to retain the economic utility from the aligned capital. This is regenerative finance ("ReFi") for NFT communities.

There is a **testnet** deployment of an `AlignmentVaultFactory` available at `0xD1ac539e856F8C86c7bf2217eC4b70D0D1c0D82C` on Sepolia.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contract Details

**SPDX-License-Identifier:** AGPL-3.0\
**Solidity Version:** 0.8.23\
**Author:** Zodomo\
**Contact Information:**

- Clusters: [`zodomo/main`](https://clusters.xyz/profile/zodomo/233)
- Farcaster: [`zodomo`](https://warpcast.com/zodomo)
- X: [`@0xZodomo`](https://twitter.com/0xZodomo)
- Telegram: [`@zodomo`](https://t.me/zodomo)
- GitHub: [`Zodomo`](https://github.com/Zodomo)
- ENS: `Zodomo.eth`
- Email: `zodomo@proton.me`

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contract Initialization

- **initialize:** Initializes all contract variables and NFTX integration. Requires the owner, aligned NFT collection, and optionally the NFTX vault ID.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Ownership Management

- **renounceOwnership:** Overridden to disable it, as renouncing would break the vault.
- **setDelegate:** Sets the delegate address for the vault. The delegate can represent the vault when claiming yield, should NFTX support the Delegate Registry for this.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## View Functions

- **getUniswapPoolValues:** Returns the Uniswap pool address, the current price, and the current tick of the pool.
- **getInventoryPositionIds:** Returns an array of inventory position IDs.
- **getLiquidityPositionIds:** Returns an array of liquidity position IDs.
- **getSpecificInventoryPositionFees:** Returns the fees accrued for a specific inventory position.
- **getTotalInventoryPositionFees:** Returns the total fees accrued across all inventory positions.
- **getSpecificLiquidityPositionFees:** Returns the fees accrued for a specific liquidity position.
- **getTotalLiquidityPositionFees:** Returns the total fees accrued across all liquidity positions.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Inventory Position Management

- **inventoryPositionCreateVToken:** Creates an inventory position with vTokens.
- **inventoryPositionCreateNfts:** Creates an inventory position with NFTs.
- **inventoryPositionIncrease:** Increases an existing inventory position with vTokens.
- **inventoryPositionWithdrawal:** Withdraws vTokens and/or NFTs from an inventory position.
- **inventoryPositionCombine:** Combines child inventory positions under a parent position.
- **inventoryPositionCollectFees:** Collects fees from specified inventory positions.
- **inventoryPositionCollectAllFees:** Collects fees from all inventory positions.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Liquidity Position Management

- **liquidityPositionCreate:** Creates a new liquidity position.
- **liquidityPositionIncrease:** Increases an existing liquidity position.
- **liquidityPositionWithdrawal:** Withdraws from a liquidity position.
- **liquidityPositionCollectFees:** Collects fees from specified liquidity positions.
- **liquidityPositionCollectAllFees:** Collects fees from all liquidity positions.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Aligned Token Management

- **buyNftsFromPool:** Buys NFTs from the NFTX pool.
- **mintVToken:** Mints vTokens by depositing NFTs.
- **buyVToken:** Buys vTokens with ETH.
- **buyVTokenExact:** Buys an exact amount of vTokens with ETH.
- **sellVToken:** Sells vTokens for ETH.
- **sellVTokenExact:** Sells an exact amount of vTokens for ETH.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Miscellaneous Token Management

- **rescueERC20:** Rescues ERC20 tokens from the vault (except aligned tokens).
- **rescueERC721:** Rescues ERC721 tokens from the vault (except aligned tokens).
- **rescueERC1155:** Rescues ERC1155 tokens from the vault (except aligned tokens).
- **rescueERC1155Batch:** Rescues a batch of ERC1155 tokens from the vault (except aligned tokens).
- **wrapEth:** Wraps ETH to WETH.
- **unwrapEth:** Unwraps WETH to ETH.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Usage

1. Deploy the vault using the `AlignmentVaultFactory` contract, specifying the aligned NFT collection and optionally the NFTX vault ID.
2. Send ETH to the vault. This ETH will be locked forever but will generate yield.
3. Use the various management functions to create and manage inventory and liquidity positions.
4. Collect fees from these positions as needed.
5. Use the token management functions to interact with the aligned NFT collection and its vTokens.

Please note that any ETH, NFTs, or tokens sent to the vault will be locked forever. Only the generated yield can be withdrawn.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

You can contribute by writing tests, fixing bugs, optimizing the code, adding cool ass ASCII art, updating the README, or anything else productive.

**Built in collaboration with MiyaMaker: <a href="https://miyamaker.com">https://miyamaker.com</a>**

Special thanks for helping me through the end:

- @sudotx
- @RyanSea

<p align="right">(<a href="#readme-top">back to top</a>)</p>
