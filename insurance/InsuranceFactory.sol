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

    modifier OnlyClientOrInsurance(address _clientAddress, address _requestingAddress) {
        require((MappingClients[_clientAddress].ClientAuthorization == true && _clientAddress == _requestingAddress) || (InsuranceCompany == _requestingAddress), "Only client or insurance company are authorized");
        _;
    }

    // Events
    event PurchasedEvent(uint256);
    event ServicedProvidedEvent(address, string, uint256);
    event LabCreatedEvent(address, address);
    event NewClientEvent(address, address);
    event UnsubscribeClientEvent(address);
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
    
    function ShowClientHistory(address _clientAddress, address _requestingAddress) public view OnlyClientOrInsurance(_clientAddress, _requestingAddress) returns (string memory) {
        string memory history = "";
        address clientContractAddress = MappingClients[_clientAddress].ClientContract;

        for(uint i = 0; i < ServicesNames.length; i++) {
            if(MappingServices[ServicesNames[i]].ServiceStatus 
                && InsuranceHealthRecord(clientContractAddress).ClientServiceStatus(ServicesNames[i]) == true) {
                (string memory serviceName, uint servicePrice) = InsuranceHealthRecord(clientContractAddress).ClientHistory(ServicesNames[i]);

                history = string(abi.encodePacked(history, "(", serviceName, ", ", uint2str(servicePrice), ") ------ "));
            }
        }

        return history;
    }

    function UnsubscribeClient(address _clientAddress) public OnlyInsurance(msg.sender) {
        MappingClients[_clientAddress].ClientAuthorization = false;
        InsuranceHealthRecord(MappingClients[_clientAddress].ClientContract).Unsubscribe;
        emit UnsubscribeClientEvent(_clientAddress);
    }

    function NewService(string memory _serviceName, uint _servicePrice) public OnlyInsurance(msg.sender) {
        MappingServices[_serviceName] = service(_serviceName, _servicePrice, true);
        ServicesNames.push(_serviceName);
        ServiceCreatedEvent(_serviceName, _servicePrice);
    }

    function RemoveService(string memory _serviceName) public OnlyInsurance(msg.sender) {
        require(GetServiceStatus(_serviceName) == true, "Service not available");
        MappingServices[_serviceName].ServiceStatus = false;
        emit RemoveServiceEvent(_serviceName);
    }

    function GetServiceStatus(string memory _serviceName) public view returns (bool) {
        return MappingServices[_serviceName].ServiceStatus;
    }

    function GetServicePrice(string memory _serviceName) public view returns (uint tokens) {
        require(GetServiceStatus(_serviceName) == true, "Service not available");
        return MappingServices[_serviceName].ServiceTokenPrice;
    }

    //Function to show only active services
    function ShowActiveServices() public view returns(string [] memory) {
        string [] memory ActiveServices = new string[](ServicesNames.length);
        uint counter = 0;

        for(uint i = 0; i < ServicesNames.length; i++) {
            if(GetServiceStatus(ServicesNames[i]) == true) {
                ActiveServices[counter] = ServicesNames[i];
                counter++;
            }
        }

        return ActiveServices;
    }

    function BuyTokens(address _client, uint _numTokens) public payable OnlyInsured(_client) {
        uint256 balance = BalanceOf();
        require(_numTokens > 0, "Buy a positive amount of tokens");
        require(_numTokens <= balance, "Buy less tokens");

        token.transfer(msg.sender, _numTokens);
        emit PurchasedEvent(_numTokens);
    }

    function BalanceOf() public view returns(uint256 tokens) {
        return (token.balanceOf(address(this)));
    }

    function GenerateTokens(uint _numTokens) public OnlyInsurance(msg.sender) {
        token.increaseTotalSupply(_numTokens);
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

    struct RequestedServices {
        string serviceName;
        uint servicePrice;
        bool serviceStatus;
    }

    struct RequestedServicesLab {
        string serviceName;
        uint servicePrice;
        address labAddress;
    }

    mapping (string => RequestedServices) clientHistory;
    RequestedServicesLab [] RequestedServicesLabHistory;

    modifier OnlyOwner(address _address) {
        require(_address == owner.ownerAddress, "You're not the owner");
        _;
    }

    event selfDestructEvent(address);
    event returnTokensEvent(address, uint);
    event paidServiceEvent(address, string, uint256);
    event serviceRequestLab(address, address, string);

    function HistoryRequestedServicesLab() public view returns (RequestedServicesLab [] memory) {
        return RequestedServicesLabHistory;
    }

    function ClientHistory(string memory _serviceName) public view returns (string memory nombreServicio, uint servicePrice) {
        return (clientHistory[_serviceName].serviceName, clientHistory[_serviceName].servicePrice);
    }

    function ClientServiceStatus(string memory _serviceName) public view returns (bool) {
        return clientHistory[_serviceName].serviceStatus;
    }

    function Unsubscribe() public OnlyOwner(msg.sender) {
        emit selfDestructEvent(msg.sender);
        selfdestruct(msg.sender);
    }

    function BuyTokens(uint _numTokens) payable public OnlyOwner(msg.sender) {
        require(_numTokens > 0, "Please buy a positive number of tokens");
        uint cost = CalculateTokenPrice(_numTokens);
        require(msg.value >= cost, "Buy less tokens or send more eth");
        uint returnValue = msg.value - cost;
        msg.sender.transfer(returnValue);
        InsuranceFactory(owner.insurance).BuyTokens(msg.sender, _numTokens);
    }

    function BalanceOf() public view OnlyOwner(msg.sender) returns (uint256 _balance) {
        return (owner.tokens.balanceOf(address(this)));
    }

    function ReturnTokens(uint _numTokens) public payable OnlyOwner(msg.sender) {
        require(_numTokens > 0, "Please send a positive number of tokens");
        require(_numTokens <= BalanceOf(), "You don't have that amout of tokens");
        owner.tokens.transfer(owner.insurance, _numTokens);
        msg.sender.transfer(CalculateTokenPrice(_numTokens));
        emit returnTokensEvent(msg.sender, _numTokens);
    }

    function RequestService(string memory _serviceName) public OnlyOwner(msg.sender) {
        require(InsuranceFactory(owner.insurance).GetServiceStatus(_serviceName) == true, "Service not available");
        uint servicePrice = InsuranceFactory(owner.insurance).GetServicePrice(_serviceName);
        require(BalanceOf() >= servicePrice, "You don't have enough tokens, please buy more");
        owner.tokens.transfer(owner.insurance, servicePrice);
        clientHistory[_serviceName] = RequestedServices(_serviceName,servicePrice,true);
        paidServiceEvent(msg.sender, _serviceName, servicePrice);
    }

    function RequestLabService(address _labAddress, string memory _serviceName) public payable OnlyOwner(msg.sender) {
        Lab labContract = Lab(_labAddress);
        require(msg.value == labContract.GetServicePrice(_serviceName) * 1 ether, "Operacion invalida");
        labContract.GiveService(msg.sender, _serviceName);
        payable(labContract.labAddress()).transfer(labContract.GetServicePrice(_serviceName) * 1 ether);
        RequestedServicesLabHistory.push(RequestedServicesLab(_serviceName, labContract.GetServicePrice(_serviceName), _labAddress));
        emit serviceRequestLab(_labAddress, msg.sender, _serviceName);
    }
}

contract Lab {

    address public labAddress;
    address insurance;
    constructor (address _senderAddress, address _insurance) public {
        labAddress = labAddress;
        insurance = _insurance;
    }

    function GetServicePrice(string memory _serviceName) public view returns (uint) {
        return 0;
    }

    function GiveService(address _clientAddress, string memory _serviceName) public {

    }
}