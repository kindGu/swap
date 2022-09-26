//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Math.sol";
import "./IERC20.sol";
import "./iPair.sol";
import "./iFactory.sol";
import "./SafeMath.sol";

contract Pair is ERC20{
    using SafeMath  for uint;

    address public factory;
    address public token0;
    address public token1;
    uint public constant INITIAL_SUPPLY = 10**3;
    uint private reserve0;
    uint private reserve1;
    uint public kLast;
    //更新
    uint public price0CumulativeLast;
    uint public price1CumulativeLast;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

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
    event Sync(uint reserve0, uint reserve1);

    uint private unlocked = 1;
    modifier lock() {//锁
        require(unlocked == 1, 'error: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    
     constructor() public {
        factory = msg.sender;
    }

    function initialize(address _token0, address _token1) external{
        require(msg.sender == factory, 'error: factory'); 
        token0 = _token0;
        token1 = _token1;
    }

    function getReserves() public view returns (uint _reserve0, uint _reserve1){
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }
    
    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        //https://solidity-by-example.org/call/
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'error: Transfer fail');
    }
 
    function _update(uint balance0, uint balance1) private{
        require(balance0 <= type(uint).max && balance1 <= type(uint).max, 'error: overflow');
        reserve0 = uint(balance0);
        reserve1 = uint(balance1);
        emit Sync(reserve0, reserve1);
    }

    function _mintFee(uint112 _reserve0, uint112 _reserve1) private{
        address feeTo = iFactory(factory).feeTo();
        uint _kLast = kLast;
        if (_kLast != 0) {
            uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
            uint rootKLast = Math.sqrt(_kLast);
            if (rootK > rootKLast) {
                uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                uint denominator = rootK.add(rootKLast);
                    //  1/2
                uint liquidity = numerator / denominator;
                if (liquidity > 0) _mint(feeTo, liquidity);
            }
        }
    }
    
    function mint(address to) external lock returns (uint liquidity) {
        (uint _reserve0, uint _reserve1) = getReserves();
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);
        
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            _mint(msg.sender, INITIAL_SUPPLY);
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
            //S = min(amount0 * totaSupply / reserue0, amount1 * totaSupply / reserue1;
        }
        require(liquidity > 0, 'error: liquidity Less than zero');
        _mint(to, liquidity);
        
        _update(balance0, balance1);
        kLast = uint(reserve0).mul(reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        //(uint _reserve0, uint _reserve1) = getReserves(); 
        address _token0 = token0;
        address _token1 = token1; 
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];
        
        uint _totalSupply = totalSupply;
        amount0 = liquidity.mul(balance0) / _totalSupply;
        amount1 = liquidity.mul(balance1) / _totalSupply;
        require(amount0 > 0 && amount1 > 0, 'error: burn token inadequate');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        
        _update(balance0, balance1);
        kLast = uint(reserve0).mul(reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    function swap(uint amount0Out, uint amount1Out, address to) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'error: Not enough output tokens');
        (uint _reserve0, uint _reserve1) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'error: Insufficient flow cell');
        
        uint balance0;
        uint balance1;
        {//乐观交换, 如果余额不够, 则回退
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'error: address error');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); 
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); 
        
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        //通过balance和reserve的差值，可以反推出输入的代币数量
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'error: input Insufficient');
        { 
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'error: go back');
        }
        
        _update(balance0, balance1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }
    function skim(address to) external lock {
        address _token0 = token0; 
        address _token1 = token1; 
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

}