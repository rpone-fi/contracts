// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "./Operatable.sol";
import "./TransferHelper.sol";
import "./interface/ITokenLock.sol";

// Each block produces 10 coins,
// of which 3.75 coins are used for liquidity mining,
// 3.75 coins are used for transaction mining, and 2.5 coins are given to the foundation
contract SwapToken is ERC20, Operatable {
    using SafeMath for uint256;

    uint256 public constant maxSupply = 3.6e8 * 1e18;     // the total supply
    EnumerableSet.AddressSet private fundAddrs;
    uint256 constant public fundRate = 25;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _minters;
    address public tokenLock;

    constructor() public ERC20("Rpone Finance Token", "rpt"){

    }

    function addFundAddr(address _addr) onlyOperator public {
        require(fundAddrs.length() < 100, "less 100");
        require(_addr != address(0), "address not 0");
        fundAddrs.add(_addr);
    }

    function removeFundAddr(address _addr) onlyOperator public {
        fundAddrs.remove(_addr);
    }

    function contains(address _addr) public view returns (bool){
        return fundAddrs.contains(_addr);
    }

    function fundAddrsLength() public view returns (uint256){
        return fundAddrs.length();
    }

    function claimFund() external {
        require(fundAddrs.length() > 0, "length is 0");
        uint256 fund = IERC20(address(this)).balanceOf(address(this));
        uint256 average = fund.div(fundAddrs.length());
        for (uint256 i = 0; i < fundAddrs.length(); i++) {
            uint256 _amount = average;
            address fundAddress = fundAddrs.at(i);
            if (tokenLock != address(0) && ITokenLock(tokenLock).lockRate() > 0) {
                ITokenLock(tokenLock).getReward(fundAddress);
                uint256 lock = ITokenLock(tokenLock).calLockAmount(_amount);
                ITokenLock(tokenLock).lockToken(fundAddress, lock);
                _amount = _amount.sub(lock);
            }
            TransferHelper.safeTransfer(address(this), fundAddress, _amount);
        }
    }

    // mint with max supply
    function mint(address _to, uint256 _amount) public onlyMinter returns (bool) {
        if (_amount.add(totalSupply()) > maxSupply) {
            return false;
        }
        //Each time, 25% more coins will be minted for the foundation
        uint _fund = _amount.mul(fundRate).div(100 - fundRate);
        _mint(address(this), _fund);
        _mint(_to, _amount);
        return true;
    }

    function setTokenLock(address _address) public onlyOperator {
        tokenLock = _address;
        TransferHelper.safeApprove(address(this), tokenLock, uint256(- 1));
    }

    function getOtherToken(address reserve) external onlyOperator {
        require(reserve != address(this), "no token");
        uint amount = IERC20(reserve).balanceOf(address(this));
        TransferHelper.safeTransfer(reserve, operator, amount);
    }

    function burn(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }

    function addMinter(address _addMinter) public onlyOperator returns (bool) {
        require(_addMinter != address(0), ": _addMinter is the zero address");
        return EnumerableSet.add(_minters, _addMinter);
    }

    function delMinter(address _delMinter) public onlyOperator returns (bool) {
        require(_delMinter != address(0), ": _delMinter is the zero address");
        return EnumerableSet.remove(_minters, _delMinter);
    }

    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(_minters, account);
    }

    function getMinter(uint256 _index) public view onlyOwner returns (address){
        require(_index <= getMinterLength() - 1, ": index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    // modifier for mint function
    modifier onlyMinter() {
        require(isMinter(msg.sender), "caller is not the minter");
        _;
    }

}
