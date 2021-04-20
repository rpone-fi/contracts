// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./uniswap/UniswapV2Factory.sol";

contract MockUniswapV2Factory is UniswapV2Factory {
    constructor(address _feeToSetter) public UniswapV2Factory(_feeToSetter) {}
}
