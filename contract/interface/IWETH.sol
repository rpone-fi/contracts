// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;

interface IWETH {
    function balanceOf(address owner) external view returns (uint);

    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}
