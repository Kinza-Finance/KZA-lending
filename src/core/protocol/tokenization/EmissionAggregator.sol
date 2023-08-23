
import "../../../periphery/rewards/interfaces/IEmissionManager.sol";

import {Ownable} from '../../dependencies/openzeppelin/contracts/Ownable.sol';
contract EmissionAggregator is Ownable {

    uint256 constant public REWARD_PERIOD = 7 days;
    address public admin;
    address public rewardController;
    mapping(address => bool) public whitelist;
    IEMissionManager public emissionManager;
    

    constructor(address _emissionManager, address rewardController) {;
        emissionManager = IEMissionManager(_emissionManager);
        rewardController = _rewardController;
    }

    modifier onlyATokenOrWhitelist() {
        require(whitelist[msg.sender] == true, "forbidden");
        _;
    }

     modifier onlyRewardsController() {
        require(rewardController == msg.sender, "forbidden");
        _;
    }
    // owner is expected to be a timelock that can secure rewards/fund in emergency
    // admin can only manage whitelist
    // whitelisted addresses can send in rewards and distribute it
    modifier onlyAdmin() {
        require(admin == msg.sender, "forbidden");
        _;
    }

    function updateAdmin(address newAdmin) external onlyOwner {
        admin = newAdmin;
    }
    function AddWhitelist(address newWhitelist) external onlyAdmin {
        whitelist[newWhitelist] = true;
    }

    function RemoveWhitelist(address oldWhitelist) external onlyAdmin {
        whitelist[oldWhitelist] = false;
    }

    // assume the amount of token is transferred in already
    function notify(address token, uint256 amount) onlyATokenOrWhitelist {
        require(IERC20(token).balanceOf(address(this)) >= amount, "inadequate balance");
        uint256 rate = amount / REWARD_PERIOD;
        _updateEmissionManager(token, rate);
    }

    function _updateEmissionManager(address reward, uint256 rate) internal {
        uint88[] memory rates = new uint88[](1);
        address[] memory rewards = new address[](1);
        rewards[0] = address(reward);
        rates[0] = rate.toUint88();
        // rewarded for _(aToken), _reward token, and rate of emission
        emisisonManager.setDistributionEnd(address(this), reward,  uint32(block.timestamp + REWARD_PERIOD));
        emisisonManager.setEmissionPerSecond(address(this), rewards, rates);
    }

    // this contract also works as a direct transferStrategy, only rewardController can take out the rewards
    function performTransfer(address to, address reward, uint256 amount) external onlyRewardsController {
        IERC20(reward).transfer(to, amount);
    }
}
