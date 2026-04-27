// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import "./IERC6093.sol";

contract MyERC1155Tokens is IERC6093 {

    address public owner;

    uint256 public tokenType1TotalSupply;
    uint256 public tokenType2TotalSupply;
    uint256 public tokenType3TotalSupply;

    mapping (address owner => mapping (uint256 id => uint256 value)) public override balanceOf;
    mapping (address owner => mapping (address operator => bool approved)) public override isApprovedForAll;

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;

        tokenType1Mint(1000);
        tokenType2Mint(5000);
        tokenType3Mint(10000);
    }

    function transferOwnership(address owner_) public onlyOwner {
        owner = owner_;
    }    

    function isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function tokenType1Mint(uint256 value) public onlyOwner {
        balanceOf[msg.sender][0] += value;
        tokenType1TotalSupply += value;
        emit TransferSingle(msg.sender, address(0), msg.sender, 0, value);
    }

    function tokenType2Mint(uint256 value) public onlyOwner {
        balanceOf[msg.sender][1] += value;
        tokenType2TotalSupply += value;
        emit TransferSingle(msg.sender, address(0), msg.sender, 1, value);
    }

    function tokenType3Mint(uint256 value) public onlyOwner {
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

    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external {
        if(from == address(0))
            revert ERC1155InvalidSender(from);

        if(to == address(0) || to == from || isContract(to)) /* С целью упрощения - запрещаем, помимо прочего, передавать токены контрактам */
            revert ERC1155InvalidReceiver(to);

        if(from != msg.sender && ! isApprovedForAll[from][msg.sender])
            revert ERC1155MissingApprovalForAll(msg.sender, from);

        uint256 balance = balanceOf[from][id];
        if(balance < value)
            revert ERC1155InsufficientBalance(from, balance, value, id);

        unchecked {
            balanceOf[from][id] -= value;
        }
        balanceOf[to][id] += value;

        emit TransferSingle(msg.sender, from, to, id, value);
    }

    function setApprovalForAll(address operator, bool approved) external {
        if(msg.sender == address(0))
            revert ERC1155InvalidApprover(msg.sender);

        if(operator == address(0) || operator == msg.sender)
            revert ERC1155InvalidOperator(operator);

        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }    
}