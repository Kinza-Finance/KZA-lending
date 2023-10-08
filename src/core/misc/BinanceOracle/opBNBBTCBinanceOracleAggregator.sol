// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {AggregatorInterface} from "../../dependencies/chainlink/AggregatorInterface.sol";
import {ITWAPAggregator} from "./ITWAPAggregator.sol";
import {IFeedRegistry} from "./IFeedRegistry.sol";
import {Ownable} from "../../dependencies/openzeppelin/contracts/Ownable.sol";



contract opBNBBTCBinanceOracleAggregator is Ownable, AggregatorInterface {
    // for information; refer to https://oracle.binance.com/docs/price-feeds/contract-addresses/bnb-mainnet
    string public constant base = 'BTC';
    string public constant quote = 'USD';
    IFeedRegistry public constant feedRegistry = IFeedRegistry(0x72d55658242377AF22907b6E7350148288f88033);
    address public twapAggregatorAddress;

    event SetTWAPAggregatorAddress(address twapAggregatorAddress);

    constructor() {
    }

    function setTWAPAggregatorAddress(address _twapAggregatorAddress) external onlyOwner {
        twapAggregatorAddress = _twapAggregatorAddress;
        emit SetTWAPAggregatorAddress(_twapAggregatorAddress);
    }

    function checkBinanceOracleAccess() external view returns (bool) {
        try feedRegistry.latestAnswerByName(base, quote) returns (int256) {
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

    function getTWAP() internal view returns (int256) {
        return toInt256(ITWAPAggregator(twapAggregatorAddress).getTWAP());
    }

    function latestAnswer() external view returns (int256) {
        try feedRegistry.latestAnswerByName(base, quote) returns (int256 answer) {
            return answer;
        } catch {
            return getTWAP();
        }
    }

    function latestTimestamp() external view returns (uint256) {
        (,,,uint256 lastUpdated,) = feedRegistry.latestRoundDataByName(base, quote);
        return lastUpdated;
    }

    function latestRound() external view returns (uint256) {
        (uint80 roundId,,,,) = feedRegistry.latestRoundDataByName(base, quote);
        return uint256(roundId);
    }

    function getAnswer(uint256 roundId) external view returns (int256) {
        (address baseAddress, address quoteAddress, ) = feedRegistry.getTradingPairDetails(base, quote);
        return feedRegistry.getAnswer(baseAddress, quoteAddress, roundId);
    }

    function getTimestamp(uint256 roundId) external view returns (uint256) {
        (address baseAddress, address quoteAddress, ) = feedRegistry.getTradingPairDetails(base, quote);
        return feedRegistry.getTimestamp(baseAddress, quoteAddress, roundId);
    }
}
