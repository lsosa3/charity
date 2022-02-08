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
        uint Balance = BalanceOf();
        require(_numTokens <= Balance, "Buy less Tokens");

        //Transfer Tokens to the buyer
        token.transfer(msg.sender, _numTokens);

        //Register purchase
        Clients[msg.sender].buyed_tokens += _numTokens;
    }

    //Disney contract Token's balance
    function BalanceOf() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    //Check client's Tokens
    function ClientTokens() public view returns (uint) {
        return token.balanceOf(msg.sender);
    }

    //Function to create more tokens
    function CreateTokens(uint _numTokens) public JustOwner(msg.sender) {
        token.increaseTotalSupply(_numTokens);
    }

    //Check if is owner
    modifier JustOwner(address _address) {
        require(_address == owner,"Dont have permission to execute, just Owner");
        _;
    }



    // ------------------------- DISNEY ATTRACTION MANAGEMENT  -------------------- //

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
    mapping (string => attraction) public mappingAttractions;

    //Array to store attraction's names
    string [] attractions;

    //Mapping to bind an address (client) to its historical data in DISNEY
    mapping (address => string []) attactionsClientHistory;

    //Create new attractions | Just execute disney
    function NewAttraction(string memory _attractionName, uint _price) public JustOwner(msg.sender) {
        //Create new attraction in Disney
        mappingAttractions[_attractionName] = attraction(_attractionName, _price, true);

        //Store attraction's name in attractions array
        attractions.push(_attractionName);

        //Emit event for new attraction
        emit new_attraction(_attractionName, _price);
    }

    //Inactivate attraction
    function RemoveAttraction(string memory _attractionName) public JustOwner(msg.sender) {
        //Check if attraction exists
        require(keccak256(abi.encodePacked(mappingAttractions[_attractionName].name)) == keccak256(abi.encodePacked(_attractionName)), "Attraction don't exists");

        //Change to false attraction status
        mappingAttractions[_attractionName].status = false;

        //Emit event
        emit remove_attraction(_attractionName);
    }

    //View available attractions 
    function AvailableAttractions() public view returns (string [] memory) {
        return attractions;
    }

    function UseAttraction (string memory _attractionName) public {
        //Attraction price in tokens
        uint attractionPriceToken = mappingAttractions[_attractionName].price;

        //Check if attraction is available
        require(mappingAttractions[_attractionName].status == true, "Attraction unavailable");

        //Check if client have enoght token
        require(ClientTokens() >= attractionPriceToken, "Don't have ehough tokens to buy this attraction, please buy more tokens");

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
    function ShowAttractionClientHistory() public view returns (string [] memory) {
        return attactionsClientHistory[msg.sender];
    }

    // ------------------------- DISNEY ATTRACTION MANAGEMENT END -------------------- //



    // ------------------------- DISNEY FOODS MANAGEMENT START -------------------- //

    //Events
    event buy_food(string, uint, address);
    event new_food(string, uint);
    event remove_food(string);

    //Struct for foods
    struct food {
        string name;
        uint price;
        string foodType;
        bool status;
    }

    //Mapping to bind a food to food's struct
    mapping (string => food) public mappingFoods;

    //Array to store food's names
    string [] foods;

    //Mapping to bind an address (client) to its historical data in DISNEY
    mapping (address => string []) foodsClientHistory;

    //Create new foods | Just execute disney
    function NewFood(string memory _foodName, string memory _foodType,  uint _price) public JustOwner(msg.sender) {
        //Create new food in Disney
        mappingFoods[_foodName] = food(_foodName, _price, _foodType, true);

        //Store food's name in attractions array
        foods.push(_foodName);

        //Emit event for new attraction
        emit new_food(_foodName, _price);
    }

    //Inactivate food
    function RemoveFood(string memory _foodName) public JustOwner(msg.sender) {
        //Check if food exists
        require(keccak256(abi.encodePacked(mappingFoods[_foodName].name)) == keccak256(abi.encodePacked(_foodName)), "Food don't exists");

        //Change to false food status
        mappingFoods[_foodName].status = false;

        //Emit event
        emit remove_food(_foodName);
    }

    //View available foods 
    function AvailableFoods() public view returns (string [] memory) {
        return foods;
    }

    //Buy food
    function BuyFood (string memory _foodName) public {
        //food price in tokens
        uint foodPriceToken = mappingFoods[_foodName].price;

        //Check if food is available
        require(mappingFoods[_foodName].status == true, "Food unavailable");

        //Check if client have enoght token
        require(ClientTokens() >= foodPriceToken, "Don't have ehough tokens to buy this food, please buy more tokens");

        /*Client pay for food
        Was nessesary to create a new transfer function called "transferDisney"
        because the address taken were wrong, due to the msg.sender that transfer 
        and transferFrom function were getting was the contract address
        */
        token.transferDisney(msg.sender, address(this), foodPriceToken);
        
        //Store in food history client this food
        foodsClientHistory[msg.sender].push(_foodName);

        //Emit buy food event
        emit buy_food(_foodName, foodPriceToken, msg.sender);
    }

    //Show client food history
    function ShowClientFoodHistory() public view returns (string [] memory) {
        return foodsClientHistory[msg.sender];
    }

    // ------------------------- DISNEY FOODS MANAGEMENT END -------------------- //


    // ------------------------- DISNEY COMMON FUNCTIONS START -------------------- //

    //Return tokens to Disney
    function ReturnTokens(uint _numTokens) public payable {
        //Check if _numTokens is higher than cero
        require(_numTokens > 0, "The tokens must be higher than cero");

        //Check if the tokens qty is a positive number
        require (ClientTokens() >= _numTokens, "The tokens QTY must be lower");

        //The client returns the tokens
        token.transferDisney(msg.sender, address(this), _numTokens);

        //Disney returns the eth
        msg.sender.transfer(TokensPrice(_numTokens));
    }

    // ------------------------- DISNEY COMMON FUNCTIONS END -------------------- //
}