// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MyNFT} from "../src/MyNFT.sol";

contract MyNFTTest is Test {
    MyNFT public nft;
    address public owner = address(0x1);
    address public user = address(0x2);

    string public constant NAME = "Robinhood NFT Collection";
    string public constant SYMBOL = "RHNFT";
    string public constant INITIAL_BASE_URI = "ipfs://QmInitialBaseURI/";
    string public constant NEW_BASE_URI = "ipfs://QmNewBaseURI/";

    function setUp() public {
        vm.prank(owner);
        nft = new MyNFT(NAME, SYMBOL, owner, INITIAL_BASE_URI);
    }

    function test_InitialState() public view {
        assertEq(nft.name(), NAME);
        assertEq(nft.symbol(), SYMBOL);
        assertEq(nft.owner(), owner);
    }

    function test_PublicMint_WithCorrectPayment() public {
        uint256 mintPrice = nft.MINT_PRICE();
        hoax(user, mintPrice); // Sets up user with eth balance and pranks user

        uint256 tokenId = nft.mintNFT{value: mintPrice}(user);

        assertEq(tokenId, 0);
        assertEq(nft.ownerOf(tokenId), user);
        assertEq(nft.balanceOf(user), 1);
        assertEq(nft.tokenURI(tokenId), string(abi.encodePacked(INITIAL_BASE_URI, "0")));
    }

    function test_PublicMint_RevertsIfPaymentInsufficient() public {
        uint256 insufficientPayment = nft.MINT_PRICE() - 1;
        hoax(user, insufficientPayment);

        vm.expectRevert("Insufficient payment: must be at least 0.001 ether");
        nft.mintNFT{value: insufficientPayment}(user);
    }

    function test_OwnerCanSetBaseURI() public {
        // Mint an NFT first to check URI
        uint256 mintPrice = nft.MINT_PRICE();
        hoax(user, mintPrice);
        uint256 tokenId = nft.mintNFT{value: mintPrice}(user);

        // Change base URI
        vm.prank(owner);
        nft.setBaseURI(NEW_BASE_URI);

        assertEq(nft.tokenURI(tokenId), string(abi.encodePacked(NEW_BASE_URI, "0")));
    }

    function test_NonOwnerCannotSetBaseURI() public {
        vm.prank(user);
        vm.expectRevert();
        nft.setBaseURI(NEW_BASE_URI);
    }

    function test_OwnerCanWithdraw() public {
        // Mint to generate contract balance
        uint256 mintPrice = nft.MINT_PRICE();
        hoax(user, mintPrice);
        nft.mintNFT{value: mintPrice}(user);

        uint256 contractBalance = address(nft).balance;
        assertEq(contractBalance, mintPrice);

        uint256 initialOwnerBalance = owner.balance;

        vm.prank(owner);
        nft.withdraw();

        assertEq(address(nft).balance, 0);
        assertEq(owner.balance, initialOwnerBalance + mintPrice);
    }

    function test_NonOwnerCannotWithdraw() public {
        vm.prank(user);
        vm.expectRevert();
        nft.withdraw();
    }
}
