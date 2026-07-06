// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC20Token} from "../src/ERC20Token.sol";

contract ERC20TokenTest is Test {
    ERC20Token public token;
    address public owner = address(0x1);
    address public user = address(0x2);

    string public constant NAME = "Robinhood Token";
    string public constant SYMBOL = "RHT";
    uint256 public constant INITIAL_SUPPLY = 1_000_000; // 1M tokens

    function setUp() public {
        vm.prank(owner);
        token = new ERC20Token(NAME, SYMBOL, INITIAL_SUPPLY, owner);
    }

    function test_InitialState() public view {
        assertEq(token.name(), NAME);
        assertEq(token.symbol(), SYMBOL);
        assertEq(token.owner(), owner);
        assertEq(token.totalSupply(), INITIAL_SUPPLY * 10 ** token.decimals());
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY * 10 ** token.decimals());
    }

    function test_OwnerCanMint() public {
        uint256 mintAmount = 500 * 10 ** token.decimals();
        
        vm.prank(owner);
        token.mint(user, mintAmount);

        assertEq(token.balanceOf(user), mintAmount);
        assertEq(token.totalSupply(), (INITIAL_SUPPLY * 10 ** token.decimals()) + mintAmount);
    }

    function test_NonOwnerCannotMint() public {
        uint256 mintAmount = 500 * 10 ** token.decimals();

        vm.prank(user);
        // Expect revert due to OwnableUnauthorizedAccount error (Ownable v5 style)
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user)
        );
        token.mint(user, mintAmount);
    }

    function test_UserCanBurn() public {
        uint256 burnAmount = 100 * 10 ** token.decimals();
        uint256 initialOwnerBalance = token.balanceOf(owner);
        uint256 initialTotalSupply = token.totalSupply();

        vm.prank(owner);
        token.burn(burnAmount);

        assertEq(token.balanceOf(owner), initialOwnerBalance - burnAmount);
        assertEq(token.totalSupply(), initialTotalSupply - burnAmount);
    }

    function test_BurnFromWithAllowance() public {
        uint256 burnAmount = 100 * 10 ** token.decimals();
        uint256 initialOwnerBalance = token.balanceOf(owner);
        uint256 initialTotalSupply = token.totalSupply();

        // Owner approves user to spend/burn tokens
        vm.prank(owner);
        token.approve(user, burnAmount);

        // User burns from Owner
        vm.prank(user);
        token.burnFrom(owner, burnAmount);

        assertEq(token.balanceOf(owner), initialOwnerBalance - burnAmount);
        assertEq(token.totalSupply(), initialTotalSupply - burnAmount);
        assertEq(token.allowance(owner, user), 0);
    }
}

