// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.34;

/// @dev Защита однократной инициализации (паттерн для прокси / ERC-1967).
abstract contract Initializable {
    bool private _initialized;
    bool private _initializing;

    error InitializableAlreadyInitialized();
    error InitializableNotInitializing();
    error InitializableInvalidInitialization();

    modifier initializer() {
        if (_initialized) revert InitializableAlreadyInitialized();
        if (!_initializing) {
            _initializing = true;
            _;
            _initializing = false;
            _initialized = true;
        } else {
            _;
        }
    }

    modifier onlyInitializing() {
        if (!_initializing) revert InitializableNotInitializing();
        _;
    }

    function _disableInitializers() internal {
        if (_initialized) revert InitializableInvalidInitialization();
        _initialized = true;
    }
}
