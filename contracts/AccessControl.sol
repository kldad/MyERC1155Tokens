// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import "./ERC2771Context.sol";

contract AccessControl is ERC2771Context {
    address private _owner;
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
//    event AccessControlUserRemovedFromBlackList(address indexed sender, address indexed user);

    modifier onlyOwner {
        require(msgSender() == _owner, "Only contract owner can call this function");
        _;
    }
    modifier onlyAdmin {
        address msgSender = msgSender();
        require(msgSender == _owner || admins[msgSender], "Only admin can call this function");
        _;
    }
    modifier onlyModerator {
        address msgSender = msgSender();
        require(msgSender == _owner || admins[msgSender] || moderators[msgSender], "Only moderator can call this function");
        _;
    }
    modifier notBlackListed {
        require(!blackList[msgSender()], "Access denied");
        _;
    }

    function __AccessControl_init(address initialOwner) internal {
        _owner = initialOwner;
    }

    function isOwner(address user) public view returns (bool) {
        return user == _owner;
    }
    function isAdmin(address user) public view returns (bool) {
        return user == _owner || admins[user];
    }
    function isModerator(address user) public view returns (bool) {
        return user == _owner || admins[user] || moderators[user];
    }
    function isBlackListed(address user) public view returns (bool) {
        return blackList[user];
    }

    function addAdmin(address user) public onlyOwner {
        address msgSender = msgSender();

        if(user == address(0) || user == msgSender || admins[user]) 
            revert AccessControlInvalidUser(msgSender, user);

        if(blackList[user])
            revert AccessControlRoleAssignmentUnavailableForBlackListed(msgSender, user);

        moderators[user] = false;
        admins[user] = true;

        emit AccessControlAdminRoleAssigned(msgSender, user);
    }
    function removeAdmin(address user) public onlyOwner {
        address msgSender = msgSender();

        if(!admins[user]) 
            revert AccessControlInvalidUser(msgSender, user);

        admins[user] = false;

        emit AccessControlAdminRoleRemoved(msgSender, user);
    }

    function addModerator(address user) public onlyAdmin {
        address msgSender = msgSender();

        if(user == address(0) || user == msgSender || moderators[user]) 
            revert AccessControlInvalidUser(msgSender, user);

        if(user == _owner) 
            revert AccessControlRoleAssignmentUnavailableForContractOwner(msgSender, user);

        if(blackList[user])
            revert AccessControlRoleAssignmentUnavailableForBlackListed(msgSender, user);

        admins[user] = false;
        moderators[user] = true;

        emit AccessControlModeratorRoleAssigned(msgSender, user);
    }
    function removeModerator(address user) public onlyAdmin {
        address msgSender = msgSender();

        if(!moderators[user]) 
            revert AccessControlInvalidUser(msgSender, user);

        moderators[user] = false;

        emit AccessControlModeratorRoleRemoved(msgSender, user);
    }

    function addToBlackList(address user) public onlyModerator {
        address msgSender = msgSender();

        if(user == address(0) || user == msgSender || blackList[user]) 
            revert AccessControlInvalidUser(msgSender, user);

        if(user == _owner) 
            revert AccessControlRoleAssignmentUnavailableForContractOwner(msgSender, user);

        admins[user] = false;
        moderators[user] = false;

        blackListedAction(user);

        blackList[user] = true;

        emit AccessControlUserBlackListed(msgSender, user);
    }

    function blackListedAction(address user) public virtual {}
}
