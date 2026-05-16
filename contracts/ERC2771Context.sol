// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

abstract contract ERC2771Context {
    address public immutable trustedForwarder;

    constructor(address trustedForwarder_) {
        trustedForwarder = trustedForwarder_;
    }

    function isTrustedForwarder(address forwarder) external view returns(bool) {
        return forwarder == trustedForwarder;
    }

    function msgSender() internal view returns(address) {
        if(msg.sender == trustedForwarder) {
            address sender;

            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }

            return sender;
        }

        return msg.sender;
    }
}