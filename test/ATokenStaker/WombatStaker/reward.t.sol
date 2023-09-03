
import {ATokenWombatStakerBaseTest} from "./ATokenWombatStakerBaseTest.t.sol";
import {IAToken} from "../../../src/core/interfaces/IAToken.sol";
import {IERC20} from "../../../src/core/dependencies/openzeppelin/contracts/IERC20.sol";
import {IERC20} from "../../../src/core/dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {RewardsDataTypes} from '../../../src/periphery/rewards/libraries/RewardsDataTypes.sol';
import {ITransferStrategyBase} from '../../../src/periphery/rewards/interfaces/ITransferStrategyBase.sol';
import {IEACAggregatorProxy} from '../../../src/periphery/misc/interfaces/IEACAggregatorProxy.sol';
import {MOCK_WOM_ORACLE, WOM, POOL_ADMIN, EMISSION_MANAGER_ADMIN} from "test/utils/Addresses.sol";

contract rewardTest is ATokenWombatStakerBaseTest {
    // since we want to test reward emission, a historical block is pinned
    // such that we can write test with some passage of time.
    // make sure to connect to an archive node to enable this feature (ideally through ganache to enable forking)
    // public BSC rpc like the binance ones does not work
    // use a very recent block to work around this if only full node is accessible
    uint256 internal _forkBlock = 31_400_000;

    IERC20 internal rewardToken = IERC20(WOM);
    function setUp() public virtual override(ATokenWombatStakerBaseTest) {
        // this varaible is taken by the parent setUp
        // uint256 forkBlock = _forkBlock;
        ATokenWombatStakerBaseTest.setUp();
        // configure WOM as a reward token sendable by emissionAdmin
        configReward();
        vm.startPrank(EMISSION_MANAGER_ADMIN);
        emissionManager.setEmissionAdmin(address(rewardToken), address(emissionAdmin));
        vm.prank(POOL_ADMIN);
        emissionAdmin.toggleATokenWhitelist(IAToken(ATokenProxyStaker));
    }

    function test_claim() public {
        address bob = address(1);
        uint256 amount = 1e18;
        deposit(bob, amount, address(underlying));
        uint256 TimeToPass = 1 days;
        vm.warp(TimeToPass + block.timestamp);
        claimWithReward();
    }

    function test_distribute() public {
        // set up a depositor
        address bob = address(1);
        uint256 amount = 1e18;
        deposit(bob, amount, address(underlying));
        // passage of time
        uint256 TimeToPass = 1 days;
        vm.warp(TimeToPass + block.timestamp);
        // distribute 
        sendToEmissionManager();
        // assert the user has non-zero claimable
        uint256 TimeToPassForRewardToAccrue = 1 days;
        vm.warp(TimeToPassForRewardToAccrue + block.timestamp);
        uint256 claimable = emissionManager.getRewardsController().getUserAccruedRewards(bob, address(rewardToken));
        assertGt(claimable, 0);
    }

    function configReward() internal {
        RewardsDataTypes.RewardsConfigInput[] memory config = new RewardsDataTypes.RewardsConfigInput[](1);
        config[0].asset = address(ATokenProxyStaker);
        config[0].reward = address(rewardToken);
        config[0].transferStrategy = ITransferStrategyBase(address(emissionAdmin));
        config[0].rewardOracle = IEACAggregatorProxy(MOCK_WOM_ORACLE);
        vm.startPrank(EMISSION_MANAGER_ADMIN);
        // set admin itself as the reward emission admin, which later would be replaced by the contract
        emissionManager.setEmissionAdmin(address(rewardToken), EMISSION_MANAGER_ADMIN);
        emissionManager.configureAssets(config);
    }
    function claimWithReward() internal {
        address aToken = address(ATokenProxyStaker);
        vm.startPrank(POOL_ADMIN);
        uint256 beforeReward = rewardToken.balanceOf(aToken);
        ATokenProxyStaker.multiClaim();
        uint256 afterReward = rewardToken.balanceOf(aToken);
        assertGt(afterReward, beforeReward); 
    }

    function sendToEmissionManager() internal {
        address[] memory rewards = new address[](1);
        rewards[0] = address(rewardToken);
        vm.prank(POOL_ADMIN);
        ATokenProxyStaker.sendEmission(rewards);
    }
}