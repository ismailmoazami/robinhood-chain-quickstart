// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MyNFT} from "../src/MyNFT.sol";

contract DeployNFTScript is Script {
    function run() external returns (MyNFT) {
        vm.startBroadcast();

        // Retrieve deployment details from env, falling back to defaults if not set
        string memory name = vm.envOr("NFT_NAME", string("Robinhood NFT Collection"));
        string memory symbol = vm.envOr("NFT_SYMBOL", string("RHNFT"));
        string memory baseURI = vm.envOr("NFT_BASE_URI", string("ipfs://QmDefaultNFTBaseURI/"));
        address deployer = msg.sender;

        console.log("Deploying NFT contract with details:");
        console.log("- Name:", name);
        console.log("- Symbol:", symbol);
        console.log("- Base URI:", baseURI);
        console.log("- Owner/Deployer:", deployer);

        MyNFT nft = new MyNFT(name, symbol, deployer, baseURI);

        console.log("MyNFT successfully deployed to:", address(nft));

        vm.stopBroadcast();
        return nft;
    }
}
