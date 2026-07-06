// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {
    ERC20Burnable
} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Robinhood ERC20 Token
 * @dev A standard ERC20 token implementation using OpenZeppelin Contracts v5.
 * Includes basic minting functionality restricted to the owner and token burning capabilities.
 */
contract ERC20Token is ERC20, ERC20Burnable, Ownable {
    /**
     * @dev Constructor that initializes the contract with a name, symbol, initial supply, and owner.
     * @param name The name of the token.
     * @param symbol The token symbol.
     * @param initialSupply The initial amount of tokens to mint (without decimals scaling).
     * @param initialOwner The address of the initial owner who will receive the supply and admin rights.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address initialOwner
    ) ERC20(name, symbol) Ownable(initialOwner) {
        // Mint the initial supply to the owner (scaled by 10^decimals)
        _mint(initialOwner, initialSupply * 10 ** decimals());
    }

    /**
     * @dev Function to mint new tokens. Can only be called by the contract owner.
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint (including decimals scaling).
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
