// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "./interface/ISwapPair.sol";
import "./interface/ISwap.sol";
import "./interface/ISwapMining.sol";

import "./Operatable.sol";

contract Repurchase is Operatable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    using EnumerableSet for EnumerableSet.AddressSet;


    address public immutable usdt;
    address public immutable swapToken;
    address public immutable pair;
    address public emergencyAddress;
    uint256 public amountIn;
    uint256 public duration;
    uint256 public lastBurnNum;
    address public swapMining;

    constructor (
        address _usdt,
        address _swapToken,
        address _pair,
        uint256 _amount,
        address _emergencyAddress,
        uint256 _duration
    ) public {
        require(_amount > 0, "Amount must be greater than zero");
        require(_emergencyAddress != address(0), "Is zero address");
        usdt = _usdt;
        swapToken = _swapToken;
        pair = _pair;
        amountIn = _amount;
        emergencyAddress = _emergencyAddress;
        duration = _duration;
        lastBurnNum = block.number;
    }

    function setAmountIn(uint256 _newIn) public onlyOperator {
        amountIn = _newIn;
    }

    function setDuration(uint256 _duration) public onlyOperator {
        duration = _duration;
    }

    function setSwapMining(address _address) onlyOperator external {
        require(_address != address(0), "Is zero address");
        swapMining = _address;
    }

    function withdrawSwapMining() external {
        ISwapMining(swapMining).takerWithdraw();
    }

    function setEmergencyAddress(address _newAddress) public onlyOperator {
        require(_newAddress != address(0), "Is zero address");
        emergencyAddress = _newAddress;
    }

    function swapAndBurn() external returns (uint256 amountOut){
        require(IERC20(usdt).balanceOf(address(this)) >= amountIn, "Insufficient contract balance");
        require(block.number >= lastBurnNum.add(duration), "not duration");
        (uint256 reserve0, uint256 reserve1,) = ISwapPair(pair).getReserves();
        uint256 amountInWithFee = amountIn.mul(997);
        amountOut = amountIn.mul(997).mul(reserve0) / reserve1.mul(1000).add(amountInWithFee);
        IERC20(usdt).safeTransfer(pair, amountIn);
        ISwapPair(pair).swap(amountOut, 0, address(this), new bytes(0));
        ISwap(swapToken).burn(IERC20(swapToken).balanceOf(address(this)));
        lastBurnNum = block.number;
    }

    function emergencyWithdraw(address _token) public onlyOperator {
        require(IERC20(_token).balanceOf(address(this)) > 0, "Insufficient contract balance");
        IERC20(_token).transfer(emergencyAddress, IERC20(_token).balanceOf(address(this)));
    }
}
