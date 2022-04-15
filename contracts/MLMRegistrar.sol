// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IMLMRegistrar {
    function downlineCount(address) external view returns (uint256);
    function getUplines(address) external view returns (address, address, address, address, address);
    function register(address) external;
    function registered(address) external view returns (bool);
    function remove() external;
    function replace(address) external;
    function uplineForUser(address) external view returns (address);
}

contract MLMRegistrar {

    using SafeMath for uint256;

    mapping(address => address) public uplineForUser;
    mapping(address => uint256) public downlineCount;
    mapping(address => bool) public registered;

    event Registered(address user, address upline);
    event Removed(address user, address upline);
    event Replaced(address user, address upline);

    constructor() {}

    function register(address upline) public {
        address user = msg.sender;
        require(registered[user] == false, "User must be unregistered");

        uplineForUser[user] = upline;
        registered[user] = true;
        downlineCount[upline] = downlineCount[upline].add(1);

        emit Registered(user, upline);
    }

    function remove() public {
        address user = msg.sender;
        address upline = uplineForUser[user];
        require(registered[user] == true, "User must be registered");     

        registered[user] = false;
        uplineForUser[user] = address(0);
        downlineCount[upline] = downlineCount[upline].sub(1);   
        emit Removed(user, upline);        
    }

    function replace(address newUpline) public {
        address user = msg.sender;
        address upline = uplineForUser[user];
        require(registered[user] == true, "User must be registered");     

        downlineCount[upline] = downlineCount[upline].sub(1);         

        uplineForUser[user] = newUpline;
        downlineCount[newUpline] = downlineCount[upline].add(1);    
        emit Replaced(user, newUpline);
    }

    function getUplines(address user) public view returns(address u1, address u2, address u3, address u4, address u5) {        
        for (uint i = 0; i < 5; i++) {
            if (i == 0) {
                u1 = uplineForUser[user];
            }            
            if (i == 1) {
                u2 = uplineForUser[u1];
            }
            if (i == 2) {
                u3 = uplineForUser[u2];
            }            
            if (i == 3) {
                u4 = uplineForUser[u3];
            }
            if (i == 4) {
                u5 = uplineForUser[u4];
            }
        }
        
    }
}

