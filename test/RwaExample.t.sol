// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {SimpleRWA} from "../src/RwaExample.sol";

contract RwaExampleTest is Test {
    SimpleRWA public rwa;

    address public owner = address(0x11);
    address public userA = address(0x22);
    address public userB = address(0x33);

    string public constant NAME = "Robinhood Simple RWA";
    string public constant SYMBOL = "RSRWA";
    uint256 public constant INITIAL_PRICE = 15000; // $150.00 in cents

    function setUp() public {
        rwa = new SimpleRWA(NAME, SYMBOL, INITIAL_PRICE, owner);
    }

    // --- 1. Initial State ---
    function test_InitialState() public view {
        assertEq(rwa.name(), NAME);
        assertEq(rwa.symbol(), SYMBOL);
        assertEq(rwa.pricePerShareCents(), INITIAL_PRICE);
        assertEq(rwa.owner(), owner);
        assertTrue(rwa.isEligible(owner));
        assertFalse(rwa.isEligible(userA));
    }

    // --- 2. Set Eligibility ---
    function test_OwnerCanSetEligibility() public {
        vm.prank(owner);
        rwa.setEligibility(userA, true);
        assertTrue(rwa.isEligible(userA));

        vm.prank(owner);
        rwa.setEligibility(userA, false);
        assertFalse(rwa.isEligible(userA));
    }

    function test_NonOwnerCannotSetEligibility() public {
        vm.prank(userA);
        vm.expectRevert(); // OwnableUnauthorizedAccount
        rwa.setEligibility(userB, true);
    }

    // --- 3. Set Price ---
    function test_OwnerCanSetPrice() public {
        vm.prank(owner);
        rwa.setPricePerShareCents(20000);
        assertEq(rwa.pricePerShareCents(), 20000);
    }

    function test_NonOwnerCannotSetPrice() public {
        vm.prank(userA);
        vm.expectRevert(); // OwnableUnauthorizedAccount
        rwa.setPricePerShareCents(20000);
    }

    // --- 4. Minting ---
    function test_OwnerCanMintToEligible() public {
        vm.prank(owner);
        rwa.setEligibility(userA, true);

        vm.prank(owner);
        rwa.mint(userA, 1000 * 10**18);
        assertEq(rwa.balanceOf(userA), 1000 * 10**18);
    }

    function test_OwnerCannotMintToIneligible() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(SimpleRWA.NotEligible.selector, userA));
        rwa.mint(userA, 1000 * 10**18);
    }

    function test_NonOwnerCannotMint() public {
        vm.prank(owner);
        rwa.setEligibility(userA, true);

        vm.prank(userA);
        vm.expectRevert(); // OwnableUnauthorizedAccount
        rwa.mint(userA, 1000 * 10**18);
    }

    // --- 5. Transfers & Eligibility Compliance ---
    function test_TransferBetweenEligibleSucceeds() public {
        // Setup eligibility
        vm.startPrank(owner);
        rwa.setEligibility(userA, true);
        rwa.setEligibility(userB, true);
        rwa.mint(userA, 1000 * 10**18);
        vm.stopPrank();

        // Perform transfer
        vm.prank(userA);
        rwa.transfer(userB, 400 * 10**18);

        assertEq(rwa.balanceOf(userA), 600 * 10**18);
        assertEq(rwa.balanceOf(userB), 400 * 10**18);
    }

    function test_TransferFromIneligibleSenderFails() public {
        // userA has balance but is made ineligible
        vm.startPrank(owner);
        rwa.setEligibility(userA, true);
        rwa.setEligibility(userB, true);
        rwa.mint(userA, 1000 * 10**18);
        rwa.setEligibility(userA, false); // make ineligible
        vm.stopPrank();

        vm.prank(userA);
        vm.expectRevert(abi.encodeWithSelector(SimpleRWA.NotEligible.selector, userA));
        rwa.transfer(userB, 400 * 10**18);
    }

    function test_TransferToIneligibleRecipientFails() public {
        vm.startPrank(owner);
        rwa.setEligibility(userA, true);
        rwa.mint(userA, 1000 * 10**18);
        // userB is ineligible
        vm.stopPrank();

        vm.prank(userA);
        vm.expectRevert(abi.encodeWithSelector(SimpleRWA.NotEligible.selector, userB));
        rwa.transfer(userB, 400 * 10**18);
    }

    function test_TransferFromEligibleToEligibleWithAllowance() public {
        vm.startPrank(owner);
        rwa.setEligibility(userA, true);
        rwa.setEligibility(userB, true);
        rwa.mint(userA, 1000 * 10**18);
        vm.stopPrank();

        // userA approves owner to spend
        vm.prank(userA);
        rwa.approve(owner, 400 * 10**18);

        // owner transfers on behalf of userA to userB
        vm.prank(owner);
        rwa.transferFrom(userA, userB, 400 * 10**18);

        assertEq(rwa.balanceOf(userA), 600 * 10**18);
        assertEq(rwa.balanceOf(userB), 400 * 10**18);
    }
}
