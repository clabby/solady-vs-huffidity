// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title HuffWrapper
/// @notice A simple contract that deploys with the runtime bytecode specified in the constructor.
contract HuffWrapper {
    constructor(bytes memory _bytecode) {
        assembly {
            return(add(_bytecode, 0x20), mload(_bytecode))
        }
    }
}
