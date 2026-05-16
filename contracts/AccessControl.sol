// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

contract AccessControl {
    address private immutable owner;
    mapping (address user => bool isAdmin) private admins;
    mapping (address user => bool isModerator) private moderators;
    mapping (address user => bool isBlackListed) private blackList;

    error AccessControlInvalidUser(address sender, address user);
    error AccessControlRoleAssignmentUnavailableForContractOwner(address sender, address user);
    error AccessControlRoleAssignmentUnavailableForBlackListed(address sender, address user);

    event AccessControlAdminRoleAssigned(address indexed sender, address indexed user);
    event AccessControlModeratorRoleAssigned(address indexed sender, address indexed user);
    event AccessControlUserBlackListed(address indexed sender, address indexed user);

    event AccessControlAdminRoleRemoved(address indexed sender, address indexed user);
    event AccessControlModeratorRoleRemoved(address indexed sender, address indexed user);
    event AccessControlUserRemovedFromBlackList(address indexed sender, address indexed user);

    modifier onlyOwner {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }
    modifier onlyAdmin {
        require(msg.sender == owner || admins[msg.sender], "Only admin can call this function");
        _;
    }
    modifier onlyModerator {
        require(msg.sender == owner || admins[msg.sender] || moderators[msg.sender], "Only moderator can call this function");
        _;
    }
    modifier notBlackListed {
        require(!blackList[msg.sender], "Access denied");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function isOwner(address user) public view returns (bool) {
        return user == owner;
    }
    function isAdmin(address user) public view returns (bool) {
        return user == owner || admins[user];
    }
    function isModerator(address user) public view returns (bool) {
        return user == owner || admins[user] || moderators[user];
    }
    function isBlackListed(address user) public view returns (bool) {
        return blackList[user];
    }

    function addAdmin(address user) public onlyOwner {
        if(user == address(0) || user == msg.sender || admins[user]) 
            revert AccessControlInvalidUser(msg.sender, user);

        if(blackList[user])
            revert AccessControlRoleAssignmentUnavailableForBlackListed(msg.sender, user);

        moderators[user] = false;
        admins[user] = true;

        emit AccessControlAdminRoleAssigned(msg.sender, user);
    }
    function removeAdmin(address user) public onlyOwner {
        if(!admins[user]) 
            revert AccessControlInvalidUser(msg.sender, user);

        admins[user] = false;

        emit AccessControlAdminRoleRemoved(msg.sender, user);
    }

    function addModerator(address user) public onlyAdmin {
        if(user == address(0) || user == msg.sender || moderators[user]) 
            revert AccessControlInvalidUser(msg.sender, user);

        if(user == owner) 
            revert AccessControlRoleAssignmentUnavailableForContractOwner(msg.sender, user);

        if(blackList[user])
            revert AccessControlRoleAssignmentUnavailableForBlackListed(msg.sender, user);

        admins[user] = false;
        moderators[user] = true;

        emit AccessControlModeratorRoleAssigned(msg.sender, user);
    }
    function removeModerator(address user) public onlyAdmin {
        if(!moderators[user]) 
            revert AccessControlInvalidUser(msg.sender, user);

        moderators[user] = false;

        emit AccessControlModeratorRoleRemoved(msg.sender, user);
    }

    function addToBlackList(address user) public onlyModerator {
        if(user == address(0) || user == msg.sender || blackList[user]) 
            revert AccessControlInvalidUser(msg.sender, user);

        if(user == owner) 
            revert AccessControlRoleAssignmentUnavailableForContractOwner(msg.sender, user);

        admins[user] = false;
        moderators[user] = false;

        blackListedAction(user);

        blackList[user] = true;

        emit AccessControlUserBlackListed(msg.sender, user);
    }

    function blackListedAction(address user) public virtual {}
}    