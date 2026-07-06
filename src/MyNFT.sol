// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Robinhood NFT Collection
 * @dev A Bored Ape-style ERC721 NFT contract with a common base URI,
 * public minting for 0.001 ether, and owner withdrawal.
 */
contract MyNFT is ERC721, Ownable {
    uint256 private _nextTokenId;
    string private _baseTokenURI;

    uint256 public constant MINT_PRICE = 0.001 ether;

    event NFTMinted(address indexed recipient, uint256 indexed tokenId);
    event BaseURIChanged(string newBaseURI);

    constructor(string memory name, string memory symbol, address initialOwner, string memory initialBaseURI)
        ERC721(name, symbol)
        Ownable(initialOwner)
    {
        _baseTokenURI = initialBaseURI;
    }

    /**
     * @dev Public minting function. Anyone can mint an NFT by paying 0.001 ether.
     * @param recipient The address that will receive the minted NFT.
     * @return The ID of the newly minted NFT.
     */
    function mintNFT(address recipient) public payable returns (uint256) {
        require(msg.value >= MINT_PRICE, "Insufficient payment: must be at least 0.001 ether");

        uint256 tokenId = _nextTokenId++;
        _safeMint(recipient, tokenId);

        emit NFTMinted(recipient, tokenId);

        return tokenId;
    }

    /**
     * @dev Set the base token URI. Can only be called by the owner.
     * @param newBaseURI The new base URI (e.g., ipfs://QmZ4t44T6x14m.../).
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    /**
     * @dev Internal function override returning the base URI.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Owner can withdraw the collected funds.
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool success,) = owner().call{value: balance}("");
        require(success, "Withdrawal failed");
    }
}
