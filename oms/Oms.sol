// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 < 0.7.0;
pragma experimental ABIEncoderV2;

contract OMS_COVID {

    // OMS address -> contract owner
    address public OMS;

    // Contract constructor
    constructor () public {
        OMS = msg.sender;
    }

    // Mapping to bind health centers (address) to the validity of the management system
    mapping (address => bool) public HealthCenterValidity;

    // 1: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 -> True = Have rights to create its own smart contract
    // 2: 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db -> False = Don't have rights to create its own smart contract

    // Array to store valid health centers smart contract address
    address [] public HealthCentersAddress;

    // Mapping to store Health centers address with its contract address
    mapping (address => address) public HealthCentersAddrContract;

    // Requests from health centers to join the OMS program 
    address [] public Requests;

    // Events
    event NewHealthCenterValidated (address);
    event NewContract (address, address);
    event NewAccessRequest (address);

    // Modifier to allow only OMS to execute som functions
    modifier JustOwner(address _addr) {
        require (_addr == OMS, "Don't have enough permission to do this!!!");
        _;
    }

    // Function for health centers to requests access to the program
    function RequestAccess() public {
        // Store the Health Center address in the requests array 
        Requests.push(msg.sender);

        // Emit new request event
        emit NewAccessRequest(msg.sender);
    }

    // Funtion to shows requests array
    function ShowRequests() public view JustOwner(msg.sender) returns (address [] memory) {
        return Requests;
    }
    
    // Function to validate new health centers
    function ValidateHealthCenter(address _healthCenter) public JustOwner(msg.sender) {
        // Validate the address of the health center
        HealthCenterValidity[_healthCenter] = true;

        // Emit validity event
        emit NewHealthCenterValidated(_healthCenter);
    }

    // Function to create a smart contract for a health center
    function HealthCenterFactory() public {
        // Check for validated health centers
        require(HealthCenterValidity[msg.sender] == true, "You are not allowed to do this");

        // Generate a new smart contract -> generate its address
        address HealthCenterContract = address (new HealthCenter(msg.sender));

        // Store new smart contract address in the arrau
        HealthCentersAddress.push(HealthCenterContract); 

        // Store health center address with its contract address
        HealthCentersAddrContract[msg.sender] = HealthCenterContract;

        // Emit new contract event
        emit NewContract(HealthCenterContract, msg.sender);   
    }
}

// Health Center Smart Contract
contract HealthCenter {
    // Health center address
    address public HealthCenterAddress;

    // Contract address
    address public ContractAddress;

    // Constructor
    constructor (address _address) public {
        HealthCenterAddress = _address;
        ContractAddress = address(this);
    }

    // Mapping to bind a personal ID with COVID test result
    // Commented to handle it with a struct
    //mapping (bytes32 => bool) ResultCovid;

    // Mapping to bind a personal ID with the IPFS code
    // Commented to handle it with a struct
    //mapping (bytes32 => string) ResultCovidIpsf;

    struct CovidResults {
        bool Result;
        string IpfsCode;
    }

    // Mapping to bind a personal ID with the IPFS code and boolean result
    mapping (bytes32 => CovidResults) ResultCovid;

    // Event: new result 
    event NewResult(bool, string);

    // Modifier to allow just the health center execute some functions
    modifier JustHealthCenter(address _address) {
        require(_address == msg.sender, "You don't have permission to do this");
        _;
    }

    // Function to store the COVID test results
    function CovidTestResult(string memory _personId, bool _result, string memory _ipfsCode) public JustHealthCenter(msg.sender) {
        // Hash person's ID
        bytes32 personIdHash = keccak256(abi.encodePacked(_personId));

        // Store the person's hash and boolean test result
        // Commented to handle it with a struct
        //ResultCovid[personId] = _result;

        // Store the person's hash and test result IPFS code
        // Commented to handle it with a struct
        //ResultCovidIpsf[personId] = _ipfsCode;

        // Store the person's hash and test result struct
        ResultCovid[personIdHash] = CovidResults(_result, _ipfsCode);

        //Emit event
        emit NewResult(_result, _ipfsCode);
    }

    // Function to show tests results
    function ShowResults(string memory _personId) public view returns (string memory _TestResult, string memory _IpfsCode){
        // Hash the person Id
        bytes32 personIdHash = keccak256(abi.encodePacked(_personId));

        // String to save the boolean result as a string
        string memory TestResult;

        if(ResultCovid[personIdHash].Result == true) {
            TestResult = "Positive";
        } else {
            TestResult = "Negative";
        } 
        
        //return (TestResult, ResultCovid[personIdHash].IpfsCode);

        _TestResult = TestResult;
        _IpfsCode = ResultCovid[personIdHash].IpfsCode;
    }
}