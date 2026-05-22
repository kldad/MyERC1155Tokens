// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

contract ERC2771Context {
    address private _trustedForwarder;

    function __ERC2771Context_init(address trustedForwarder_) internal {
        _trustedForwarder = trustedForwarder_;
    }

    function trustedForwarder() public view returns (address) {
        return _trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) external view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    function msgSender() internal view returns(address) {
        if(msg.sender == _trustedForwarder) {
            address sender;

            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }

            return sender;
        }

        return msg.sender;
    }
}
