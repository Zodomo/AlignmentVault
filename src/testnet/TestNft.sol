// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.23;

import {ERC721} from "../../lib/solady/src/tokens/ERC721.sol";
import {Ownable} from "../../lib/solady/src/auth/Ownable.sol";
import {LibString} from "../../lib/solady/src/utils/LibString.sol";

contract TestNft is ERC721, Ownable {
    error InsufficientFunds();

    uint256 public totalSupply;

    constructor() payable {
        _initializeOwner(msg.sender);
    }

    function name() public pure override returns (string memory) {
        return "AlignmentVault Test NFT";
    }

    function symbol() public pure override returns (string memory) {
        return "AVTEST";
    }

    function tokenURI(
        uint256 id
    ) public view override returns (string memory) {
        if (!_exists(id)) revert TokenDoesNotExist();
        return LibString.concat("https://remilio.org/remilio/json/", LibString.toString(id));
    }

    function mint(address to, uint256 amount) external onlyOwner {
        uint256 tokenId = totalSupply;
        for (uint256 i = 0; i < amount; i++) {
            unchecked {
                ++tokenId;
            }
            _mint(to, tokenId);
        }
        totalSupply = tokenId;
    }

    function mint(uint256 amount) external payable {
        if (msg.value < amount * 0.025 ether) revert InsufficientFunds();

        uint256 tokenId = totalSupply;
        for (uint256 i = 0; i < amount; i++) {
            unchecked {
                ++tokenId;
            }
            _mint(msg.sender, tokenId);
        }
        totalSupply = tokenId;
    }

    function burn(
        uint256 id
    ) external {
        address nftOwner = _ownerOf(id);
        if (nftOwner != msg.sender && getApproved(id) != msg.sender && !isApprovedForAll(nftOwner, msg.sender)) {
            revert Unauthorized();
        }
        _burn(id);
    }
}
