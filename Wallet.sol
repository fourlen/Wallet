pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Wallet {


    address public owner;
    address feeCollector = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    uint8 fee = 1;


    event TokenSent(address indexed _tokenAddress, address indexed _to, uint _amount);
    event TokenRecieved(address indexed _tokenAddress, address indexed _sender, uint amount);
    
    event EtherSent(address indexed _to, uint _amount);
    event EtherRecieved(address indexed _sender, uint amount);

    event TokenApproved(address indexed _tokenAddress, address indexed _spender, uint _amount);

    event FeeChanged(uint8 _fee);


    constructor(){
        owner = msg.sender;
    }


    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }


    function sendEtherToWallet() payable public{
        require(msg.value != 0 ether,"Sent Ether Cant Be 0");
        emit EtherRecieved(msg.sender,msg.value);
    }


    function sendWalletEtherToAddress(address _to,uint _amount) public onlyOwner returns(bool){
        require(_to != address(0),"To Address Cant Be 0");
        uint transactionFee = _amount / 100 * fee;
        require(_amount + transactionFee <= address(this).balance ,"Amount Bigger Than Wallet Balance");
        bool result_main = payable(address(_to)).send(_amount);
        require(result_main == true,"Transfer From Wallet To User Failed");
        bool result_fee = payable(address(feeCollector)).send(transactionFee);
        require(result_fee == true,"Fee transaction failed");
        emit EtherSent(msg.sender, _amount);

        return true;
    }


    function sendTokenFromWalletToAddress(address _tokenAddress,address _to,uint _amount) public onlyOwner returns(bool){
        require(_tokenAddress != address(0),"Token Address Cant Be 0");
        require(_to != address(0),"To Address Cant Be 0");

        IERC20 _token = IERC20(_tokenAddress);

        uint256 walletBalance = _token.balanceOf(address(this));
        require(walletBalance > _amount,"Amount Bigger Than Balance");

        bool result = _token.transfer(_to,_amount);
        require(result == true,"Transfer From Owner To Wallet Failed");

        emit TokenSent(_tokenAddress,_to,_amount);

        return result;
    }


    function sendTokenToWallet(address _tokenAddress,uint _amount) public returns(bool){
        require(_tokenAddress != address(0),"Token Address Cant Be 0");

        IERC20 _token = IERC20(_tokenAddress);

        uint256 userBalance = _token.balanceOf(msg.sender);
        require(userBalance > _amount,"Amount Bigger Than Balance");

        uint allowance = _token.allowance(msg.sender, address(this));
        require(allowance >= _amount,"Amount Bigger Than Allowance");
        bool result = _token.transferFrom(msg.sender,address(this),_amount);
        require(result == true,"Transfer From Owner To Wallet Failed");

        emit TokenRecieved(_tokenAddress,msg.sender,_amount);

        return result;
    }


    function approveToken(address _tokenAddress, address _spender, uint _amount) public returns(bool) {
        require(_tokenAddress != address(0),"Token Address Cant Be 0");
        require(_spender != address(0),"Spender Address Cant Be 0");
        

        IERC20 _token = IERC20(_tokenAddress);
        bool result = _token.approve(_spender, _amount);
        require(result == true, "Approve token failed");

        emit TokenApproved(_tokenAddress, _spender, _amount);

        return result;
    }


    function setFee(uint8 _fee) public onlyOwner returns(bool) {
        require(_fee > 0 && _fee < 100, "Fee must be greater than 0 and less than 100");
        fee = _fee;

        emit FeeChanged(_fee);

        return true;
    }
}