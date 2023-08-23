// the primary purpose is to consolidate reward, since each reward can only be set by 1 address on emissionManager
interface IEmissionAggregator {
    function notify(address token, uint256 amount) external;
}