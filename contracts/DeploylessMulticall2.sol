// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract DeploylessMulticall2 {
    struct Call {
        address target;
        bytes callData;
    }
    
    struct Result {
        bool success;
        bytes returnData;
    }

    constructor(bool requireSuccess, Call[] memory calls) {
        Result[] memory returnData = new Result[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);

            if (requireSuccess) {
                require(success, "Multicall2 aggregate: call failed");
            }

            returnData[i] = Result(success, ret);
        }

        assembly {
            // returnData.size = memory.size - returnData.pointer - 2 *  32 * returnData.length + 32
            let size := add(sub(sub(mload(0x40), returnData), mul(0x40, mload(returnData))), 0x20)
            let start := sub(sub(mload(0x40), size), 0x40)

            // Fix pointers
            if gt(mload(returnData), 1)
            {
                for
                    { let index := 0 }
                    lt(index, mload(returnData))
                    { index := add(index, 1) }
                {
                    let oldPointer := add(add(returnData, 0x20), mul(0x20, index))
                    let pointer := add(start, add(0x40, mul(0x20, index)))
                    if iszero(index)
                    {
                        mstore(pointer, mul(0x20, mload(returnData)))
                    }
                    if gt(index, 0)
                    {
                        let length := sub(
                            mload(add(mload(oldPointer), 0x20)),
                            mload(add(mload(sub(oldPointer, 0x20)), 0x20))
                        )
                        let value := add(mload(sub(pointer, 0x20)), length)
                        mstore(pointer, value)
                    }
                }
            }
            
            // Fix order: (returnData, success) -> (success, returnData)
            for
                { let index := 0 }
                lt(index, mload(returnData))
                { index := add(index, 1) }
            {
                let oldPointer := add(add(returnData, 0x20), mul(0x20, index))
                mstore(sub(mload(add(mload(oldPointer), 0x20)), 0x40), mload(mload(oldPointer)))
            }
            
            // Fix lengths
            for
                { let index := 0 }
                lt(index, mload(returnData))
                { index := add(index, 1) }
            {
                let oldPointer := add(add(returnData, 0x20), mul(0x20, index))
                mstore(sub(mload(add(mload(oldPointer), 0x20)), 0x20), 0x40)
            }

            // Fix pointers (single element)
            if eq(mload(returnData), 1)
            {
                let oldPointer := add(returnData, 0x20)
                let pointer := add(start, 0x40)
                mstore(pointer, mul(0x20, mload(returnData)))
            }
            
            // Write header
            mstore(start, 0x20)
            mstore(add(start, 0x20), mload(returnData))
            
            return(start, size)
        }
    }
}
