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
    mapping (address => bool) health_center_validity;

    // 1: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 -> True = Have rights to create its own smart contract
    // 2: 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db -> False = Don't have rights to create its own smart contract

    // Array to store valid health centers smart contract address
    address [] public healthCentersAddress;

    // Events
    event NewHealthCenterValidated (address);
    event NewContract (address, address);

    // Modifier to allow only OMS to execute som functions
    modifier JustOwner(address _addr) {
        require (_addr == OMS, "Don't have enough permission to do this!!!");
        _;
    }
    
    // Function to validate new health centers
    function ValidateHealthCenter(address _healthCenter) public JustOwner(msg.sender) {
        // Validate the address of the health center
        health_center_validity[_healthCenter] = true;

        // Emit validity event
        emit NewHealthCenterValidated(_healthCenter);
    }

    // Function to create a smart contract for a health center
    function HealthCenterFactory() public {
        // Check for validated health centers
        require(health_center_validity[msg.sender] == true, "You are not allowed to do this");

        // Generate a new smart contract -> generate its address
        address health_center_contract = address (new HealthCenter(msg.sender));

        // Store new smart contract address in the arrau
        healthCentersAddress.push(msg.sender); 

        // Emit new contract event
        emit NewContract(health_center_contract, msg.sender);
        
    }


}

// Health Center Smart Contract
contract HealthCenter {
    address public healthCenterAddress;
    address public contractAddress;

    constructor (address _address) public {
        healthCenterAddress = _address;
        contractAddress = address(this);
    }
}