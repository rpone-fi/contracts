// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./uniswap/UniswapV2Factory.sol";
import "./uniswap/UniswapV2Pair.sol";

contract UniswapV2FactoryDeployer {
    UniswapV2Factory public factory;

    constructor(address _feeToSetter) public {
        factory = new UniswapV2Factory(_feeToSetter);
    }

    function getPairCodeHash() public pure returns (bytes32) {
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        return keccak256(abi.encodePacked(bytecode));
    }

}

