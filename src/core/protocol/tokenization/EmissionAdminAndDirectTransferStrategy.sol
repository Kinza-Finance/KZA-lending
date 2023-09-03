import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {IAToken} from '../../interfaces/IAToken.sol';
import {IPool} from '../../interfaces/IPool.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import {IEmissionManager} from '../../../periphery/rewards/interfaces/IEmissionManager.sol';
import {Ownable} from '../../../core/dependencies/openzeppelin/contracts/Ownable.sol';
// this contract exists to consolidate the reward emission 
// that many ATokens need to send for the same rewardToken
// plus being the transferStrategy on rewardsDisbutor:: performTransfer
contract EmissionAdminAndDirectTransferStrategy is Ownable {
    IEmissionManager public immutable emissionManager;
    IPool public immutable pool;

    mapping(IAToken => bool) public ATokenWhitelist;
    // the duration of distribution
    uint256 public REWARD_PERIOD = 3 days;
    // _token => reward => lastdistributionTimestamp
    mapping(address => mapping(address => uint256)) public lastRewardDistributionEnd;
    event ATokenWhitelistChanged(bool current);
    constructor(IPool _pool, IEmissionManager _emissionManager) {
        pool = _pool;
        emissionManager = _emissionManager;
    }

    modifier onlyATokenWithWhitelist() {
        require(_isATokenProxy());
        require(ATokenWhitelist[IAToken(msg.sender)]);
        /// @TODO confirm it's an AToken indeed from the pool
        _;
    }

    modifier onlyRewardsController() {
        require(msg.sender == address(emissionManager.getRewardsController()));
        _;
    }

    // assume money is already sent to the corresponding vault for claims, 
    // this contract is not responsible for reward backing
    function notify(address[] memory rewards, uint256[] memory amounts) external onlyATokenWithWhitelist {
        require(rewards.length == amounts.length);
        address token = msg.sender;
        _updateEmissionManager(token, rewards, amounts);
    }


    function performTransfer(address to, address reward, uint256 amount) external onlyRewardsController {
        IERC20(reward).transfer(to, amount);
    }

    function toggleATokenWhitelist(IAToken aToken) external onlyOwner {
        /// @TODO confirm it's an AToken indeed from the pool
        bool current = ATokenWhitelist[aToken];
        emit ATokenWhitelistChanged(current);
        ATokenWhitelist[aToken] = !current;
    }

    function updateRewardPeriod(uint256 newRewardPeriod) external onlyOwner {
        require(newRewardPeriod > 0);
        REWARD_PERIOD = newRewardPeriod;
    }

    function _updateEmissionManager(address token, address[] memory rewards, uint256[] memory amounts) internal {
        uint88[] memory rates = new uint88[](amounts.length);
        for (uint i; i < rewards.length;) {
            require(lastRewardDistributionEnd[token][rewards[i]] <= block.timestamp);
            uint256 rate = amounts[i] / REWARD_PERIOD;
            rates[i] = toUint88(rate);
            emissionManager.setDistributionEnd(token, rewards[i],  uint32(block.timestamp + REWARD_PERIOD));
            lastRewardDistributionEnd[token][rewards[i]] = block.timestamp + REWARD_PERIOD;
            unchecked {
                i++;
            }
        }
        emissionManager.setEmissionPerSecond(token, rewards, rates);
    }
    function _isATokenProxy() view private returns (bool) {
        // mutual confirmation
        address underlying = IAToken(msg.sender).UNDERLYING_ASSET_ADDRESS();
        DataTypes.ReserveData memory d = pool.getReserveData(underlying);
        return d.aTokenAddress == msg.sender;
    }

        function toUint88(uint256 value) internal pure returns (uint88) {
        if (value > type(uint88).max) {
            revert("SafeCastOverflowedUintDowncast(88, value)");
        }
        return uint88(value);
    }

}