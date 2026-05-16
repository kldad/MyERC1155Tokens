// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import "./IERC6093.sol";
import "./AccessControl.sol";
import "./PermitExtension.sol";
import "./ERC2771Context.sol";

contract MyERC1155Tokens is IERC6093, AccessControl, PermitExtension, ERC2771Context {

    uint256 public tokenType1TotalSupply;
    uint256 public tokenType2TotalSupply;
    uint256 public tokenType3TotalSupply;

    mapping (address owner => mapping (uint256 id => uint256 value)) public override balanceOf;
    mapping (address owner => mapping (address operator => bool approved)) public override isApprovedForAll;

    constructor(address trustedForwarder_) ERC2771Context(trustedForwarder_) {
        tokenType1Mint(1000);
        tokenType2Mint(5000);
        tokenType3Mint(10000);
    }

    function isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function tokenType1Mint(uint256 value) public onlyAdmin {
        balanceOf[msg.sender][0] += value;
        tokenType1TotalSupply += value;
        emit TransferSingle(msg.sender, address(0), msg.sender, 0, value);
    }

    function tokenType2Mint(uint256 value) public onlyAdmin {
        balanceOf[msg.sender][1] += value;
        tokenType2TotalSupply += value;
        emit TransferSingle(msg.sender, address(0), msg.sender, 1, value);
    }

    function tokenType3Mint(uint256 value) public onlyAdmin {
        balanceOf[msg.sender][2] += value;
        tokenType3TotalSupply += value;
        emit TransferSingle(msg.sender, address(0), msg.sender, 2, value);
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory) {
        uint256[] memory values = new uint256[](owners.length * ids.length);
        uint256 k;

        for(uint256 i = 0; i < owners.length; i++)
            for(uint256 j = 0; j < ids.length; j++)
                values[k++] = balanceOf[owners[i]][ids[j]];

        return values;
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external notBlackListed {
        if(from == address(0))
            revert ERC1155InvalidSender(from);

        if(to == address(0) || to == from || isContract(to)) /* С целью упрощения - запрещаем, помимо прочего, передавать токены контрактам */
            revert ERC1155InvalidReceiver(to);

        address msgSender = msgSender();

        if(from != msgSender && ! isApprovedForAll[from][msgSender])
            revert ERC1155MissingApprovalForAll(msgSender, from);

        uint256 balance = balanceOf[from][id];
        if(balance < value)
            revert ERC1155InsufficientBalance(from, balance, value, id);

        unchecked {
            balanceOf[from][id] -= value;
        }
        balanceOf[to][id] += value;

        emit TransferSingle(msgSender, from, to, id, value);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external notBlackListed {
        if(from == address(0))
            revert ERC1155InvalidSender(from);

        if(to == address(0) || to == from || isContract(to)) /* С целью упрощения - запрещаем, помимо прочего, передавать токены контрактам */
            revert ERC1155InvalidReceiver(to);

        address msgSender = msgSender();

        if(from != msgSender && ! isApprovedForAll[from][msgSender])
            revert ERC1155MissingApprovalForAll(msgSender, from);

        if(ids.length != values.length)
            revert ERC1155InvalidArrayLength(ids.length, values.length);

        for(uint256 i = 0; i < ids.length; i++) {
            uint256 balance = balanceOf[from][ids[i]];
            if(balance < values[i])
                revert ERC1155InsufficientBalance(from, balance, values[i], ids[i]);
        }

        for(uint256 i = 0; i < ids.length; i++) {
            unchecked {
                balanceOf[from][ids[i]] -= values[i];
            }
            balanceOf[to][ids[i]] += values[i];
        }

        emit TransferBatch(msgSender, from, to, ids, values);
    }

    function setApprovalForAll(address operator, bool approved) external notBlackListed {
        setApprovalForAll_(msgSender(), operator, approved);
    }
    function setApprovalForAll_(address owner, address operator, bool approved) private {
        if(owner == address(0))
            revert ERC1155InvalidApprover(owner);

        if(operator == address(0) || operator == owner)
            revert ERC1155InvalidOperator(operator);

        isApprovedForAll[owner][operator] = approved;

        emit ApprovalForAll(owner, operator, approved);
    }

    function blackListedAction(address user) public override {
        uint256[] memory ids = new uint256[](3);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;

        uint256[] memory values = new uint256[](3);
        values[0] = balanceOf[user][0];
        values[1] = balanceOf[user][1];
        values[2] = balanceOf[user][2];

        balanceOf[user][0] = 0;
        balanceOf[user][1] = 0;
        balanceOf[user][2] = 0;

        unchecked {
            tokenType1TotalSupply -= values[0];
            tokenType2TotalSupply -= values[1];
            tokenType3TotalSupply -= values[2];
        }    

        emit TransferBatch(msg.sender, user, address(0), ids, values);
   }

    function setApprovalForAllByPermit(address owner, address operator, bool approved) public override {
        setApprovalForAll_(owner, operator, approved);
    }
}