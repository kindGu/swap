//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./iPir.sol";
import "./ifactory.sol";

contract Pair is iPair, ERC20 {
    address public factory;
    address public token0;
    address public token1;
    uint public constant MINIMUM_LIQUIDITY = 10**3;
    uint private reserve0;
    uint private reserve1;
    uint public kLast;
    //更新
    
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1); 
    
    uint private unlocked = 1;
    modifier lock() {//锁
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    
     constructor() public {
        factory = msg.sender;
    }
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'error: factory'); 
        token0 = _token0;
        token1 = _token1;
    }

    function getReserves() public view returns (uint _reserve0, uint _reserve1){
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }
    
    function _safeTransfer(address token, address to, uint value) private {
        require(token != address(0), "token is 0x0");
        require(to != address(0), "to is 0x0");
        asser(IERC20(token).Transfer(address(0), to, value));
    }
    function setReserves(uint balance0, uint balance1) private {
        require(balance0 <= uint(-1) && balance1 <= uint(-1), 'error: overflow');
        reserve0 = uint(balance0);
        reserve1 = uint(balance1);
        emit Sync(reserve0, reserve1);
    }
    function mint(address to) external lock returns (uint liquidity) {
        (uint _reserve0, uint _reserve1,) = getReserves();
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);
        
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            _mint();
        }
    }
}
