// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {ERC1967} from "./ERC1967.sol";
import {IERC1967} from "./IERC1967.sol";

/// @dev UUPS: логика апгрейда в реализации; вызывается только через прокси (delegatecall).
abstract contract UUPSUpgradeable {
    address private immutable _implementation;

    error UUPSUnauthorizedCallContext();
    error UUPSUpgradeNotAuthorized();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _implementation = address(this);
    }

    modifier onlyProxy() {
        if (address(this) == _implementation) revert UUPSUnauthorizedCallContext();
        _;
    }

    function proxiableUUID() external pure returns (bytes32) {
        return ERC1967.IMPLEMENTATION_SLOT;
    }

    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable onlyProxy {
        _authorizeUpgrade(newImplementation);
        ERC1967.setImplementation(newImplementation);
        if (data.length > 0) {
            (bool success, bytes memory returndata) = newImplementation.delegatecall(data);
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

    function _authorizeUpgrade(address newImplementation) internal virtual;
}
