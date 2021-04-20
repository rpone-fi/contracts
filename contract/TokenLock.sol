// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import './TransferHelper.sol';
import "./Operatable.sol";

contract TokenLock is Operatable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint256 constant MAX_LOCK = 1e5;
    uint256 public lockRate = 5e4;

    uint public period = 2880000;

    struct UserInfo {
        uint256 amount;
        uint256 withdrawBlockNum;
    }

    uint256 internal _totalSupply;
    mapping(address => UserInfo) public userInfo;
    address immutable public token;

    constructor(address _token) public {
        token = _token;
    }

    function lockToken(address account, uint256 amount) public {
        UserInfo storage user = userInfo[account];
        if (user.withdrawBlockNum == 0) {
            user.withdrawBlockNum = block.number;
        }
        uint256 beforeAmount = IERC20(token).balanceOf(address(this));
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
        uint256 afterAmount = IERC20(token).balanceOf(address(this));

        uint256 _amount = afterAmount.sub(beforeAmount);

        _totalSupply = _totalSupply.add(_amount);
        user.amount = user.amount.add(_amount);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function calLockAmount(uint amount) public view returns (uint256) {
        return amount.mul(lockRate).div(MAX_LOCK);
    }

    function balanceOf(address account) public view returns (uint256) {
        UserInfo storage user = userInfo[account];
        return user.amount;
    }

    function getReward(address account) public {
        uint _amount = getUnlock(account);
        if (_amount == 0) {
            return;
        }
        UserInfo storage user = userInfo[account];
        if (_amount > user.amount) {
            _amount = user.amount;
        }
        user.amount = user.amount.sub(_amount);
        _totalSupply = _totalSupply.sub(_amount);
        TransferHelper.safeTransfer(token, account, _amount);
        user.withdrawBlockNum = block.number;
    }

    function getUnlock(address account) public view returns (uint256){
        UserInfo memory user = userInfo[account];
        if (user.amount == 0) {
            return 0;
        }
        uint _amount = user.amount.mul(block.number - user.withdrawBlockNum).div(period);
        if (_amount > user.amount) {
            _amount = user.amount;
        }
        return _amount;
    }

    function getOtherToken(address _token) external onlyOperator {
        require(_token != token, "no token");
        uint amount = IERC20(_token).balanceOf(address(this));
        TransferHelper.safeTransfer(_token, operator, amount);
    }

    function setLockRate(uint256 _rate) public onlyOperator {
        require(_rate <= MAX_LOCK.div(2), "rate < max");
        lockRate = _rate;
    }

    function setPeriod(uint256 _period) public onlyOperator {
        period = _period;
    }

}
