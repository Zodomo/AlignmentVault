# AlignmentVault

The `AlignmentVault` contract is a powerful tool designed to align economic incentives in the world of NFTs by providing functionality to enhance liquidity for a target NFT collection. By permanently locking liquidity, it ensures sustained benefits for both the vault owner and the broader NFT community. Below, we'll delve into the core features and usage guidelines of the `AlignmentVault` contract.

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


## Overview

The `AlignmentVault` contract stands as a cornerstone of regenerative finance ("ReFi") for NFTs, fostering a symbiotic relationship between derivative NFT collections and their primary counterparts. Instead of passively hoping for derivative teams to preserve and enhance the value of primary collections, this contract actively aligns their interests by channeling capital towards deepening liquidity in a way that benefits all stakeholders.

## Key Features

- **Permanent Liquidity Enhancement:** Liquidity deposited into the vault is locked indefinitely, ensuring sustained benefits for the aligned NFT collection.
- **Yield Generation:** While the principal remains locked, the contract generates yield, which can be claimed indefinitely, providing a continuous source of income.
- **Integration with NFTX Protocol:** Seamless integration with the NFTX protocol allows for efficient liquidity management and yield generation through Uniswap.
- **ERC-1167 Factory Deployment:** A dedicated ERC-1167 factory simplifies deployment, reduces gas costs, and ensures Etherscan verification of deployed vaults.

## Contract Details

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

- **SPDX-License-Identifier:** AGPL-3.0
- **Solidity Version:** 0.8.20
- **Author:** Zodomo
- **Contact:** Zodomo.eth on ENS, @0xZodomo on Twitter, and zodomo@proton.me via email.

## Usage

<p align="right">(<a href="#readme-top">back to top</a>)</p>



## Errors

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


## Conclusion

The `AlignmentVault` contract represents a groundbreaking approach to aligning economic incentives in the NFT ecosystem, fostering collaboration and sustainability across collections. With its robust features, seamless integration with NFTX, and simplified deployment process, it serves as a cornerstone of regenerative finance for NFTs.

---

For a deeper understanding and detailed interactions, refer to the contract's codebase, associated comments, or reach out to Zodomo directly.

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

You can get one for writing tests, bug fixing, optimizing, adding cool ass ASCII art, updating the README (completely out of date), anything productive. My own testing is coming along nicely, but figured I'd invite the community to participate too and get some names in the Contributors list on GitHub. Please make sure you switch to and PR against the nftxv3-redesign branch!


<p align="right">(<a href="#readme-top">back to top</a>)</p>
