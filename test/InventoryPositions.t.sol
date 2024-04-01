// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import "./AlignmentVault.t.sol";

contract InventoryPositionsTest is AlignmentVaultTest {
    // Setting up initial conditions for the test
    function setUp() public override {
        super.setUp();
        // Transferring tokens to the test contract and AlignmentVault contract for testing purposes
        transferMilady(address(this), 69);
        transferMilady(address(av), 333);
        transferMilady(address(av), 420);
    }

    // Testing the creation of an inventory position using vTokens
    function testInventoryPositionCreateVToken() public {
        // Defining token and amount arrays for the test
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 69;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        // Calculating the expected position ID
        uint256 expectedPositionId = IERC721Enumerable(address(NFTX_INVENTORY_STAKING)).totalSupply() + 1;

        // Minting vToken and transferring it to AlignmentVault contract
        mintVToken(tokenIds, amounts);
        IERC20(vault).transfer(address(av), 1 ether);

        // Expecting an event and emitting the event for inventory position creation
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionCreated(expectedPositionId, 1 ether);
        // Creating the inventory position
        uint256 positionId = av.inventoryPositionCreateVToken(1 ether);
        (,,,,, uint256 vTokenShareBalance,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        uint256[] memory positionIds = av.getInventoryPositionIds();

        // Assertions for the test
        assertEq(positionId, expectedPositionId, "positionId doesn't match expectations");
        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 0, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 2, "NFT balance is incorrect");
        assertEq(vTokenShareBalance, 1 ether, "vTokenShareBalance doesn't match position");
        assertEq(positionIds[0], positionId, "inventory position ID unaccounted for");
    }

    // Testing the creation of an inventory position using NFTs
    function testInventoryPositionCreateNfts() public {
        // Defining token and amount arrays for the test
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 333;
        tokenIds[1] = 420;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;
        // Calculating the expected position ID
        uint256 expectedPositionId = IERC721Enumerable(address(NFTX_INVENTORY_STAKING)).totalSupply() + 1;

        // Expecting an event and emitting the event for inventory position creation
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionCreated(expectedPositionId, 2 ether);
        // Creating the inventory position
        uint256 positionId = av.inventoryPositionCreateNfts(tokenIds, amounts);
        (,,,,, uint256 vTokenShareBalance,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        uint256[] memory positionIds = av.getInventoryPositionIds();

        // Assertions for the test
        assertEq(positionId, expectedPositionId, "positionId doesn't match expectations");
        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 0, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 0, "NFT balance is incorrect");
        assertEq(vTokenShareBalance, 2 ether, "vTokenShareBalance doesn't match position");
        assertEq(positionIds[0], positionId, "inventory position ID unaccounted for");
    }

    // Testing that an inventory position created with NFTs cannot be increased
    function testInventoryPositionIncrease() public {
        // Defining token and amount arrays for the test
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 333;
        tokenIds[1] = 420;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        // Minting vToken and creating an inventory position with vToken
        av.mintVToken(tokenIds, amounts);
        uint256 positionId = av.inventoryPositionCreateVToken(1 ether);
        // Expecting an event and emitting the event for inventory position increase
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionIncreased(positionId, 1 ether);
        // Attempting to increase the inventory position
        av.inventoryPositionIncrease(positionId, 1 ether);
        (,,,,, uint256 vTokenShareBalance,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        uint256[] memory positionIds = av.getInventoryPositionIds();

        // Assertions for the test
        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 0, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 0, "NFT balance is incorrect");
        assertEq(vTokenShareBalance, 2 ether, "vTokenShareBalance doesn't match position");
        assertEq(positionIds[0], positionId, "inventory position ID unaccounted for");
    }

    // Testing withdrawal of vTokens from an inventory position created with vTokens
    function testInventoryVTokenPositionVTokenWithdrawal() public {
        // Defining token and amount arrays for the test
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 333;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        // Minting vToken and creating an inventory position with vToken
        av.mintVToken(tokenIds, amounts);
        uint256 positionId = av.inventoryPositionCreateVToken(1 ether);
        // Fast-forwarding time for withdrawal eligibility
        vm.warp(block.timestamp + 3 days + 1);
        // Expecting an event and emitting the event for inventory position withdrawal
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionWithdrawal(positionId, 1 ether);
        // Withdrawing vTokens from the inventory position
        av.inventoryPositionWithdrawal(positionId, 1 ether, none, 0);
        (,,,,, uint256 vTokenShareBalance,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        uint256[] memory positionIds = av.getInventoryPositionIds();

        // Assertions for the test
        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 1 ether, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 1, "NFT balance is incorrect");
        assertEq(vTokenShareBalance, 0, "vTokenShareBalance doesn't match position");
        assertEq(positionIds[0], positionId, "inventory position ID unaccounted for");
    }
      /**
     * @dev Test function to simulate withdrawal of vTokens from inventory position.
     *      This function creates a vToken position, waits for 3 days, then withdraws vTokens.
     *      It asserts various conditions to ensure correctness of the withdrawal process.
     */
    function testInventoryVTokenPositionNftWithdrawal() public {
        // Define token IDs and amounts
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 333;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        // Mint vTokens and create vToken position
        av.mintVToken(tokenIds, amounts);
        uint256 positionId = av.inventoryPositionCreateVToken(1 ether);

        // Wait for 3 days
        vm.warp(block.timestamp + 3 days + 1);

        // Emit event for position withdrawal
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionWithdrawal(positionId, 1 ether);

        // Withdraw vTokens from inventory position
        av.inventoryPositionWithdrawal(positionId, 1 ether, tokenIds, 0);

        // Retrieve vToken share balance and inventory position IDs
        (,,,,, uint256 vTokenShareBalance,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        uint256[] memory positionIds = av.getInventoryPositionIds();

        // Assertions for correctness of withdrawal
        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 0, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 2, "NFT balance is incorrect");
        assertEq(vTokenShareBalance, 0, "vTokenShareBalance doesn't match position");
        assertEq(positionIds[0], positionId, "inventory position ID unaccounted for");
    }

    /**
     * @dev Test function to simulate withdrawal of both NFTs and vTokens from inventory position.
     *      This function creates a combined NFT-vToken position, waits for 3 days, then withdraws NFTs and vTokens.
     *      It asserts various conditions to ensure correctness of the withdrawal process.
     */
    function testInventoryVTokenPositionBothWithdrawal() public {
        // Define token IDs and amounts for vTokens
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 333;
        tokenIds[1] = 420;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        // Define token IDs for NFTs withdrawal
        uint256[] memory withdrawal = new uint256[](1);
        withdrawal[0] = 420;

        // Mint vTokens and create combined position
        av.mintVToken(tokenIds, amounts);
        uint256 positionId = av.inventoryPositionCreateVToken(2 ether);

        // Wait for 3 days
        vm.warp(block.timestamp + 3 days + 1);

        // Emit event for position withdrawal
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionWithdrawal(positionId, 2 ether);

        // Withdraw NFTs and vTokens from inventory position
        av.inventoryPositionWithdrawal(positionId, 2 ether, withdrawal, 0);

        // Retrieve vToken share balance and inventory position IDs
        (,,,,, uint256 vTokenShareBalance,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        uint256[] memory positionIds = av.getInventoryPositionIds();

        // Assertions for correctness of withdrawal
        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 1 ether, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 1, "NFT balance is incorrect");
        assertEq(vTokenShareBalance, 0, "vTokenShareBalance doesn't match position");
        assertEq(positionIds[0], positionId, "inventory position ID unaccounted for");
    }

    /**
     * @dev Test function to simulate withdrawal of vTokens from NFT position.
     *      This function creates an NFT position, waits for 3 days, then withdraws vTokens.
     *      It asserts various conditions to ensure correctness of the withdrawal process.
     */
    function testInventoryNftPositionVTokenWithdrawal() public {
        // Define token IDs and amounts for NFTs
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 333;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        // Create NFT position
        uint256 positionId = av.inventoryPositionCreateNfts(tokenIds, amounts);

        // Wait for 3 days
        vm.warp(block.timestamp + 3 days + 1);

        // Emit event for position withdrawal
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionWithdrawal(positionId, 1 ether);

        // Withdraw vTokens from NFT position
        av.inventoryPositionWithdrawal(positionId, 1 ether, none, 0);

        // Retrieve vToken share balance and inventory position IDs
        (,,,,, uint256 vTokenShareBalance,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        uint256[] memory positionIds = av.getInventoryPositionIds();

        // Assertions for correctness of withdrawal
        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 1 ether, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 1, "NFT balance is incorrect");
        assertEq(vTokenShareBalance, 0, "vTokenShareBalance doesn't match position");
        assertEq(positionIds[0], positionId, "inventory position ID unaccounted for");
    }

    /**
     * @dev Test function to simulate withdrawal of NFTs from NFT position.
     *      This function creates an NFT position, waits for 3 days, then withdraws NFTs.
     *      It asserts various conditions to ensure correctness of the withdrawal process.
     */
    function testInventoryNftPositionNftWithdrawal() public {
        // Define token IDs and amounts for NFTs
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 333;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        // Create NFT position
        uint256 positionId = av.inventoryPositionCreateNfts(tokenIds, amounts);

        // Wait for 3 days
        vm.warp(block.timestamp + 3 days + 1);

        // Emit event for position withdrawal
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionWithdrawal(positionId, 1 ether);

        // Withdraw NFTs from NFT position
        av.inventoryPositionWithdrawal(positionId, 1 ether, tokenIds, 0);

        // Retrieve vToken share balance and inventory position IDs
        (,,,,, uint256 vTokenShareBalance,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        uint256[] memory positionIds = av.getInventoryPositionIds();

        // Assertions for correctness of withdrawal
        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 0, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 2, "NFT balance is incorrect");
        assertEq(vTokenShareBalance, 0, "vTokenShareBalance doesn't match position");
        assertEq(positionIds[0], positionId, "inventory position ID unaccounted for");
    }

    /**
     * @dev Test function to simulate withdrawal of both NFTs and vTokens from NFT position.
     *      This function creates a combined NFT-vToken position, waits for 3 days, then withdraws NFTs and vTokens.
     *      It asserts various conditions to ensure correctness of the withdrawal process.
     */
    function testInventoryNftPositionBothWithdrawal() public {
        // Define token IDs and amounts for NFTs
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 333;
        tokenIds[1] = 420;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        // Define token IDs for vTokens withdrawal
        uint256[] memory withdrawal = new uint256[](1);
        withdrawal[0] = 420;

        // Create combined NFT-vToken position
        uint256 positionId = av.inventoryPositionCreateNfts(tokenIds, amounts);

        // Wait for 3 days
        vm.warp(block.timestamp + 3 days + 1);

        // Emit event for position withdrawal
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionWithdrawal(positionId, 2 ether);

        // Withdraw NFTs and vTokens from NFT position
        av.inventoryPositionWithdrawal(positionId, 2 ether, withdrawal, 0);

        // Retrieve vToken share balance and inventory position IDs
        (,,,,, uint256 vTokenShareBalance,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        uint256[] memory positionIds = av.getInventoryPositionIds();

        // Assertions for correctness of withdrawal
        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 1 ether, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 1, "NFT balance is incorrect");
        assertEq(vTokenShareBalance, 0, "vTokenShareBalance doesn't match position");
        assertEq(positionIds[0], positionId, "inventory position ID unaccounted for");
    }

    /**
     * @dev Test function to simulate combination of two vToken positions into one.
     *      This function creates two vToken positions, combines them, and asserts correctness.
     */
    function testInventoryVTokenPositionCombineVTokenPosition() public {
        // Define token IDs and amounts for vTokens
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 333;
        tokenIds[1] = 420;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        // Define arrays to hold position IDs
        uint256[] memory childPositionIds = new uint256[](1);
        uint256[] memory positionIds = new uint256[](2);

        // Mint vTokens and create vToken positions
        av.mintVToken(tokenIds, amounts);
        uint256 positionId = av.inventoryPositionCreateVToken(1 ether);
        positionIds[0] = positionId;

        // Create child vToken position
        childPositionIds[0] = av.inventoryPositionCreateVToken(1 ether);
        positionIds[1] = childPositionIds[0];

        // Wait for 3 days
        vm.warp(block.timestamp + 3 days + 1);

        // Emit event for position combination
        vm.expectEmit(address(av));
        emit IAlignmentVault.AV_InventoryPositionCombination(positionId, childPositionIds);

        // Combine vToken positions
        av.inventoryPositionCombine(positionId, childPositionIds);

        // Retrieve vToken share balance and inventory position IDs
        (,,,,, uint256 vTokenShareBalance0,,) = NFTX_INVENTORY_STAKING.positions(positionId);
        (,,,,, uint256 vTokenShareBalance1,,) = NFTX_INVENTORY_STAKING.positions(childPositionIds[0]);

        // Assertions for correctness of combination
        assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
        assertEq(NFTX_INVENTORY_STAKING.ownerOf(childPositionIds[0]), address(av), "positionId not owned by AV");
        assertEq(IERC20(vault).balanceOf(address(av)), 0, "vToken balance is incorrect");
        assertEq(IERC721(alignedNft).balanceOf(address(av)), 0, "NFT balance is incorrect");
        assertEq(vTokenShareBalance0, 2 ether, "vTokenShareBalance doesn't match position");
        assertEq(vTokenShareBalance1, 0, "vTokenShareBalance doesn't match position");
        assertEq(av.getInventoryPositionIds(), positionIds, "inventory position IDs unaccounted for");
    }

// Test combining vToken position with NFT position
function testInventoryVTokenPositionCombineNftPosition() public {
    // Initialize tokenIds array with one element
    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = 333;
    // Initialize amounts array with one element
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = 1;
    // Initialize childPositionIds array with one element
    uint256[] memory childPositionIds = new uint256[](1);
    // Initialize positionIds array with two elements
    uint256[] memory positionIds = new uint256[](2);

    // Mint vTokens
    av.mintVToken(tokenIds, amounts);
    // Create a vToken position
    uint256 positionId = av.inventoryPositionCreateVToken(1 ether);
    // Set the first element of positionIds array
    positionIds[0] = positionId;
    // Update tokenIds array
    tokenIds[0] = 420;
    // Create a child NFT position
    childPositionIds[0] = av.inventoryPositionCreateNfts(tokenIds, amounts);
    // Set the second element of positionIds array
    positionIds[1] = childPositionIds[0];

    // Fast forward time
    vm.warp(block.timestamp + 3 days + 1);
    // Expect an emission
    vm.expectEmit(address(av));
    // Emit event for AV inventory position combination
    emit IAlignmentVault.AV_InventoryPositionCombination(positionId, childPositionIds);
    // Combine positions
    av.inventoryPositionCombine(positionId, childPositionIds);
    // Fetch vToken share balances
    (,,,,, uint256 vTokenShareBalance0,,) = NFTX_INVENTORY_STAKING.positions(positionId);
    (,,,,, uint256 vTokenShareBalance1,,) = NFTX_INVENTORY_STAKING.positions(childPositionIds[0]);

    // Assert ownership of positions
    assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
    assertEq(NFTX_INVENTORY_STAKING.ownerOf(childPositionIds[0]), address(av), "positionId not owned by AV");
    // Assert vToken and NFT balances
    assertEq(IERC20(vault).balanceOf(address(av)), 0, "vToken balance is incorrect");
    assertEq(IERC721(alignedNft).balanceOf(address(av)), 0, "NFT balance is incorrect");
    // Assert vToken share balances
    assertEq(vTokenShareBalance0, 2 ether, "vTokenShareBalance doesn't match position");
    assertEq(vTokenShareBalance1, 0, "vTokenShareBalance doesn't match position");
    // Assert inventory position IDs
    assertEq(av.getInventoryPositionIds(), positionIds, "inventory position IDs unaccounted for");
}

// Test combining NFT position with vToken position
function testInventoryNftPositionCombineVTokenPosition() public {
    // Initialize tokenIds array with one element
    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = 333;
    // Initialize amounts array with one element
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = 1;
    // Initialize childPositionIds array with one element
    uint256[] memory childPositionIds = new uint256[](1);
    // Initialize positionIds array with two elements
    uint256[] memory positionIds = new uint256[](2);

    // Create an NFT position
    uint256 positionId = av.inventoryPositionCreateNfts(tokenIds, amounts);
    // Set the first element of positionIds array
    positionIds[0] = positionId;
    // Update tokenIds array
    tokenIds[0] = 420;
    // Mint vTokens
    av.mintVToken(tokenIds, amounts);
    // Create a vToken position
    childPositionIds[0] = av.inventoryPositionCreateVToken(1 ether);
    // Set the second element of positionIds array
    positionIds[1] = childPositionIds[0];

    // Fast forward time
    vm.warp(block.timestamp + 3 days + 1);
    // Expect an emission
    vm.expectEmit(address(av));
    // Emit event for AV inventory position combination
    emit IAlignmentVault.AV_InventoryPositionCombination(positionId, childPositionIds);
    // Combine positions
    av.inventoryPositionCombine(positionId, childPositionIds);
    // Fetch vToken share balances
    (,,,,, uint256 vTokenShareBalance0,,) = NFTX_INVENTORY_STAKING.positions(positionId);
    (,,,,, uint256 vTokenShareBalance1,,) = NFTX_INVENTORY_STAKING.positions(childPositionIds[0]);

    // Assert ownership of positions
    assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
    assertEq(NFTX_INVENTORY_STAKING.ownerOf(childPositionIds[0]), address(av), "positionId not owned by AV");
    // Assert vToken and NFT balances
    assertEq(IERC20(vault).balanceOf(address(av)), 0, "vToken balance is incorrect");
    assertEq(IERC721(alignedNft).balanceOf(address(av)), 0, "NFT balance is incorrect");
    // Assert vToken share balances
    assertEq(vTokenShareBalance0, 2 ether, "vTokenShareBalance doesn't match position");
    assertEq(vTokenShareBalance1, 0, "vTokenShareBalance doesn't match position");
    // Assert inventory position IDs
    assertEq(av.getInventoryPositionIds(), positionIds, "inventory position IDs unaccounted for");
}

// Test combining two NFT positions
function testInventoryNftPositionCombineNftPosition() public {
    // Initialize tokenIds array with one element
    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = 333;
    // Initialize amounts array with one element
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = 1;
    // Initialize childPositionIds array with one element
    uint256[] memory childPositionIds = new uint256[](1);
    // Initialize positionIds array with two elements
    uint256[] memory positionIds = new uint256[](2);

    // Create an NFT position
    uint256 positionId = av.inventoryPositionCreateNfts(tokenIds, amounts);
    // Set the first element of positionIds array
    positionIds[0] = positionId;
    // Update tokenIds array
    tokenIds[0] = 420;
    // Create another NFT position
    childPositionIds[0] = av.inventoryPositionCreateNfts(tokenIds, amounts);
    // Set the second element of positionIds array
    positionIds[1] = childPositionIds[0];

    // Fast forward time
    vm.warp(block.timestamp + 3 days + 1);
    // Expect an emission
    vm.expectEmit(address(av));
    // Emit event for AV inventory position combination
    emit IAlignmentVault.AV_InventoryPositionCombination(positionId, childPositionIds);
    // Combine positions
    av.inventoryPositionCombine(positionId, childPositionIds);
    // Fetch vToken share balances
    (,,,,, uint256 vTokenShareBalance0,,) = NFTX_INVENTORY_STAKING.positions(positionId);
    (,,,,, uint256 vTokenShareBalance1,,) = NFTX_INVENTORY_STAKING.positions(childPositionIds[0]);

    // Assert ownership of positions
    assertEq(NFTX_INVENTORY_STAKING.ownerOf(positionId), address(av), "positionId not owned by AV");
    assertEq(NFTX_INVENTORY_STAKING.ownerOf(childPositionIds[0]), address(av), "positionId not owned by AV");
    // Assert vToken and NFT balances
    assertEq(IERC20(vault).balanceOf(address(av)), 0, "vToken balance is incorrect");
    assertEq(IERC721(alignedNft).balanceOf(address(av)), 0, "NFT balance is incorrect");
    // Assert vToken share balances
    assertEq(vTokenShareBalance0, 2 ether, "vTokenShareBalance doesn't match position");
    assertEq(vTokenShareBalance1, 0, "vTokenShareBalance doesn't match position");
    // Assert inventory position IDs
    assertEq(av.getInventoryPositionIds(), positionIds, "inventory position IDs unaccounted for");
    }
}
