//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./iWTH.sol";
import "./IERC20.sol";
import "./iFactory.sol";
import "./SafeMath.sol";

contract Router{
  using SafeMath for uint;
  address public immutable override factory;
  address public immutable override WETH;
  
  constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }
    
    function _addLiquidity(
      address tokenA,
      address tokenB,
      uint ADesired,
      uint BDesired,
      uint Amin,
      uint Bmin) internal virtual returns (uint amountA, uint amountB){
          if(iFactory(factory).getPair(tokenA, tokenB) == address(0)){
            iFactory(factory).createPair(tokenA, tokenB);
          }
          //排序
      }
}
