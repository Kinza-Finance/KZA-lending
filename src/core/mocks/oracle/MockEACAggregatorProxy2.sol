// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "../../dependencies/chainlink/AggregatorInterface.sol";

contract MockEACAggregatorProxy2 is AggregatorInterface {
    address public aggregator;
    address public asset;
    uint256 timestamp;
    uint256 roundId;
    int256 answer;
    string public name;
    mapping(uint256 => int256) public historyAnswer;
    mapping(uint256 => uint256) public historyTimtstamp;

    constructor(string memory _name, address _asset, int256 _answer) {
        name = _name;
        aggregator = address(this);
        asset = _asset;
        timestamp = block.timestamp;
        roundId = 1;
        answer = _answer;
        historyAnswer[roundId] = answer;
        historyTimtstamp[roundId] = block.timestamp;
    }

    function decimals() external pure returns (uint8) {
        return uint8(8);
    }

    function latestAnswer() external view returns (int256) {
        return answer;
    }

    function latestTimestamp() external view returns (uint256) {
        return timestamp;
    }

    function latestRound() external view returns (uint256) {
        return roundId;
    }

    function getAnswer(uint256 _roundId) external view returns (int256) {
        return historyAnswer[_roundId];
    }

    function getTimestamp(uint256 _roundId) external view returns (uint256) {
        return historyTimtstamp[_roundId];
    }

    function updateAnswer(int256 _answer) external {
        answer = _answer;
        roundId += 1;
        historyAnswer[roundId] = _answer;
        historyTimtstamp[roundId] = block.timestamp;
        emit AnswerUpdated(_answer, roundId, block.timestamp);
    }
}
