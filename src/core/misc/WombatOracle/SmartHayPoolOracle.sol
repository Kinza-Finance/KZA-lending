// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {AggregatorInterface} from "../../dependencies/chainlink/AggregatorInterface.sol";

// immutable, just create another contract if any underlying aggregators need to be updated
contract SmartHayPoolOracle {
    // for information; refer to https://oracle.binance.com/docs/price-feeds/contract-addresses/bnb-mainnet
    AggregatorInterface public usdcAggregator;
    AggregatorInterface public usdtAggregator;
    AggregatorInterface public hayAggregator;
    address[3] private dependentAssets;

    // dependent on other internal aggregator.
    constructor(address _usdcAggregator, address _usdtAggregator, address _hayAggregator,
                address _usdc, address _usdt, address _hay) {
        usdcAggregator = AggregatorInterface(_usdcAggregator);
        usdtAggregator = AggregatorInterface(_usdtAggregator);
        hayAggregator = AggregatorInterface(_hayAggregator);
        dependentAssets[0] = _usdc;
        dependentAssets[1] = _usdt;
        dependentAssets[2] = _hay;
    }


    function latestAnswer() external view returns (int256) {
        int256 usdcPrice = usdcAggregator.latestAnswer();
        int256 usdtPrice = usdtAggregator.latestAnswer();
        int256 hayPrice = hayAggregator.latestAnswer();
        // return the minimum of three
        return usdcPrice > usdtPrice 
                ? usdtPrice > hayPrice ? hayPrice
                                       : usdtPrice
                : usdcPrice > hayPrice ? hayPrice
                                       : usdcPrice;
    }

    function latestTimestamp() external view returns (uint256) {
        uint256 usdcTime = usdcAggregator.latestTimestamp();
        uint256 usdtTime = usdtAggregator.latestTimestamp();
        uint256 hayTime = hayAggregator.latestTimestamp();
        // return the minimum of three time (the most stale)
        return usdcTime > usdtTime 
                ? usdtTime > hayTime ? hayTime
                                       : usdtTime
                : usdcTime > hayTime ? hayTime
                                       : usdcTime;
    }

    // this is quite not useful since each round might be different on each aggreagator
    function latestRound() external view returns (uint256) {
        uint256 usdcRound = usdcAggregator.latestRound();
        uint256 usdtRound = usdtAggregator.latestRound();
        uint256 hayRound = hayAggregator.latestRound();
        // return the minimum of three round (the most stale)
        return usdcRound > usdtRound
                ? usdtRound > hayRound ? hayRound
                                       : usdtRound
                : usdcRound > hayRound ? hayRound
                                       : usdcRound;
    }

    function getSubTokens() external view returns (address[] memory) {
        address[] memory _dependentAssets = new address[](3);
        _dependentAssets[0] = dependentAssets[0];
        _dependentAssets[1] = dependentAssets[1];
        _dependentAssets[2] = dependentAssets[2];
        return _dependentAssets;
  }
}
