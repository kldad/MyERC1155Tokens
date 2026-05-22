// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

import "./MyERC1155Tokens.sol";

/// @dev Вторая реализация для демонстрации UUPS-апгрейда; layout storage не меняется.
contract MyERC1155TokensV2 is MyERC1155Tokens {
    function version() public pure override returns (uint256) {
        return 2;
    }
}
