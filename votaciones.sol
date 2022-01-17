// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 < 0.7.0;
pragma experimental ABIEncoderV2;

// -------------------------------
//  CANDIDATE  |  AGE  |  ID
// -------------------------------
//  ANA       |  29   | 12345X 
//  Toni      |  25   | 43445J 
//  Marie     |  24   | 43245K 
//  Albert    |  31   | 13345H 

contract vote {
    
    // Address of the contract owner
    address public owner;
    
    // constructor
    constructor () public {
        owner = msg.sender;
    }
    
    // linking the candidate's name with the hash of their personal data
    mapping (string => bytes32) ID_Candidate;
    
    // linking candidates and their votes
    mapping (string => uint) candidate_votes;
    
    // List to save the names of candidates
    string [] candidates;
    
    // Voters list hash from voter address -- To check if this person already voted
    bytes32 [] voters;
    
    //Function to add candidates
    function Represent(string memory _name, uint _age, string memory _id) public {
        
        // candidates hash
        bytes32 candidate_hash = keccak256(abi.encodePacked(_name, _age, _id));
        
        // adding to ID_Candidate array
        ID_Candidate[_name] = candidate_hash;
        
        // adding to candidate_votes array
        candidate_votes[_name] = 0;
        
        // adding to candidates array
        candidates.push(_name);
    }
    
    //show registered candidates
    function showCandidates() public view returns(string[] memory) {
        
        // return candidates array
        return candidates;
    }

    function toVote(string memory _candidate) public {
        //Hash of voters address
        bytes32 voter_hash = keccak256(abi.encodePacked(msg.sender));

        //Check if this person already voted
        for(uint i = 0; i < voters.length; i++) {
            require(voters[i] != voter_hash, "Already voted!!!");
        }

        //Adding this person hashed address to the list of persons who voted
        voters.push(voter_hash);

        //Adding the vote to the selected candidate
        candidate_votes[_candidate]++;
    }

    //This function returns some specific candidate votes quantity
    function showCandidateVotes(string memory _candidate) public view returns(uint){
        //Returns a candidate votes
        return candidate_votes[_candidate];
    }

    //Auxiliary function to transform a uint to string
    function uint2string(uint _i) internal pure returns(string memory _uintAsString){
        if (_i == 0) {
            return "0";
        }

        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint k = len -1;

        while(_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }

        return string(bstr);
    }

    //Check voting results
    function viewResults() public view returns(string memory){
        //A variable to store every candidate with its votesb
        string memory results;

        //Go over all the candidates list names to add them to the result variable
        for(uint i = 0; i < candidates.length; i++) {
            //Update the results variable with the candidate name in the i position and the numbers of votes
            results = string(abi.encodePacked(results, "(", candidates[i], ", ", uint2string(showCandidateVotes(candidates[i])), ") --"));
        }

        //return results
        return results;
    }

    //Return thw winner candidate
    function Winner() public view returns (string memory) {
        //Store the winner candidate
        string memory winner = candidates[0];

        // Variable to handle if there is a tie
        bool flag;

        // Check every candidate to pull the winner
        for(uint i = 1; i < candidates.length; i++) {

            //Check if the current content in the winner is the winner against the candidates  
            if(showCandidateVotes(candidates[i]) > showCandidateVotes(winner)) {
                winner = candidates[i];
                flag = false;
            }
            else if(showCandidateVotes(candidates[i]) == showCandidateVotes(winner)) {
                flag = true;
            }
        }

        //In case there is a tie shws this text instead the name of a candidate
        if(flag == true) {
            winner = "There is a tie";
        }

        //Returns the winner name
        return winner;
    }
}
