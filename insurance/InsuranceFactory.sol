// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 < 0.7.0;
pragma experimental ABIEncoderV2;
import "./BasicOperations.sol";
import "./ERC20.sol";

// Insurance company smart contract
contract InsuranceFactory is BasicOperations {
    
    constructor () public {
        token = new ERC20Basic(100);
        Insurance = address(this);
        InsuranceCompany = msg.sender;
    }

    struct client {
        address ClientAddress;
        bool ClientAuthorization;
        address ClientContract;
    }

    struct service {
        string ServiceName;
        uint ServiceTokenPrice;
        bool ServiceStatus;
    }

    struct lab {
        address LabContractAddress;
        bool LabValidation;

    }
    // Contract instance
    ERC20Basic private token;

    // Addresses 
    address Insurance;
    address payable public InsuranceCompany;

    // Mappings and arrays

    // Mappings address to client struct
    mapping(address => client) public MappingClients;
    // Mappings service name to service struct
    mapping(string => service) public MappingServices;
    // Mapping address to lab
    mapping(address => lab) public MappingLab;


    // Array to store clients address
    address [] Clients;
    // Array to store service names
    string [] private ServicesNames;
    // Arry to store labs address
    address [] LabsAddress;

    function CheckOnlyClient(address _insuredAddress) public view {
        require(MappingClients[_insuredAddress].ClientAuthorization == true, "Client not authorized, please check");
    }
    // Modifiers to apply restrictions on insured and insurance
    modifier OnlyInsured(address _insuredAddress) {
        CheckOnlyClient(_insuredAddress);
        _;
    }

    modifier OnlyInsurance(address _insuranceAddress) {
        require(InsuranceCompany == _insuranceAddress, "You are not authorized to do this!");
        _;
    }

    modifier ClientOrInsurance(address _clientAddress, address _inCommingAddress) {
        require((MappingClients[_clientAddress].ClientAuthorization == true && _clientAddress == _inCommingAddress) || (InsuranceCompany == _inCommingAddress), "Only client or insurance company are authorized");
        _;
    }

    // Events
    event PurchasedEvent(uint256);
    event ServicedProvidedEvent(address, string, uint256);
    event LabCreatedEvent(address, address);
    event NewClientEvent(address, address);
    event RemoveClientEvent(address);
    event ServiceCreatedEvent(string, uint256);
    event RemoveServiceEvent(string);


    function CreateLab() public {
        LabsAddress.push(msg.sender);
        address labAddress = address(new Lab(msg.sender, Insurance));
        MappingLab[msg.sender] = lab(labAddress, true);
        emit LabCreatedEvent(msg.sender, labAddress);
    }

    function CreateClientContract() public {
        Clients.push(msg.sender);
        address clientAddress = address(new InsuranceHealthRecord(msg.sender, token, Insurance, InsuranceCompany));
        MappingClients[msg.sender] = client(msg.sender, true, clientAddress);
        emit NewClientEvent(msg.sender, clientAddress);
    }

    function showLabs() public view OnlyInsurance(msg.sender) returns (address [] memory) {
        return LabsAddress;
    }

    function showClients() public view OnlyInsurance(msg.sender) returns (address [] memory) {
        return Clients;
    }
}

contract InsuranceHealthRecord is BasicOperations {

    enum State { available, notAvailable }

    struct Owner {
        address ownerAddress;
        uint balance;
        State state;
        IERC20 tokens;
        address insurance;
        address payable insuranceCompany;
    }

    Owner owner;

    constructor (address _owner, IERC20 _token, address _insurance, address payable _insuranceCompany) public {
        owner.ownerAddress = _owner;
        owner.balance = 0;
        owner.state = State.available;
        owner.tokens = _token;
        owner.insurance = _insurance;
        owner.insuranceCompany = _insuranceCompany;
    }
}

contract Lab {

    address public labAddress;
    address insurance;
    constructor (address _senderAddress, address _insurance) public {
        labAddress = labAddress;
        insurance = _insurance;
    }
}