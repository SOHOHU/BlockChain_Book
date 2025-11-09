// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract SimpleStorage {
    uint256 private value;

    event ValueChanged(address indexed sender, uint256 newValue);

    constructor(uint256 initialValue) {
        value = initialValue;
        emit ValueChanged(msg.sender, initialValue);
    }

    function set(uint256 newValue) external {
        value = newValue;
        emit ValueChanged(msg.sender, newValue);
    }

    function get() external view returns (uint256) {
        return value;
    }
}

