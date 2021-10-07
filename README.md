# Deployless Multicall

An implementation of Multicall contract that doesn't require it to be deployed. Can be used in any EVM chain at any block.

## Usage

[ethcall](https://github.com/Destiner/ethcall) provides a convenient wrapper around low-level interation. Alternatively, you can compile a contract yourself, and make an "read-only deploy" eth_call:

```js
const args = encode(deploylessMulticallAbi, [calls]);
const data = ethers.utils.hexConcat([deploylessMulticallBytecode, args]);
const callData = await provider.call({
	data,
});
const result = decode(multicallAbi, 'aggregate', callData);
return result;
```
where `encode` and `decode` is the ABI coding functions.

## How

Normally, a consturcor in Solidity contract returns the bytecode of the newly created contract. Here, we use inline assembly to overwrite return data with the call result.

The code makes some assuptions about how the variables stored in memory, so it's better to stick to Solidity version specified in the contract.
