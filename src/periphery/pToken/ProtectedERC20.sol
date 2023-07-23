// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.10;

import "@openzeppelin/token/ERC20/extensions/ERC20Wrapper.sol";
import "@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

contract ProtectedERC20 is ERC20, ERC20Wrapper {

    constructor(address underlying, string memory underlyingName, string memory underlyingSymbol) 
    ERC20(
        string(abi.encodePacked("Kinza Protected ", IERC20Metadata(underlying).name())),
        string(abi.encodePacked("p", IERC20Metadata(underlying).symbol()))
        )
    ERC20Wrapper(IERC20(underlying)) {
    }

    function decimals() public view virtual override(ERC20, ERC20Wrapper) returns (uint8) {
        // ERC20Wrapper would use try catch to return decimal 18 if the external read fails
        // this would rather fail and revert if the underlying decimal read does not return
        return IERC20Metadata(address(underlying())).decimals();
    }

}