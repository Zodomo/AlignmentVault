// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import "./AlignmentVault.t.sol";

import {IQuoter} from "../lib/nftx-protocol-v3/src/uniswap/v3-periphery/interfaces/IQuoter.sol";

contract AlignedTokenMgmtTest is AlignmentVaultTest {
    function setUp() public override {
        super.setUp();
        transferMilady(address(this), 69);
        transferMilady(address(this), 333);
        IERC721(MILADY).transferFrom(address(this), address(av), 69);
        IERC721(MILADY).safeTransferFrom(address(this), address(av), 333);
        transferMilady(address(av), 420);
        transferMilady(address(av), 777);
        transferMilady(address(av), 999);
    }

    IQuoter public quoter = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/
    //                  ALIGNED TOKEN MANAGEMENT
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´*/

    function testBuyNftsFromPool() public prank(deployer) {
        // Add NFTs to inventory
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 420;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        av.inventoryPositionCreateNfts(tokenIds, amounts);

        // Add NFTs to liquidity
        tokenIds = new uint256[](2);
        tokenIds[0] = 777;
        tokenIds[1] = 999;
        amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;
        av.liquidityPositionCreate({
            ethAmount: 20 ether,
            vTokenAmount: 0,
            tokenIds: tokenIds,
            amounts: amounts,
            tickLower: type(int24).min,
            tickUpper: type(int24).max,
            sqrtPriceX96: 0,
            ethMin: 0,
            vTokenMin: 0
        });

        // Buy NFT from pool
        tokenIds = new uint256[](1);
        tokenIds[0] = 420;

        vm.recordLogs(); // note: Quoter.sol is reverting so testing logs post call

        uint256 balBefore = address(av).balance;

        av.buyNftsFromPool(50 ether, tokenIds, type(uint256).max, 3000, 0);

        Vm.Log[] memory events = vm.getRecordedLogs();

        assertEq(IERC721(MILADY).ownerOf(420), address(av), "NFT wasn't bought from pool");

        bytes32 eventSig = events[events.length - 1].topics[0];
        bytes32 ethAmountTopic = events[events.length - 1].topics[1];
        bytes32 tokenIdsTopic = events[events.length - 1].topics[2];
        address emitter = events[events.length - 1].emitter;

        assertEq(emitter, address(av), "unexpected log: emitter");
        assertEq(eventSig, keccak256("AV_NftsPurchased(uint256,uint256[])"), "unexpected log: signature");
        assertEq(ethAmountTopic, bytes32(balBefore - address(av).balance), "unexpected log: ethAmount");
        assertEq(tokenIdsTopic, keccak256(abi.encodePacked(tokenIds)), "unexpected log: tokenIds");
    }

    function testMintVToken() public prank(deployer) {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 69;
        tokenIds[1] = 333;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        vm.expectEmit(true, true, false, false, address(av));
        emit IAlignmentVault.AV_MintVTokens(tokenIds, amounts);

        av.mintVToken(tokenIds, amounts);
        assertEq(IERC20(vault).balanceOf(address(av)), 2 ether, "vToken mint amount error");
    }

    function testBuyVToken() public prank(deployer) {
        uint256 ethBalBefore = address(av).balance;
        uint256 vTokenBought = av.buyVToken(1 ether, 3000, 0, 0);
        assertEq(address(av).balance, ethBalBefore - 1 ether, "ETH balance inaccurate");
        assertEq(IERC20(vault).balanceOf(address(av)), vTokenBought, "vToken balance didn't increase");
    }

    function testBuyVTokenExact() public prank(deployer) {
        uint256 ethBalBefore = address(av).balance;
        uint256 ethSpent = av.buyVTokenExact(5 ether, 3000, 0.1 ether, 0);
        assertEq(address(av).balance, ethBalBefore - ethSpent, "ETH balance inaccurate");
        assertEq(IERC20(vault).balanceOf(address(av)), 0.1 ether, "vToken swap wasn't exact");
    }

    function testSellVToken() public prank(deployer) {
        av.buyVTokenExact(5 ether, 3000, 0.1 ether, 0);
        uint256 ethBalBefore = address(av).balance;
        uint256 ethBought = av.sellVToken(0.1 ether, 3000, 0, 0);
        assertEq(address(av).balance, ethBalBefore + ethBought, "ETH balance inaccurate");
        assertEq(IERC20(vault).balanceOf(address(av)), 0, "vToken balance wasn't swapped");
    }

    function testSellVTokenExact() public prank(deployer) {
        av.buyVTokenExact(5 ether, 3000, 0.1 ether, 0);
        uint256 ethBalBefore = address(av).balance;
        uint256 vTokenBalBefore = IERC20(vault).balanceOf(address(av));
        uint256 vTokenSpent = av.sellVTokenExact(0.1 ether, 3000, 0.01 ether, 0);
        assertEq(address(av).balance, ethBalBefore + 0.01 ether, "ETH balance didn't increase");
        assertEq(IERC20(vault).balanceOf(address(av)), vTokenBalBefore - vTokenSpent, "vToken balance inaccurate");
    }
}
