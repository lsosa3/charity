// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 < 0.7.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

contract Disney {

    // ------------------------- Initial Declarations ---------------------//

    //Contract instance
    ERC20Basic private token;

    //Disney address (owner)
    address payable public owner;

    //Constructor
    constructor () public {
        token = new ERC20Basic(1000000);
        owner = msg.sender;
    }

    //Struct to store the disney's clients
    struct client {
        uint buyed_tokens;
        string [] enjoyed_attractions;
    }

    //Mapping for clients
    mapping (address => client) public Clients;

    // ------------------- TOKEN MANAGEMENT ----------------------------//

    //Function to stablish the token price
    function TokensPrice(uint _numTokens) internal pure returns (uint) {
        //Convert Tokens to Ethers: 1 Token -> 1 ether
        return _numTokens*(1 ether);
    }

    //function to buy Tokens at disney and enjoy atractions
    function BuyTokens(uint _numTokens) public payable {
        //Get tokens price
        uint price = TokensPrice(_numTokens);

        //Check if have enough to pay
        require (msg.value >= price, "Buy less tokens or Pay more eth");

        //Difference of what client pay
        uint returnValue = msg.value - price;

        //Disney return that difference of ethers to the client
        msg.sender.transfer(returnValue);

        //Get the amount of availables Tokens
        uint Balance = balanceOf();
        require(_numTokens <= Balance, "Buy less Tokens");

        //Transfer Tokens to the buyer
        token.transfer(msg.sender, _numTokens);

        //Register purchase
        Clients[msg.sender].buyed_tokens += _numTokens;
    }

    //Disney contract Token's balance
    function balanceOf() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    //Check client's Tokens
    function clientTokens() public view returns (uint) {
        return token.balanceOf(msg.sender);
    }

    //Function to create more tokens
    function createTokens(uint _numTokens) public justOwner(msg.sender) {
        token.increaseTotalSupply(_numTokens);
    }

    //Check if is owner
    modifier justOwner(address _address) {
        require(_address == owner,"Dont have permission to execute, just Owner");
        _;
    }



    // ------------------------- DISNEY MANAGEMENT  -------------------- //

    //Events
    event enjoy_attaction(string, uint, address);
    event new_attraction(string, uint);
    event remove_attraction(string);

    //Struct for attractions
    struct attraction {
        string name;
        uint price;
        bool status;
    }

    //Mapping to bind an attraction to attraction's struct
    mapping (string => attraction) public MappingAttractions;

    //Array to store attraction's names
    string [] attractions;

    //Mapping to bind an address (client) to its historical data in DISNEY
    mapping (address => string []) attactionsClientHistory;

    //Create new attractions | Just execute disney
    function newAttraction(string memory _attractionName, uint _price) public justOwner(msg.sender) {
        //Create new attraction in Disney
        MappingAttractions[_attractionName] = attraction(_attractionName, _price, true);

        //Store attraction's name in attractions array
        attractions.push(_attractionName);

        //Emit event for new attraction
        emit new_attraction(_attractionName, _price);
    }

    //Inactivate attraction
    function removeAttraction(string memory _attractionName) public justOwner(msg.sender) {
        //Check if attraction exists
        require(keccak256(abi.encodePacked(MappingAttractions[_attractionName].name)) == keccak256(abi.encodePacked(_attractionName)), "Attraction don't exists");

        //Change to false attraction status
        MappingAttractions[_attractionName].status = false;

        //Emit event
        emit remove_attraction(_attractionName);
    }

    //View available attractions 
    function availableAttractions() public view returns (string [] memory) {
        return attractions;
    }

    function useAttraction (string memory _attractionName) public {
        //Attraction price in tokens
        uint attractionPriceToken = MappingAttractions[_attractionName].price;

        //Check if attraction is available
        require(MappingAttractions[_attractionName].status == true, "Attraction unavailable");

        //Check if client have enoght token
        require(clientTokens() >= attractionPriceToken, "Don't have ehough tokens to buy this attractio, please buy more tokens");

        /*Client pay for attraction
        Was nessesary to create a new transfer function called "transferDisney"
        because the address taken were wrong, due to the msg.sender that transfer 
        and transferFrom function were getting was the contract address
        */
        token.transferDisney(msg.sender, address(this), attractionPriceToken);
        
        //Store in attraction history client this attracction
        attactionsClientHistory[msg.sender].push(_attractionName);

        //Emit enjoy attraction event
        emit enjoy_attaction(_attractionName, attractionPriceToken, msg.sender);
    }

    //Show client attraction history
    function showClientHistory() public view returns (string [] memory) {
        return attactionsClientHistory[msg.sender];
    }

    //Return tokens to Disney
    function returnTokens(uint _numTokens) public payable {
        //Check if _numTokens is higher than cero
        require(_numTokens > 0, "The tokens must be higher than cero");

        //Check if the tokens qty is a positive number
        require (clientTokens() >= _numTokens, "The tokens QTY must be lower");

        //The client returns the tokens
        token.transferDisney(msg.sender, address(this), _numTokens);

        //Disney returns the eth
        msg.sender.transfer(TokensPrice(_numTokens));
    }
}