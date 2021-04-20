// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./Operatable.sol";
import "./interface/ISwap.sol";
import "./TransferHelper.sol";

abstract contract TokenReward is Operatable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The RPT Token!
    ISwap public swapToken;
    // rpt tokens created per block.
    uint256 public tokenPerBlock;
    // The block number when rpt mining starts.
    uint256 public immutable startBlock;
    uint public periodEndBlock;
    // How many blocks (120 days) are halved 3456000
    uint256 public period;
    address public tokenLock;

    uint256 public minTokenReward = 3.75e17;

    constructor(ISwap _swapToken,
        address _tokenLock,
        uint256 _tokenPerBlock,
        uint256 _startBlock,
        uint256 _period) public
    {
        require(_tokenLock != address(0), "address is not 0");
        swapToken = _swapToken;
        tokenPerBlock = _tokenPerBlock;
        startBlock = _startBlock;
        period = _period;
        periodEndBlock = _startBlock.add(_period);
        tokenLock = _tokenLock;
        TransferHelper.safeApprove(address(swapToken), _tokenLock, uint256(- 1));
    }

    modifier reduceBlockReward()  {
        if (block.number > startBlock && block.number >= periodEndBlock) {
            if (tokenPerBlock > minTokenReward) {
                tokenPerBlock = tokenPerBlock.mul(75).div(100);
            }
            if (tokenPerBlock < minTokenReward) {
                tokenPerBlock = minTokenReward;
            }
            periodEndBlock = block.number.add(period);
        }
        _;
    }

    function setHalvingPeriod(uint256 _block) public onlyOperator {
        period = _block;
    }

    function setMinTokenReward(uint256 _reward) public onlyOperator {
        minTokenReward = _reward;
    }

    function setTokenLock(address _address) public onlyOperator {
        require(_address != address(0), "address is not 0");
        tokenLock = _address;
        TransferHelper.safeApprove(address(swapToken), tokenLock, uint256(- 1));
    }


    // Set the number of swap produced by each block
    function setTokenPerBlock(uint256 _newPerBlock, bool _withUpdate) public onlyOperator {
        if (_withUpdate) {
            massUpdatePools();
        }
        tokenPerBlock = _newPerBlock;
    }

    function massUpdatePools() public virtual;


}