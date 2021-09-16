// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.4 <0.7.0;

contract charity {
    
    struct Cause {
        uint Id;
        string name;
        uint target;
        uint collected;
    }
    
    uint causesCounter = 0;
    
    mapping(string => Cause) causes;
    
    //create a new charity cause
    function newCause(string memory _name, uint target) public payable{
        causesCounter = causesCounter++;
        
        causes[_name] = Cause(causesCounter, _name, target, 0);
    }
    
    //check if the case reached it target
    function targetReached(string memory _name, uint _amount) private view returns (bool){
        bool flag = false;
        Cause memory cause = causes[_name];
        
        if(cause.target >= (cause.collected+_amount)) {
            flag = true;
        }
        return flag;
    }
    
    //give to a cause
    function give(string memory _name, uint _amount) public returns (bool) {
        bool accept = true;
        
        if(targetReached(_name, _amount)) {
            causes[_name].collected = causes[_name].collected + _amount;
        }
        else {
            accept = false;
        }
        
        return accept;
    }
    
    //check cause collected
    
    function check_cause(string memory _name) public view returns(bool, uint){
        
        bool targetReach = false;
        Cause memory cause = causes[_name];
        if(cause.collected >= cause.target) {
            targetReach = true;
        }
        
        return (targetReach, causes[_name].collected);
    }
}
