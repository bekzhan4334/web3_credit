//SDPX-Lisense-Identifier: UNLICENSED

pragma solidity ^0.8.15;

//task3

contract Wallet{

    mapping(address => uint) public balances;

    function addBalance()external payable{
        balances[msg.sender] = msg.value;
    }

    function transferEth(address recipient, uint value)external virtual {
        require(value <= balances[msg.sender], "Not enough funds");
        balances[msg.sender] -= value;
        balances[recipient] += value;
    }

    function withdraw(uint value)external virtual{
        require(value <= balances[msg.sender], "Not enough funds");
        balances[msg.sender] -= value;
        payable(msg.sender).transfer(value);
    }
}

contract Bank{

    struct Stake{
        uint target;
        uint balance;
    }

    mapping(address => Stake) public stakes;

    function addStake(uint target)external payable{

        if(stakes[msg.sender].balance == 0){
            stakes[msg.sender] = Stake(target, msg.value);
        }
        else if(stakes[msg.sender].balance > 0){
            if(target > stakes[msg.sender].target){
                 stakes[msg.sender].target = target;
                 stakes[msg.sender].balance += msg.value;
            }
            else{
            stakes[msg.sender].balance += msg.value;
        }
        }
        else{
            stakes[msg.sender].balance += msg.value;
        }
        
    }

    function unstake()external virtual{
        require(stakes[msg.sender].balance >= stakes[msg.sender].target);
        payable(msg.sender).transfer(stakes[msg.sender].balance);
        stakes[msg.sender].balance = 0;
    }
}

contract Credit is Wallet, Bank{

    //unchangable percent
    uint immutable public percent;
    //Funds of the bank
    uint public bankBalance;
    //amount of opened credits
    uint public openCredit;
    address owner;

    struct Credit{
        //Долг
        uint debt;
        //залог
        uint bail;
        uint time;
        uint id;
        //last payment -> month
        uint8 lastPayment;
    }

    mapping(uint => address) public borrowers;

    mapping(address => Credit) public credits;

    constructor(uint _percent)payable{
        percent = _percent;
        owner = msg.sender;
        bankBalance = msg.value;
    }

    function getCredit(uint _debt)external {
        require(bankBalance > _debt);
        require(credits[msg.sender].debt == 0);

        require(stakes[msg.sender].balance + balances[msg.sender] >= _debt * 2);
        openCredit++;

        borrowers[openCredit] = msg.sender;
        credits[msg.sender] = Credit(_debt, _debt * 2, block.timestamp,openCredit, 0);
        bankBalance -= _debt;
        payable(msg.sender).transfer(_debt);
    }

    function repayLoan()external payable{
        require(msg.value > 0);
        require(credits[msg.sender].debt != 0);

        //Saving it locally to save gas
        Credit memory credit = credits[msg.sender];

        //How many months passed from taking a credit 
        uint8 month = uint8((block.timestamp - credit.time) / 30 days);

        for(uint i = 0; i < month - credit.lastPayment; i++){
            credit.debt += credit.debt * percent / 100;
        }

        if(msg.value >= credit.debt){
            bankBalance += credit.debt;
            balances[msg.sender] += msg.value - credit.debt;
            if(credit.id != openCredit){
                credits[borrowers[openCredit]].id = credit.id;
                borrowers[credit.id] = borrowers[openCredit];
            }
            delete credits[msg.sender];
            delete borrowers[openCredit];
            openCredit--;
        }
        else{
            bankBalance += msg.value;
            credit.debt -= msg.value;
            credit.bail = credit.debt * 2;
            credit.lastPayment = month;
            credits[msg.sender] = credit;
        }
    }

    function closeCredit(address debtor)external {

        //checking the owner 
        require(msg.sender == owner);
        
        //saving structure locally to save gas
        Credit memory credit = credits[debtor];

        // Credit should have a debt
        require(credit.debt != 0);

        // Calculating how many months passed are after taking a credit
        uint8 month = uint8((block.timestamp - credit.time) / 30 days);

        // Checking if the credit can be closed
        require(month > 12 || month - (credit.lastPayment) > 4);

        // Adding percents for the month that are unpaid
        for(uint i = 0; i < month - credit.lastPayment; i++){
            credit.debt += credit.debt * percent / 100;
        }

        // Updaing the bail
        credit.bail = credit.debt * 2;

        // if bail bigger than balance and stakes 
        if(credit.bail > balances[debtor] + stakes[debtor].balance){
            // then we transferring all of the funds to the bank
            bankBalance += balances[debtor] + stakes[debtor].balance;
            balances[debtor] = 0;
            stakes[debtor].balance = 0;
        }
        // if balance is greater than bail 
        else if(balances[debtor] > credit.bail){
           bankBalance += credit.bail;
           balances[debtor] -= credit.bail;
        }
        else{
            // transfering funds to the bank
            bankBalance += credit.bail;
            // taking everything from the balance first
            credit.debt -= balances[debtor];
            balances[debtor] = 0;
            // and the rest from the stakes
            stakes[debtor].balance -= credit.debt;
        }
      
        //deleting the credit 
        if(credit.id != openCredit){
            credits[borrowers[openCredit]].id = credit.id;
            borrowers[credit.id] = borrowers[openCredit];
        }
            delete credits[debtor];
            delete borrowers[openCredit];
            openCredit--;
        
    }

    function getCredits() external view returns(Credit[] memory){
        require(msg.sender == owner, "Youre not owner!");
        //creating a list to add open credits there
        Credit[] memory tempCredits = new Credit[](openCredit);

        // iterating all of the opened credits
        for(uint i = 1; i <= openCredit; i++){
            tempCredits[i-1] = credits[borrowers[i]];
        }

        return tempCredits;
        
    }

    function recalculation(address debtor)public returns(Credit memory){
        //saving debtor credit locally
        Credit memory credit = credits[debtor];
        
        //checking if credit is not paid yet
        if(credit.debt != 0){
            // how many months passed after credit was taken
            uint8 month = uint8((block.timestamp - credit.time)/30 days);

            for(uint i = 0; i < month - credit.lastPayment; i++){
                credit.debt += credit.debt * percent / 100;
            }

            credit.bail = credit.debt * 2;
            credits[debtor] = credit;

            return credit;
        }
    }

    function transferEth(address recipient, uint value)external override {
        require(value <= balances[msg.sender], "Not enough funds");

        recalculation(msg.sender);

        uint remain = balances[msg.sender] + stakes[msg.sender].balance - value;
        require(remain >= credits[msg.sender].bail, "You don't have enough funds, because of the credit");
        balances[msg.sender] -= value;
        balances[recipient] += value;
    }

    function withdraw(uint value)external override {
        require(value <= balances[msg.sender], "Not enough funds");

        recalculation(msg.sender);

        uint remain = balances[msg.sender] + stakes[msg.sender].balance - value;
        require(remain >= credits[msg.sender].bail, "You don't have enough funds, because of the credit");
        balances[msg.sender] -= value;
        payable(msg.sender).transfer(value);
    }

    function unstake()external override {
        require(stakes[msg.sender].balance >= stakes[msg.sender].target);

        recalculation(msg.sender);

        require(balances[msg.sender] >= credits[msg.sender].bail);

        payable(msg.sender).transfer(stakes[msg.sender].balance);
        stakes[msg.sender].balance = 0;
    }

    function withdrawFunds(uint value)external {
        require(msg.sender == owner, "You're not owner");
        require(bankBalance > value);
        payable(owner).transfer(value);
    }

    function depositCap(uint value)external payable{
        bankBalance += msg.value;
    }

}


    




