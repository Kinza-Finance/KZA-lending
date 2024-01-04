// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {AggregatorInterface} from "../../dependencies/chainlink/AggregatorInterface.sol";
import {SID} from "../../dependencies/binance/SID.sol";
import {IPublicResolver} from "../../dependencies/binance/IPublicResolver.sol";
import {ITWAPAggregator} from "./ITWAPAggregator.sol";
import {Ownable} from "../../dependencies/openzeppelin/contracts/Ownable.sol";


contract SNBNBBinanceOracleCustomAggregator is Ownable, AggregatorInterface {
    // for information; refer to https://oracle.binance.com/docs/price-feeds/contract-addresses/bnb-mainnet
    // fyi, kept for integration and exist in upstream
    string private constant feedRegistrySID = "snbnb-usd.boracle.bnb";
    bytes32 private constant nodeHash = 0x153896165d7b9a227edd631aead0720dce98d9213dac89cbc36da25457262097;
    address public immutable sidRegistryAddress;

    AggregatorInterface public immutable internalOracle;
    int256 public immutable maxFallbackThreshold;
    address public twapAggregatorAddress;

    event SetTWAPAggregatorAddress(address twapAggregatorAddress);

    constructor(address _sidRegistryAddress, address _internalOracle, int256 _maxFallbackThreshold) {
        sidRegistryAddress = _sidRegistryAddress;
        internalOracle  = AggregatorInterface(_internalOracle);
        maxFallbackThreshold = _maxFallbackThreshold;
    }

    function setTWAPAggregatorAddress(address _twapAggregatorAddress) external onlyOwner {
        twapAggregatorAddress = _twapAggregatorAddress;
        emit SetTWAPAggregatorAddress(_twapAggregatorAddress);
    }

    function getFeedRegistryAddress() public view returns (address) {
        SID sidRegistry = SID(sidRegistryAddress);
        address publicResolver = sidRegistry.resolver(nodeHash);
        return IPublicResolver(publicResolver).addr(nodeHash);
    }


    // for deprecated usage
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
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }

    function getTWAP() public view returns (int256) {
        return toInt256(ITWAPAggregator(twapAggregatorAddress).getTWAP());
    }

    function latestAnswer() external view returns (int256) {
        int256 price = internalOracle.latestAnswer();
        if (_shouldFallbackToTwap(price)) {
            return getTWAP();
        }
        return price;
    }

    function latestTimestamp() external view returns (uint256) {
        return internalOracle.latestTimestamp();
    }

    function latestRound() external view returns (uint256) {
        return internalOracle.latestRound();
    }

    function getAnswer(uint256 roundId) external view returns (int256) {
        return internalOracle.getAnswer(roundId);
    }

    function getTimestamp(uint256 roundId) external view returns (uint256) {
        return internalOracle.getTimestamp(roundId);
    }

    function _shouldFallbackToTwap(int256 price) internal view returns(bool) {
        if (price > maxFallbackThreshold) {
            return true;
        }
        return false;
    }
}