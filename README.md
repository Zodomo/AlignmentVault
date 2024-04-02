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
<img alt="Stars" src="https://img.shields.io/github/stars/Zodomo/AlignmentVault?style=social" />
<img alt="Stars" src="https://img.shields.io/github/forks/Zodomo/AlignmentVault?style=social" />




<br />
<div align="center">
<h1 align="center">AlignmentVault</h1>
</div>



# Table of Contents
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
    </li>
    <li>
      <a href="#contract-details">Contract Details</a>
    </li>
    <li><a href="#imports">Imports</a></li>
    <li><a href="#interfaces">Interfaces</a></li>
    <li><a href="#contract-initialization">Contract Initialization</a></li>
    <li><a href="#ownership-management">Ownership Management</a></li>
    <li><a href="#utility-functions">Utility Functions</a></li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#important-points">Important Points</a></li>
  </ol>





# About The Project

The **`AlignmentVault`** contract provides functionality to send ETH to a vault for the purpose of permanently enhancing the floor liquidity of a target NFT collection. While the liquidity is locked forever, the yield can be claimed indefinitely, and is split 50/50 between the vault owner and the NFTX liquidity pool.

This contract was intentionally designed to harness the economic velocity of collection derivatives and direct it into boosting a primary collection, instead of being extractive to the greater community. Instead of hoping derivative teams sweep and hold our prized collections, this code forces their alignment in a way that is not only beneficial, but allows them to retain the economic potential from that aligned capital. This is regenerative finance ("ReFi") for NFTs.

An ERC-1167 factory is deployed to mainnet at **`0xD7810e145F1A30C7d0B8C332326050Af5E067d43`**. Usage of this is recommended as it will save gas, and vaults deployed with it will automatically be verified by Etherscan.

