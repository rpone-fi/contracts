// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ITokenLock {

    function balanceOf(address account) external view returns (uint256);

    function calLockAmount(uint amount) external view returns (uint256);

    function lockRate() external view returns (uint256);

    function lockToken(address account, uint256 amount) external;

    function getReward(address account) external;
}