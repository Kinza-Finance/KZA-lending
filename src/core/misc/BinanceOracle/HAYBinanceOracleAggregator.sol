// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {AggregatorInterface} from "../../dependencies/chainlink/AggregatorInterface.sol";
import {SID} from "../../dependencies/binance/SID.sol";
import {IPublicResolver} from "../../dependencies/binance/IPublicResolver.sol";
import {ITWAPAggregator} from "./ITWAPAggregator.sol";
import {Ownable} from "../../dependencies/openzeppelin/contracts/Ownable.sol";

contract HAYBinanceOracleAggregator is Ownable, AggregatorInterface {
    string public constant feedRegistrySID = "hay-usd.boracle.bnb";
    bytes32 public constant nodeHash = 0xdefb391114b081d478abf3dc3f56caa145fee6ff97aedc4ff0342eb8b06da292;
    address public immutable sidRegistryAddress;
    address twapAggregatorAddress;

    event SetTWAPAggregatorAddress(address twapAggregatorAddress);

    constructor(address _sidRegistryAddress) {
        sidRegistryAddress = _sidRegistryAddress;
    }

    function setTWAPAggregatorAddress(address _twapAggregatorAddress) external onlyOwner {
        twapAggregatorAddress = _twapAggregatorAddress;
        emit SetTWAPAggregatorAddress(_twapAggregatorAddress);
    }

    function getFeedRegistryAddress() internal view returns (address) {
        SID sidRegistry = SID(sidRegistryAddress);
        address publicResolver = sidRegistry.resolver(nodeHash);
        return IPublicResolver(publicResolver).addr(nodeHash);
    }

    function getTWAP() private view returns (int256) {
        return int256(ITWAPAggregator(twapAggregatorAddress).getTWAP());
    }

    function checkBinanceOracleAccess() external view returns (bool) {
        AggregatorInterface feedRegistry = AggregatorInterface(getFeedRegistryAddress());
        if (feedRegistry.latestAnswer() >= 0) {
            return true;
        }
        return false;
    }

    function latestAnswer() external view returns (int256) {
        AggregatorInterface feedRegistry = AggregatorInterface(getFeedRegistryAddress());
        try feedRegistry.latestAnswer() returns (int256 answer) {
            return answer;
        } catch {
            return getTWAP();
        }
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
