// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ERC20Token} from "../src/ERC20Token.sol";

contract DeployScript is Script {
    function run() external returns (ERC20Token) {
        vm.startBroadcast();

        // Retrieve deployment details from env, falling back to defaults if not set
        string memory name = vm.envOr("TOKEN_NAME", string("Robinhood Token"));
        string memory symbol = vm.envOr("TOKEN_SYMBOL", string("RHT"));
        uint256 initialSupply = vm.envOr(
            "TOKEN_INITIAL_SUPPLY",
            uint256(1_000_000)
        );
        address deployer = msg.sender;

        console.log("Deploying contract with details:");
        console.log("- Name:", name);
        console.log("- Symbol:", symbol);
        console.log("- Initial Supply:", initialSupply);
        console.log("- Owner/Deployer:", deployer);

        ERC20Token token = new ERC20Token(
            name,
            symbol,
            initialSupply,
            deployer
        );

        console.log("ERC20Token successfully deployed to:", address(token));

        vm.stopBroadcast();
        return token;
    }
}
