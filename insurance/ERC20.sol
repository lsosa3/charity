// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 < 0.7.0;
pragma experimental ABIEncoderV2;
import "./SafeMath.sol";

//Interface or the new token
interface IERC20 {
    //Total supply of the token that will ever exist
    function totalSupply() external view returns (uint256);

    //Returns the balance of an address
    function balanceOf(address account) external view returns (uint256);

    //Returns the number of tokens that the spender is available to spend in behalf of the owner
    function allowance(address owner, address spender) external view returns (uint256);

    //Returns a boolean value as a result of the operation
    function transfer(address recipient, uint256 amount) external returns (bool);

    //Returns a boolean value as a result of the spend operation
    function approve(address spender, uint256 amount) external returns (bool);

    //Returns a boolean value as a result of the operation using the allowance method
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    //Event emited when an amount of tokens is sent
    event Transfer(address indexed from, address indexed to, uint256 ammount);

    //Event emited when an asignation with allowance() method is stablished
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20Basic is IERC20 {

    string public constant name = "ERC20 Lucas Test";
    string public constant symbol = "LMSP";
    uint8 public constant decimals = 18;

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed owner, address indexed spender, uint256 tokens);

    using SafeMath for uint256;

    //Balances
    mapping(address => uint) balances;

    //Mapping of allowed address  
    mapping(address => mapping(address => uint)) allowed;

    uint256 totalSupply_;

    constructor (uint256 initialSupply) public {
        totalSupply_ = initialSupply;
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function increaseTotalSupply(uint newTokensAmount) public {
        totalSupply_ += newTokensAmount;
        balances[msg.sender] += newTokensAmount;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function allowance(address owner, address delegate) public override view returns (uint256) {
        return allowed[owner][delegate];
    }

    function transfer(address recipient, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[recipient] = balances[recipient].add(numTokens);
        emit Transfer(msg.sender, recipient, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);

        emit Transfer(owner, buyer, numTokens);

        return true;
    }
}