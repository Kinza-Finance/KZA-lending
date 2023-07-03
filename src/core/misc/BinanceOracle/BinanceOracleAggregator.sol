// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {AggregatorInterface} from "../../dependencies/chainlink/AggregatorInterface.sol";
import {SID} from "../../dependencies/binance/SID.sol";
import {IPublicResolver} from "../../dependencies/binance/IPublicResolver.sol";

contract BinanceOracleAggregator is AggregatorInterface {
    address public immutable sidRegistryAddress;
    address public asset;
    bytes32 nodeHash;

    constructor(address _sidRegistryAddress, address _asset, bytes32 _nodeHash) {
        sidRegistryAddress = _sidRegistryAddress;
        asset = _asset;
        nodeHash = _nodeHash;
    }

    function getFeedRegistryAddress() internal view returns (address) {
        SID sidRegistry = SID(sidRegistryAddress);
        address publicResolverAddress = sidRegistry.resolver(nodeHash);
        IPublicResolver publicResolver = IPublicResolver(publicResolverAddress);

        return publicResolver.addr(nodeHash);
    }

    function latestAnswer() external view returns (int256) {
        AggregatorInterface feedRegistry = AggregatorInterface(getFeedRegistryAddress());
        return feedRegistry.latestAnswer();
    }

    function latestTimestamp() external view returns (uint256) {
        AggregatorInterface feedRegistry = AggregatorInterface(getFeedRegistryAddress());
        return feedRegistry.latestTimestamp();
    }

    function latestRound() external view returns (uint256) {
        AggregatorInterface feedRegistry = AggregatorInterface(getFeedRegistryAddress());
        return feedRegistry.latestRound();
    }

    function getAnswer(uint256 roundId) external view returns (int256) {
        AggregatorInterface feedRegistry = AggregatorInterface(getFeedRegistryAddress());
        return feedRegistry.getAnswer(roundId);
    }

    function getTimestamp(uint256 roundId) external view returns (uint256) {
        AggregatorInterface feedRegistry = AggregatorInterface(getFeedRegistryAddress());
        return feedRegistry.getTimestamp(roundId);
    }
}
