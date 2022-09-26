//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./iFactory.sol";
import "./Pair.sol";

contract Factory is iFactory {
    address public override feeTo;
    address public override feeToSetter;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view override returns (uint) {
    return allPairs.length;
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'error: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'error: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pairAddr) {
        require(tokenA != tokenB, 'error: same contract');
        
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        require(token0 != address(0), 'error: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'error: ZERO_ADDRESS'); 

        Pair pair = new Pair(); 
        pair.initialize(tokenA, tokenB);

        pairAddr = address(pair);
        
        getPair[tokenA][tokenB] = pairAddr;
        getPair[tokenB][tokenA] = pairAddr;
        allPairs.push(pairAddr);

        emit PairCreated(token0, token1, pairAddr, allPairs.length);
}
}