There is also an incredible post from @bonkleman_ on X describing what this is, how it works, and why people should consider integrating it in derivative NFT collections. This post can be found [here](https://twitter.com/bonkleman_/status/1714370560543904021).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contract Details

**SPDX-License-Identifier:** AGPL-3.0  
**Solidity Version:** 0.8.20  
**Author:** Zodomo
**Contact Information:**  
- ENS: `Zodomo.eth`
- Farcaster: `zodomo`
- X: [`@0xZodomo`](https://twitter.com/0xZodomo)
- Telegram: [`@zodomo`](https://t.me/zodomo)
- GitHub: [`Zodomo`](https://github.com/Zodomo)
- Email: `zodomo@proton.me`

<p align="right">(<a href="#readme-top">back to top</a>)</p>



## Imports

- solady/src/auth/Ownable.sol
- openzeppelin/interfaces/IERC20.sol
- openzeppelin/interfaces/IERC721.sol
- openzeppelin/proxy/utils/Initializable.sol
- liquidity-helper/UniswapV2LiquidityHelper.sol

<p align="right">(<a href="#readme-top">back to top</a>)</p>



## Interfaces

- **INFTXFactory:** Interface to interact with NFTX factory, e.g., to get vaults for an asset.
- **INFTXVault:** Interface to fetch the vault ID.
- **INFTXLPStaking:** Interface for depositing into NFTX vault and claiming rewards.
- **INFTXStakingZap:** Interface for adding liquidity to the NFTX vault.
- **IAlignmentVault:** Interface for interacting with a deployed AlignmentVault.
- **IAlignmentVaultFactory:** Interface for interacting with the ERC-1167 factory to deploy a vault.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



## Contract Initialization

- **initialize:** Initializes all contract variables and NFTX integration.
- **disableInitializers:** Disables the ability to call initialization functions again, recommended post-initialization.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



## Ownership Management

- **renounceOwnership:** Overridden to disable the ability, as it would break the vault. A privileged operator is required for it to function properly. If an AlignmentVault is embedded in or used by another contract, it is important that the controlling code be the owner of the vault.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



## Utility Functions

- **\_estimateFloor:** Estimates the floor price of the NFT in terms of WETH based on NFTX SLP reserves.
- **alignNfts:** Only pair ETH with specific NFTs to add to NFTX vault liquidity. This does not automatically allocate excess ETH.
- **alignTokens:** This allows the owner to add a specific amount of ETH and the total fractionalized NFT token balance to the NFTX vault liquidity.
- **alignMaxLiquidity:** Adds NFTs and all ETH to the NFTX vault and stakes them. This deepens the floor liquidity of the aligned NFT, utilizing the maximum amount of capital available in the vault to do it.
- **claimYield:** Claims yield generated by the staked NFTWETH SLP. The yield can either be compounded or 50% sent to a recipient. The NFTX LP will always receive 50% of the yield.
- **checkInventory:** Checks the contract's inventory to recognize any new NFTs that were transferred unsafely. The contract must be aware of all NFTs it has in order to use them, so run this before alignMaxLiquidity if any NFT tokenIds are not accounted for!

<p align="right">(<a href="#readme-top">back to top</a>)</p>



## Errors

- **InvalidVaultId:** Vault ID is invalid.
- **AlignedAsset:** Unapproved action on an aligned asset (ETH/WETH/NFT/NFTX tokens)
- **NoNFTXVault:** No vault found in NFTX.
- **UnwantedNFT:** Deposited NFT is not the aligned NFT.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



## Usage

1. Call **`deploy()`** or **`deployDeterministic()`** on **`0xD7810e145F1A30C7d0B8C332326050Af5E067d43`** (ETH mainnet) to deploy your own vault.
    - Using **`IAlignmentVaultFactory`** can be helpful if you'd like to do this from another contract.
    - Provide the address of the NFT you want to align with and the corresponding NFTX vault ID. The salt value in **`deployDeterministic()`** is used for predicting your deployment address. Only use this if you're familiar with deployment methods like **`create2`**.
    - If you are unsure of the vault ID you should use, it is recommended that you visit https://nftx.io/vault/{address}/info/ (replace {address} with the NFT address you'd like to use) and view the Vault ID there. While the contract will use the initial vault automatically if you specify **`0`**, this is not recommended.
2. Once deployed, use **`IAlignmentVault`** to interact with the deployed vault.
    - Any deposits to the vault that involve ETH, WETH, aligned NFTs, and corresponding NFTX tokens or liquidity cannot be withdrawn, so be careful about when you deposit into the vault.
3. Any method of sending ETH to the vault is supported. Whether this is using the low-level **`call`** function or executing a WETH ERC20 token transfer, the vault will be able to handle it. All direct ETH transfers are automatically wrapped into WETH upon receipt. If any NFTs belonging to the aligned collection are sent, use **`safeTransferFrom()`** to perform that transfer so the vault can log the inventory it has received for latter processing!
    - It is important to use **`safeTransferFrom()`** when sending to the vault so it is not required to index the ownership of all NFTs belonging to a collection, incurring significant gas savings.
4. In the event aligned NFTs were transferred unsafely, use **`checkInventory()`** and provide an array of the tokenIds you'd like to check as input. This function will check each of them and add them to its inventory if they are owned by the vault. The function is also designed to prevent double-additions of a specific tokenId, so feel free to provide the entire tokenId range you expect the vault to be aware of.
5. If you are executing **`alignMaxLiquidity()`**, calculate how much ETH is required to add each NFT to the LP. The NFTX floor price per NFT is required for this action.
    - If the vault cannot afford to add any amount of NFTs it possesses, it will try to add as many as it can afford before adding the remaining ETH to the LP. Please perform any validation checks to ensure it will operate as you expect!
    - If you need manual control over liquidity additions, the **`alignNfts()`** function will allow you to add specific NFTs you choose (as long as you can afford all NFTs specified). This function also doesn't technically require the execution of **`checkInventory()`** beforehand. The **`alignTokens()`** function will allow you to utilize a specific amount of ETH (and entire fractionalized NFT token balance) to deepen the liquidity with.
        - If you intend to use **`alignNfts()`**, you might save gas if you don't use safe transfers to fund the vault, as they won't need to be removed from the internal inventory. If you do this, please keep these unsafe transfers in mind and run **`checkInventory()`** first if you intend to use **`alignMaxLiquidity()`** at any point in the future!
6. Once you're ready, call **`alignMaxLiquidity()`** (or other manual functions) to add all liquidity the vault is capable of adding to the NFTX LP for the aligned NFT.
7. Call **`claimRewards()`** with a recipient as input in order to retrieve any yield generated by the deposited liquidity. This yield will come in the form of the fractionalized NFT tokens in the NFTX LP and not ETH. Be aware that the vault will compound 50% of the yield, and will compound 100% of it if the zero address is provided as the recipient.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



## Important Points

- The contract allows for the permanent locking of liquidity into a target NFT collection. While the principal is locked, the rewards (or yield) can be claimed indefinitely.
- It integrates with several other protocols, including NFTX which uses Uniswap, for liquidity management and yield generation.
- The contract comes with initialization procedures to support deployment via the ERC-1167 proxy deployed to ETH mainnet at **`0xD7810e145F1A30C7d0B8C332326050Af5E067d43`**
- Ownership management is present, though the ability to renounce ownership is intentionally disabled.
- The contract also offers utility functions that estimate floor prices, manage liquidity, and claim yields. There's also a function to check the inventory of the contract against any unsafely transferred NFTs.
- Given the locked nature of liquidity, anyone interacting with the contract should be aware of the permanent nature of deposits.

---

This README serves as a general overview and documentation of the **`AlignmentVault`** contract. For in-depth details and interactions, refer to the contract's code and associated comments or reach out to Zodomo directly.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<p align="right">(<a href="#readme-top">back to top</a>)</p>