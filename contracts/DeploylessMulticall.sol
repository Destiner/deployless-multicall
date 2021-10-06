// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

contract DeploylessMulticall {
    struct Call {
        address target;
        bytes callData;
    }

    constructor(Call[] memory calls) {
        uint256 blockNumber = block.number;
        bytes[] memory returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }

        assembly {
            // 'Multicall.aggregate' returns (uint256, bytes[])
            // Overwrite memory to comply with the expected format
            mstore(sub(returnData, 0x40), blockNumber)
            mstore(sub(returnData, 0x20), 0x40)

            // Fix returnData index pointers
            let indexOffset := add(returnData, 0x20)
            for
                { let pointerIndex := add(returnData, 0x20) }
                lt(pointerIndex, add(returnData, mul(add(mload(returnData), 1), 0x20)))
                { pointerIndex := add(pointerIndex, 0x20) }
            {
                mstore(pointerIndex, sub(mload(pointerIndex), indexOffset))
            }
            
            return(
                sub(returnData, 0x40),
                // We assume that 'returnData' is placed at the end of memory
                // Therefore, 'sub(mload(0x40), returnData' provides the array length
                add(sub(mload(0x40), returnData), 0x40)
            )
        }
    }
}
