// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IEACAggregatorProxy} from './interfaces/IEACAggregatorProxy.sol';

contract PTokenPriceAdaptor {
  uint8 public immutable DECIMALS;
  IEACAggregatorProxy public aggregatorProxy;
  address public token;

  constructor(address dependentAggregator, address dependentToken) {
    token = dependentToken;
    aggregatorProxy = IEACAggregatorProxy(dependentAggregator);
    DECIMALS = aggregatorProxy.decimals();
  }

  function aggregator() external view returns (address) {
    return aggregatorProxy.aggregator();
  }

  function getSubTokens() external view returns (address[] memory) {
    address[] memory dependentAssets = new address[](1);
    dependentAssets[0] = token;
    return dependentAssets;
  }
  function getTokenType() external pure returns (uint256) {
    //  not simple but composite, for a different subgraph handler
    return 2;
  }

  function latestAnswer() public view returns (int256) {
    return aggregatorProxy.latestAnswer();
  }

    function decimals() external view returns (uint8) {
    return DECIMALS;
  }
}