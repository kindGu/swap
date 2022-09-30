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
}
