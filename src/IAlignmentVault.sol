// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

interface IAlignmentVault {
    error AV_UnalignedNft();

    error AV_NFTX_NoVaultsExist();
    error AV_NFTX_InvalidVaultId();
    error AV_NFTX_InvalidVaultNft();
    error AV_NFTX_NoStandardVault();

    event AV_ReceivedAlignedNft(uint256 indexed tokenId);

    function initialize(
        address _owner,
        address _alignedNft,
        uint256 _vaultId
    ) external payable;
    function disableInitializers() external payable;

    function wrapEth() external payable;

    function onERC721Received(address, address, uint256 _tokenId, bytes calldata) external returns (bytes4 magicBytes);
}