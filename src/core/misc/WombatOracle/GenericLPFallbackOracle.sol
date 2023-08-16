// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract GenericLPFallbackOracle {

    // to return 0 since this is forbidden in the current AaveOracle setup
  function getAssetPrice(address asset) external view returns (uint256) {
    return 0;
  }

}