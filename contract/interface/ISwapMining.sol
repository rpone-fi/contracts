// SPDX-License-Identifier: MIT
interface ISwapMining {
    function swap(address account, address input, address output, uint256 amount) external returns (bool);
    function takerWithdraw() external;
}