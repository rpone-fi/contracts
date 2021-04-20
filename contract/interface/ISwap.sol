// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISwap is IERC20 {
    function mint(address to, uint256 amount) external returns (bool);
    function burn(uint256 _amount) external;
}