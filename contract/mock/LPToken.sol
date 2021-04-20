pragma solidity =0.5.16;

import '../FSwapFactory.sol';

contract LPToken is FSwapERC20 {
    constructor(uint _totalSupply) public {
        _mint(msg.sender, _totalSupply);
    }
}
