// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";

contract SimpleStorageTest is Test {
    SimpleStorage public simpleStorage;

    event ValueChanged(uint256 newValue);

    function setUp() public {
        simpleStorage = new SimpleStorage();
    }

    function test_InitialValueIsZero() public view {
        assertEq(simpleStorage.get(), 0);
    }

    function test_SetValue() public {
        vm.expectEmit(true, true, true, true);
        emit ValueChanged(42);
        
        simpleStorage.set(42);
        assertEq(simpleStorage.get(), 42);
    }

    function test_OverwriteValue() public {
        simpleStorage.set(100);
        assertEq(simpleStorage.get(), 100);

        simpleStorage.set(200);
        assertEq(simpleStorage.get(), 200);
    }
}
