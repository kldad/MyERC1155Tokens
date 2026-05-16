// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

contract ERC2771TrustedForwarder {
    string internal name;

    struct MetaTransaction {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
        uint256 deadline;
    }

    bytes32 private constant EIP_712_DOMAIN_TYPE_HASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 private constant META_TRANSACTION_TYPE_HASH = keccak256(
        "MetaTransaction(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data,uint256 deadline)"
    );

    mapping(address owner => uint256 nonce) public nonces;
    bytes32 public immutable DOMAIN_SEPARATOR;

    constructor() {
        name = "ERC2771TrustedForwarder";

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP_712_DOMAIN_TYPE_HASH,
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function execute( 
        MetaTransaction calldata metaTx,
        bytes calldata signature
    ) external payable returns(bytes memory) {
        require(metaTx.deadline >= block.timestamp, "Deadline exceeded");
        require(metaTx.nonce == nonces[metaTx.from], "Invalid nonce");

        bytes32 hash = keccak256(
            abi.encodePacked(
                hex"1901",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        META_TRANSACTION_TYPE_HASH,
                        metaTx.from,
                        metaTx.to,
                        metaTx.value,
                        metaTx.gas,
                        metaTx.nonce,
                        keccak256(metaTx.data),
                        metaTx.deadline
                    )
                )
            )
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            let sigOffset := mload(0x40)
            calldatacopy(sigOffset, signature.offset, 96)
            r := mload(sigOffset)
            s := mload(add(sigOffset, 32))
            v := byte(0, mload(add(sigOffset, 64)))            
        }

        address signer = ecrecover(hash, v, r, s);
        require(signer == metaTx.from, "denied");

        nonces[metaTx.from]++;

        bytes memory extendedData = abi.encodePacked(metaTx.data, metaTx.from);

        (bool success, bytes memory data) = metaTx.to.call {
            value: metaTx.value,
            gas: metaTx.gas
        }(extendedData);
        require(success, "Call failed");

        return data;
    }
}