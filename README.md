# swap

**Router  --(调用)-->  Factory  --(创建)-->  Piar  --(引用)-->  ERC20**

**Router**
* SWAP
* SWAP ETH
* Add/remove 流动池
* Add/remove ETH流动池

**Factory**
* createPiar

**Piar**
* mint
* burn
* update
* skny

**Ticket**
* getTicket
* random
* transfer


## X * Y = k
交易前后 两个代币数量乘积不变, 

tokenA 和 tokenB, 数量为X, Y, 
使用 ∆x 的tokenA来购买tokenB, 或多少的tokenA才能换取 ∆y 的tokenB

```
(x+∆x)(y-∆y) = k
```

tokenA的变化率: ```  α = ∆x/x  ```
tokenB的变化率: ```  β = ∆y/y  ```

```
  {
  x + ∆x = (1 + ∆x) x = x / 1 - β
  y - ∆y = y / (1 + α) = (1 - β) y

  ∆x = (β * x) / (1 - β)
  ∆y = (α * y) / (1 + α)
  }
```
 
在不收取手续费的前提下,swap前与swap后都需要满足 X * Y = K, 
但在收取手续费后, swap前输入的交换代币A amount * (手续费费率0.3%), 
而在交换后代币B后, 池子里代币数量X, Y, 都进行了增加(LP代币总量不变, 池子里的金额数量增加)

```
uint balance_djusted = balance1.mul(1000).sub(amount1In.mul(3)); 
```

```
∆x = (β * x) / (1 - β) * (1 / r)
∆y = (α * r * y) / (1 + α * r)
```

```
function input(uint amount1, uint reservein, uint reserveout)returns(uint){
  require(reservein>0 && reserveout>0);
  uint fee = amount1.mul(1000).sub(3);
  uint numerator = fee * reserveout;
  uint denominator = reservein.mul(1000) + fee;
  return numerator/denominator;
  }


function output(uint amount, uint reservein, uint reserveout)returns(uint){
  require(reservein>0 && reserveout>0);
  uint numerator = reservein.mul(reserveout).mul(1000);
  uint denominator = (reserveout - amount).mul(997);
  return numerator/denominator + 1;
  }
```

而对于团队所收取的手续费则是在增加流动性与消除流动性时进行计算, 
某 交易池 的财富量为: ```  W = f(x, y)=sqrt(x * y)  ```
即 在所有的0.3%手续费中抽取1/6提取给团队, 剩下的交由流动提供者(返还LP token)
在添加/消除流动池之前, 都需要先将手续费进行结清
```
(rootK - rootKLast) / (5rootk + rootKLast)
```

```
  {
  ∆ = rootK - rootKLast 
  lp/lp_supply = (∆/6) / [(∆5/6) + rootKLast]
  lp = lp_supply * ∆ / (5rootK + rootKLast)
  
  
  kLast = uint(reserve0).mul(reserve1);//更为节省gas
  cumulatedFee += ( sqrt(reserve0 * reserve1) - rootKBefore );
  }
```

## 如何计算发放给团队的手续费数量
由于在每一笔的swap上，手续费都会累次增加（ √k ），
而对比 t1 与 t2 时刻的 √k1 和 √k2 ,其差值就是 t1 与 t2 时刻的手续费，
则在某一时间段 （t1, t2） 手续费就得出
```
f(t1,t2) = (√k2 - √k1) / √k2
```
而当在 t2 时刻时，LPtoken的总供应量为 S1 ,需要发放给团队的为S
由于 发送给团队的LPtoken是先于 mint与burn 之前的，
```
f(t1,t2) * r = S / (S + S1)
```
所以，发放给团队的手续费为： 
```
S =  (√k2 - √k1) / ( (1 / r) * (√k2 + √k1) ) * S1
```
//将所有手续费的一半分给流动提供者, 余下一半的其中一部分作为彩票奖池

## 添加流动池
(第一次添加流动池 与 除第一笔添加流动池 的情况)

在第一次添加时, 为了避免损失, 需要依照当时两币的市价比去提供相应的价值(数量* 价格), 
添加流动池后，返回的为LP token，而mint触发是Router通过factory向pair发送代币之后，中间是有一次gas损失，
所以合约的储备量和合约的token不相等，中间的差值就是要mint 的token数量

即，amount0 和amount1 ，随后则需要进行收取手续费

第一次添加流动池：
```  S = √（∆x * ∆y） = √k  ```

1 tokenA = 100 tokenB
存入2tokenA + 200tokenB = 20 LPtoken 
可以防止抬高流动性单价从而垄断交易对

除第一次添加流动池： 

```
S = min(amount0 * totaSupply / reserue0, amount1 * totaSupply / reserue1;
```

## 彩票
通过添加流动性获取LPtoken 由LPtoken的数量分配数字

```
function getTicket(uint amount) public view returns(uint){
  return (amount % 5);
}
```

随机数的产生  范围 0 至 number

```
function random(uint number) public view returns(uint) {
    return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % number;
}
```
