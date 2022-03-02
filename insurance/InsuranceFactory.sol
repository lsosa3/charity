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
    mapping(address => client) public MappingCustomers;
    // Mappings service name to service struct
    mapping(string => service) public MappingServices;
    // Mapping address to lab
    mapping(address => lab) public MappingLab;


    // Array to store customers
    address [] Customers;
    // Array to store service names
    string [] private ServicesNames;
    // Arry to store labs address
    address [] LabsAddress;
 
}