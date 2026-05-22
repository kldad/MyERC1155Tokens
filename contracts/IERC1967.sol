// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

/// @dev События и ошибки, связанные со слотом реализации EIP-1967.
interface IERC1967 {
    event Upgraded(address indexed implementation);

    error ERC1967InvalidImplementation(address implementation);
    error ERC1967ProxyInitializationFailed();
}
