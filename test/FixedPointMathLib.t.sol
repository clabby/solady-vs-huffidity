// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { HuffDeployer } from "foundry-huff/HuffDeployer.sol";
import { FixedPointMathLib } from "../src/FixedPointMathLib.sol";
import { FixedPointMathLib as FixedPointMathLib_Solady } from "solady/utils/FixedPointMathLib.sol";
import { HuffWrapper } from "../src/HuffWrapper.sol";

contract FixedPointMathLib_Test is Test {
    FixedPointMathLib lib;
    FixedPointMathLib_Wrapper solady;

    function setUp() public {
        // Grab the Solidity + Huff runtime code
        bytes memory bytecode = type(FixedPointMathLib).runtimeCode;
        bytes memory huff = (HuffDeployer.deploy("MulDiv")).code;

        // Concatenate the Solidity and Huff code
        bytes memory finalCode;
        assembly {
            // Grab the free memory pointer
            finalCode := mload(0x40)

            // Get the length of the Solidity and Huff code.
            let solLen := mload(bytecode)
            let huffLen := mload(huff)

            // Get the start of the final runtime code data
            let finalStart := add(finalCode, 0x20)

            // Copy the solidity code
            pop(staticcall(
                gas(),
                0x04,
                add(bytecode, 0x20),
                solLen,
                finalStart,
                solLen
            ))

            // Copy the huff code
            pop(staticcall(
                gas(),
                0x04,
                add(huff, 0x20),
                huffLen,
                add(finalStart, solLen),
                huffLen
            ))

            // The length of `finalCode` is the sum of the lengths of the two runtime code snippets
            let finalLen := add(solLen, huffLen)

            // Store the length of the final code
            mstore(finalCode, finalLen)

            // Update the free memory pointer
            mstore(0x40, add(finalCode, and(add(finalLen, 0x3F), not(0x1F))))
        }

        // Deploy the lib
        lib = FixedPointMathLib(address(new HuffWrapper(finalCode)));
        // Deploy the Solady lib wrapper
        solady = new FixedPointMathLib_Wrapper();
    }

    ////////////////////////////////////////////////////////////////
    //                         HUFFIDITY                          //
    ////////////////////////////////////////////////////////////////

    function testMulDiv_Huffidity() public {
        assertEq(lib.mulDiv(2.5e27, 0.5e27, 1e27), 1.25e27);
        assertEq(lib.mulDiv(2.5e18, 0.5e18, 1e18), 1.25e18);
        assertEq(lib.mulDiv(2.5e8, 0.5e8, 1e8), 1.25e8);
        assertEq(lib.mulDiv(369, 271, 1e2), 999);

        assertEq(lib.mulDiv(1e27, 1e27, 2e27), 0.5e27);
        assertEq(lib.mulDiv(1e18, 1e18, 2e18), 0.5e18);
        assertEq(lib.mulDiv(1e8, 1e8, 2e8), 0.5e8);

        assertEq(lib.mulDiv(2e27, 3e27, 2e27), 3e27);
        assertEq(lib.mulDiv(3e18, 2e18, 3e18), 2e18);
        assertEq(lib.mulDiv(2e8, 3e8, 2e8), 3e8);
    }

    function testMulDivEdgeCases_Huffidity() public {
        assertEq(lib.mulDiv(0, 1e18, 1e18), 0);
        assertEq(lib.mulDiv(1e18, 0, 1e18), 0);
        assertEq(lib.mulDiv(0, 0, 1e18), 0);
    }

    function testMulDivZeroDenominatorReverts_Huffidity() public {
        vm.expectRevert(0xad251c27);
        lib.mulDiv(1e18, 1e18, 0);
    }

    function testMulDiv_Huffidity(uint256 x, uint256 y, uint256 denominator) public {
        // Ignore cases where x * y overflows or denominator is 0.
        unchecked {
            if (denominator == 0 || (x != 0 && (x * y) / x != y)) return;
        }

        assertEq(lib.mulDiv(x, y, denominator), (x * y) / denominator);
    }

    ////////////////////////////////////////////////////////////////
    //                       SOLADY MILADY                        //
    ////////////////////////////////////////////////////////////////

    function testMulDiv_Solady() public {
        assertEq(solady.mulDiv(2.5e27, 0.5e27, 1e27), 1.25e27);
        assertEq(solady.mulDiv(2.5e18, 0.5e18, 1e18), 1.25e18);
        assertEq(solady.mulDiv(2.5e8, 0.5e8, 1e8), 1.25e8);
        assertEq(solady.mulDiv(369, 271, 1e2), 999);

        assertEq(solady.mulDiv(1e27, 1e27, 2e27), 0.5e27);
        assertEq(solady.mulDiv(1e18, 1e18, 2e18), 0.5e18);
        assertEq(solady.mulDiv(1e8, 1e8, 2e8), 0.5e8);

        assertEq(solady.mulDiv(2e27, 3e27, 2e27), 3e27);
        assertEq(solady.mulDiv(3e18, 2e18, 3e18), 2e18);
        assertEq(solady.mulDiv(2e8, 3e8, 2e8), 3e8);
    }

    function testMulDivEdgeCases_Solady() public {
        assertEq(solady.mulDiv(0, 1e18, 1e18), 0);
        assertEq(solady.mulDiv(1e18, 0, 1e18), 0);
        assertEq(solady.mulDiv(0, 0, 1e18), 0);
    }

    function testMulDivZeroDenominatorReverts_Solady() public {
        vm.expectRevert(0xad251c27);
        solady.mulDiv(1e18, 1e18, 0);
    }

    function testMulDiv_Solady(uint256 x, uint256 y, uint256 denominator) public {
        // Ignore cases where x * y overflows or denominator is 0.
        unchecked {
            if (denominator == 0 || (x != 0 && (x * y) / x != y)) return;
        }

        assertEq(solady.mulDiv(x, y, denominator), (x * y) / denominator);
    }
}

/// @dev Wrapper contract to put the two libs on equal footing in terms of the call overhead.
contract FixedPointMathLib_Wrapper {
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) external pure returns (uint256 _res) {
        _res = FixedPointMathLib_Solady.mulDiv(x, y, denominator);
    }
}
