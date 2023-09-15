// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

library UtilLib {
    error ZeroAddress();
    function checkNonZeroAddress(address _address) internal pure {
        if (_address == address(0)) revert ZeroAddress();
    }
}