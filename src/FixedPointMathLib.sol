// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title FixedPointMathLib
/// @notice Example of a contract that interacts with appended Huff code.
contract FixedPointMathLib {
    /// @notice Calls appended Huff code that mimics Solady's FixedPointMathLib.mulDiv function.
    /// @dev See: [MulDiv.huff]
    function mulDiv(uint256 x, uint256 y, uint256 d) public pure returns (uint256 _res) {
        function (uint256, uint256, uint256) pure returns (uint256) _mulDiv;
        assembly {
            _mulDiv := sub(codesize(), 40)
        }
        _res = _mulDiv(x, y, d);
    }
}
