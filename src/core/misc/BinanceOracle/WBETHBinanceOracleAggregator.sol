// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {AggregatorInterface} from "../../dependencies/chainlink/AggregatorInterface.sol";
import {SID} from "../../dependencies/binance/SID.sol";
import {IPublicResolver} from "../../dependencies/binance/IPublicResolver.sol";
import {Ownable} from "../../dependencies/openzeppelin/contracts/Ownable.sol";

interface IChainlinkAggregatorProxy {
    function latestAnswer() external view returns (int256);
}

contract WBETHBinanceOracleAggregator is Ownable, AggregatorInterface {

    // for information; refer to https://oracle.binance.com/docs/price-feeds/contract-addresses/bnb-mainnet
    string private constant feedRegistrySID = "wbeth-usd.boracle.bnb";
    bytes32 private constant nodeHash = 0xf4132c82e8606c3c23c6e0e05f3fdaa88d1d56188433bc36a95c2f89504f31d2;
    address public immutable sidRegistryAddress;
    address public chainlinkAggregatorProxy;

    event SetChainlinkAggregatorProxyAddress(address NewChainlinkAggregatorProxy);

    constructor(address _sidRegistryAddress, address _chainlinkAggregator, address _weth) {
        sidRegistryAddress = _sidRegistryAddress;
        chainlinkAggregatorProxy = _chainlinkAggregator;
        WETH = _weth;
    }

    function setChainlinkAggregatorAddress(address _chainlinkAggregatorProxy) external onlyOwner {
        chainlinkAggregatorProxy = _chainlinkAggregatorProxy;
        emit SetChainlinkAggregatorProxyAddress(_chainlinkAggregatorProxy);
    }

    function getFeedRegistryAddress() public view returns (address) {
        SID sidRegistry = SID(sidRegistryAddress);
        address publicResolver = sidRegistry.resolver(nodeHash);
        return IPublicResolver(publicResolver).addr(nodeHash);
    }

    function checkBinanceOracleAccess() external view returns (bool) {
        AggregatorInterface feedRegistry = AggregatorInterface(getFeedRegistryAddress());
        try feedRegistry.latestAnswer() returns (int256) {
            return true;
        } catch {
            return false;
        }
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */

    function getChainlinkAnswer() internal view returns (int256) {
        return IChainlinkAggregatorProxy(chainlinkAggregatorProxy).latestAnswer();
    }

    function latestAnswer() external view returns (int256) {
        AggregatorInterface feedRegistry = AggregatorInterface(getFeedRegistryAddress());
        try feedRegistry.latestAnswer() returns (int256 answer) {
            return answer;
        } catch {
            return getChainlinkAnswer();
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