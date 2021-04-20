pragma solidity ^0.5.16;

import './UniswapV2Library.sol';
import '../interface/IFSwapFactory.sol';
import '../interface/IFSwapPair.sol';

import "../interface/IFSwapCallee.sol";
import "../interface/IWETH.sol";

contract ExampleFlashSwap is IFSwapCallee {
    using SafeMath  for uint;

    IFSwapFactory  factoryV1;
    address  factory;
    IWETH  WETH;

    constructor(address _factory,  address _weth) public {
        factory = _factory;
        WETH = IWETH(_weth);
    }

    // needs to accept ETH from any V1 exchange and WETH. ideally this could be enforced, as in the router,
    // but it's not possible because it requires a call to the v1 factory, which takes too much gas
    function() external payable {}

    // gets tokens/WETH via a V2 flash swap, swaps for the ETH/tokens on V1, repays V2, and keeps the rest!
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        address[] memory path = new address[](2);
        sender;
        uint amountToken;
        uint amountETH;
        {// scope for token{0,1}, avoids stack too deep errors
            address token0 = IFSwapPair(msg.sender).token0();
            address token1 = IFSwapPair(msg.sender).token1();
            assert(msg.sender == UniswapV2Library.pairFor(factory, token0, token1));
            // ensure that msg.sender is actually a V2 pair
            assert(amount0 == 0 || amount1 == 0);
            // this strategy is unidirectional
            path[0] = amount0 == 0 ? token0 : token1;
            path[1] = amount0 == 0 ? token1 : token0;
            amountToken = token0 == address(WETH) ? amount1 : amount0;
            amountETH = token0 == address(WETH) ? amount0 : amount1;
        }

        require(path[0] == address(WETH) || path[1] == address(WETH), "path is wrong");
        // this strategy only works with a V2 WETH pair
//        IERC20 token = IERC20(path[0] == address(WETH) ? path[1] : path[0]);


        if (amountToken > 0) {
            //            (uint minETH) = abi.decode(data, (uint));

            //            uint amountReceived = minETH;
            //            uint amountRequired = UniswapV2Library.getAmountsIn(factory, amountToken, path)[0];
            //            require(amountReceived > amountRequired, "amountReceived > amountRequired");
            // fail if we didn't get enough ETH back to repay our flash loan
            //            assert(token.balanceOf(address(this))>0);
            //            WETH.deposit{value : amountRequired}();
            //            assert(WETH.balanceOf(address(this))>0);
            //            assert(WETH.transfer(msg.sender, amountETH));
            // return WETH to V2 pair
            //            (bool success,) = sender.call{value : amountReceived - amountRequired}(new bytes(0));
            // keep the rest! (ETH)
            //            assert(success);
        } else {
            uint minTokens = abi.decode(data, (uint));
            minTokens;
            // slippage parameter for V1, passed in by caller
            uint _amount = amountETH.mul(1010).div(1000);
            WETH.withdraw(_amount);

            WETH.deposit.value(_amount)();
//            uint amountReceived = minTokens;
//            uint amountRequired = UniswapV2Library.getAmountsIn(factory, amountETH, path)[0];
            //            assert(amountReceived > amountRequired);
            //            // fail if we didn't get enough tokens back to repay our flash loan
            assert(WETH.transfer(msg.sender, _amount));
            //            // return tokens to V2 pair
            //            assert(WETH.transfer(sender, amountReceived - amountRequired));
            //            // keep the rest! (tokens)
        }
    }
}
