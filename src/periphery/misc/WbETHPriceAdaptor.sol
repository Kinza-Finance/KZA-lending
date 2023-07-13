// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IEACAggregatorProxy} from './interfaces/IEACAggregatorProxy.sol';
import {IwbETH} from './interfaces/IwbETH.sol';

contract WbETHPriceAdaptor {
  address public immutable WETH;
  /**
   * @notice Price feed for (ETH / Base) pair
   */
  IEACAggregatorProxy public immutable ETH_TO_BASE;
    /**
   * @notice wbETH token contract to get exchangeRate
   */
  IwbETH public immutable WBETH;

  /**
   * @notice Number of decimals for wbETH / bETH ratio
   */
  uint8 public constant RATIO_DECIMALS = 18;

  /**
   * @notice Number of decimals in the output of this price adapter
   */
  uint8 public immutable DECIMALS;

  string private _description;

  /**
   * @param ethToBaseAggregatorAddress the address of ETH / BASE feed
   */
  constructor(address weth, address ethToBaseAggregatorAddress, address wbETHAddress) {
    WETH = weth;
    ETH_TO_BASE = IEACAggregatorProxy(ethToBaseAggregatorAddress);

    DECIMALS = ETH_TO_BASE.decimals();

    WBETH = IwbETH(wbETHAddress);

    _description = "wbETH/ETH/USD ";
  }

  function description() external view returns (string memory) {
    return _description;
  }

  function decimals() external view returns (uint8) {
    return DECIMALS;
  }

  function aggregator() external view returns (address) {
    return ETH_TO_BASE.aggregator();
  }

  function getSubTokens() external view returns (address[] memory) {
    address[] memory dependentAssets = new address[](1);
    dependentAssets[0] = WETH;
    return dependentAssets;
  }
  function getTokenType() external pure returns (uint256) {
    //  not simple but composite, for a different subgraph handler
    return 2;
  }

  function latestAnswer() public view returns (int256) {
    int256 ethToBasePrice = ETH_TO_BASE.latestAnswer();
    int256 ratio = int256(WBETH.exchangeRate());

    if (ethToBasePrice <= 0 || ratio <= 0) {
      return 0;
    }

    return (ethToBasePrice * ratio) / int256(10 ** RATIO_DECIMALS);
  }
}