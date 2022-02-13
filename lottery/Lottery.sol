// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 < 0.7.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

contract Lottery {
    // ------------------------- Initial Declarations ---------------------//

    //Contract instance
    ERC20Basic private token;

    //Lottery address owner
    address public owner;
    address public contractt;

    //Tokens created
    uint public tokens_created = 10000;

    //Event token buy
    event buy_token(address, uint);

    //Constructor
    constructor () public {
        token = new ERC20Basic(tokens_created);
        owner = msg.sender;
        contractt = address(this);
    }

    // ---------------------------------------------------------------------//


    // --------------------------- TOKEN -----------------------------------//

    //Modifier to make functions only accesibles for the contract owner
    modifier JustOwner(address _addr) {
        require (_addr == owner, "Don't have enough permission to do this!!!");
        _;
    }

    // Get the price of token in eth
    function TokenPrice(uint _numTokens) internal pure returns (uint) {
        return _numTokens * (1 ether);
    }

    //Function to create more tokens
    function CreateTokens(uint _numTokens) public JustOwner(msg.sender) {
        token.increaseTotalSupply(_numTokens);
    }

    //Function to buy tokens to then buy lottery tickets
    function BuyTokens(uint _numTokens) public payable {
        //Get the token price
        uint tokenPrice = TokenPrice(_numTokens);

        //Check if the client have enough eth
        require(msg.value >= tokenPrice, "Buy less tokens or pay with more eth");

        //Return difference
        uint returnValue = msg.value - tokenPrice;

        //Transfer the difference
        msg.sender.transfer(returnValue);

        //Get the amount of tokens available in the contract
        uint balance = AvailableTokens();

        //Check if there is enough tokens for the buyer
        require (balance >= _numTokens, "Buy less tokens please");

        //Send tokens to de buyer
        token.transfer(msg.sender, _numTokens);

        //Emit buy_token event
        emit buy_token(msg.sender, _numTokens);
    }

    //Retuns the available tokens in the contract
    function AvailableTokens() public view returns (uint) {
        return token.balanceOf(contractt);
    }

    //Get the prize acumulated amount
    function Prize() public view returns (uint) {
        return token.balanceOf(owner);
    }

    //Check client tokens
    function MyTokens() public view returns (uint) {
        return token.balanceOf(msg.sender);
    }

    // --------------------------- TOKEN END-----------------------------------//



    // --------------------------- LOTTERY -----------------------------------//

    // Ticket prize
    uint public ticketPrice = 5;

    // Mapping to bind the ticket buyer and ticket numbers
    mapping (address => uint []) buyer_tickets;

    // Mapping to bing the ticket winner to the address
    mapping (uint => address) tickets_to_addr;

    // Random number
    uint randNonce = 0;

    //Generated tickets numbers
    uint [] purchasedTickets;

    // Event when a ticket is purchased
    event purchased_ticket(uint, address);

    // Event when there is a winner
    event winner_ticket(uint);

    //Function to buy tickets
    function BuyTickets(uint _tickets) public {
        // Total amount of tickets to buy
        uint totalAmount = _tickets * ticketPrice;

        // Check if buyer have enough tokens
        require(MyTokens() >= totalAmount, "Don't have enough tokens, please buy more tokens or buy less tickets");

        /*Transfer the buyers tokens to the contract owner
        Was nessesary to create a new transfer function called "transferDisney"
        because the address taken were wrong, due to the msg.sender that transfer 
        and transferFrom function were getting was the contract address
        */
        token.transferLottery(msg.sender, owner, totalAmount);

        /*
        For to calculate tickets numbers and assign it to the tickets buyer
        this takes  the time stamp, the buyer address and a nonce (a number that we use just one time)
        just to not execute this with the same parameters twice them we use 
        keccak256 to convert this entries to an aleatory hash and then into an
        uint then we use % 1000 to turn it into a random 4 digits number between 0 - 9999
        */
        for(uint i = 0; i < _tickets; i++) {
            uint random = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 10000;
            randNonce++;
            // Store the tickets 
            buyer_tickets[msg.sender].push(random);

            // purchased tickets
            purchasedTickets.push(random);

            // DNA ticket
            tickets_to_addr[random] = msg.sender;

            // Emit event
            emit purchased_ticket(random, msg.sender);
        }
    }

    // View purchased tickets
    function ShowPurchasedTickets() public view returns (uint [] memory) {
        return buyer_tickets[msg.sender];
    }

    //Chose winner function
    function ChooseWinner() public JustOwner(msg.sender) {
        uint lengthh = purchasedTickets.length;
        
        // Check if there are purchased tickets
        require(lengthh > 0, "There are no tickets for the lottery!!!");

        // 1 - Pick a random position in the array
        uint arrayPos = uint(uint(keccak256(abi.encodePacked(now))) % lengthh);

        // 2 - Pick the ticket  through the random array position
        uint winnerTicket = purchasedTickets[arrayPos];

        // Emit winner event
        emit winner_ticket(winnerTicket);

        // Get the winner addr
        address winnerAddr = tickets_to_addr[winnerTicket];

        // Send tokens to winner
        token.transferLottery(msg.sender, winnerAddr, Prize());
    }

    // --------------------------- LOTTERY END-----------------------------------//
}