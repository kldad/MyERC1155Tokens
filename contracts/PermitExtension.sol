// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import "./AccessControl.sol";

contract PermitExtension is AccessControl {
    string public name;

    bytes32 private constant EIP_712_DOMAIN_TYPE_HASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 private constant PERMIT_TYPE_HASH = keccak256(
        "Permit(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)"
    );

    mapping(address owner => uint256 nonce) public nonces;
    bytes32 public DOMAIN_SEPARATOR;

    function __PermitExtension_init() internal {
        name = "ThreeTokens";
        DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    function _computeDomainSeparator() private view returns (bytes32) {
        return keccak256(
            abi.encode(
                EIP_712_DOMAIN_TYPE_HASH,
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function permit(
        address owner,
        address operator,
        bool approved, 
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external notBlackListed {
        require(deadline >= block.timestamp, "Deadline exceeded");
        require(owner != address(0) && !isBlackListed(owner), "Invalid owner");         
        require(operator != address(0) && operator != owner && !isBlackListed(operator), "Invalid operator");         

        bytes32 hash = keccak256(
            abi.encodePacked(
                hex"1901",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPE_HASH,
                        owner,
                        operator,
                        approved,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );

        address signer = ecrecover(hash, v, r, s);
        require(signer == owner, "denied");

        setApprovalForAllByPermit(owner, operator, approved);
    }
    
    function setApprovalForAllByPermit(address owner, address operator, bool approved) internal virtual {}
}
