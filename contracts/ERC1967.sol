// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import {IERC1967} from "./IERC1967.sol";

/// @dev Утилиты для слота реализации EIP-1967:
/// `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`
library ERC1967 {
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function getImplementation() internal view returns (address implementation) {
        assembly {
            implementation := sload(IMPLEMENTATION_SLOT)
        }
    }

    function setImplementation(address implementation) internal {
        if (implementation.code.length == 0) {
            revert IERC1967.ERC1967InvalidImplementation(implementation);
        }
        assembly {
            sstore(IMPLEMENTATION_SLOT, implementation)
        }
        emit IERC1967.Upgraded(implementation);
    }
}
