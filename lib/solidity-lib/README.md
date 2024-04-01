# uniswap-lib

[![Tests](https://github.com/Uniswap/uniswap-lib/workflows/Tests/badge.svg)](https://github.com/Uniswap/uniswap-lib/actions?query=workflow%3ATests)
[![Static Analysis](https://github.com/Uniswap/uniswap-lib/workflows/Static%20Analysis/badge.svg)](https://github.com/Uniswap/uniswap-lib/actions?query=workflow%3A%22Static+Analysis%22)
[![Lint](https://github.com/Uniswap/uniswap-lib/workflows/Lint/badge.svg)](https://github.com/Uniswap/uniswap-lib/actions?query=workflow%3ALint)
[![npm](https://img.shields.io/npm/v/@uniswap/lib)](https://unpkg.com/@uniswap/lib@latest/)

Solidity libraries that are shared across Uniswap contracts. These libraries are focused on safety and gas efficiency.

## Install

Run `yarn` to install dependencies.

## Test

Run `yarn test` to execute the test suite.

## Usage

To include this library in another project, use `yarn add @uniswap/lib`.

Then import the contracts via:

```solidity
import '@uniswap/lib/contracts/libraries/Babylonian.sol';

```
This library provides utilities for performing mathematical calculations and other operations efficiently and securely in Solidity contracts. By importing and using these libraries, developers can benefit from improved gas efficiency and reduced risk of vulnerabilities in their decentralized finance (DeFi) applications built on the Uniswap protocol
