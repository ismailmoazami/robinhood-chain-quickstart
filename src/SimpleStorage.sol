// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleStorage
 * @dev A basic smart contract to store and retrieve a single uint256 value.
 */
contract SimpleStorage {
    uint256 private _value;

    event ValueChanged(uint256 newValue);

    /**
     * @dev Set the value stored in the contract.
     * @param newValue The new value to store.
     */
    function set(uint256 newValue) public {
        _value = newValue;
        emit ValueChanged(newValue);
    }

    /**
     * @dev Retrieve the value stored in the contract.
     * @return The stored value.
     */
    function get() public view returns (uint256) {
        return _value;
    }
}
