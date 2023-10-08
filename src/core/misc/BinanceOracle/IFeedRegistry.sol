pragma solidity = 0.8.10;
interface IFeedRegistry {
    function latestAnswerByName(string memory base, string memory quote) external view returns(int256);
    function latestRoundDataByName(string memory base, string memory quote) external view returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function getTradingPairDetails(string memory base, string memory quote) external view returns(address baseAddress, address quoteAddress, address feedAddress);
    function getAnswer(address baseAddress, address quoteAddress, uint256 roundId) external view returns(int256);
    function getTimestamp(address baseAddress, address quoteAddress, uint256 roundId) external view returns(uint256);
}