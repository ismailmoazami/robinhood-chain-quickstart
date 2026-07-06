// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";

contract DeployScript is Script {
    function run() external returns (SimpleStorage) {
        vm.startBroadcast();

        SimpleStorage storageContract = new SimpleStorage();

        console.log("SimpleStorage successfully deployed to:", address(storageContract));

        vm.stopBroadcast();
        return storageContract;
    }
}
