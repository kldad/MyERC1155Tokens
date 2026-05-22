// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ERC1967} from "./ERC1967.sol";
import {IERC1967} from "./IERC1967.sol";

/// @dev Минимальный ERC-1967 прокси: хранит адрес реализации и делегирует вызовы.
contract ERC1967Proxy {
    constructor(address implementation, bytes memory initData) payable {
        ERC1967.setImplementation(implementation);
        if (initData.length > 0) {
            _delegateCall(implementation, initData);
        }
    }

    fallback() external payable {
        _delegateToImplementation();
    }

    receive() external payable {
        _delegateToImplementation();
    }

    function implementation() external view returns (address) {
        return ERC1967.getImplementation();
    }

    function _delegateToImplementation() private {
        address impl = ERC1967.getImplementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _delegateCall(address target, bytes memory data) private {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        if (!success) {
            if (returndata.length > 0) {
                assembly {
                    revert(add(returndata, 32), mload(returndata))
                }
            }
            revert IERC1967.ERC1967ProxyInitializationFailed();
        }
    }
}
