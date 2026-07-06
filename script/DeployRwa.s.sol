// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {SimpleRWA} from "../src/RwaExample.sol";

contract DeployScript is Script {
    function run() external returns (SimpleRWA) {
        vm.startBroadcast();

        string memory name = vm.envOr("RWA_NAME", string("Robinhood Simple RWA"));
        string memory symbol = vm.envOr("RWA_SYMBOL", string("RSRWA"));
        uint256 initialPrice = vm.envOr("RWA_INITIAL_PRICE", uint256(10000)); // $100.00 (in cents)
        address owner = vm.envOr("RWA_OWNER", msg.sender);

        console.log("Deploying SimpleRWA contract with details:");
        console.log("- Name:", name);
        console.log("- Symbol:", symbol);
        console.log("- Initial Price (Cents):", initialPrice);
        console.log("- Owner:", owner);

        SimpleRWA rwa = new SimpleRWA(name, symbol, initialPrice, owner);

        console.log("SimpleRWA successfully deployed to:", address(rwa));

        vm.stopBroadcast();
        return rwa;
    }
}
