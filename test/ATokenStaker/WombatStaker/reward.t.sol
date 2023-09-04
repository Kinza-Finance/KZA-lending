
import {ATokenWombatStakerBaseTest} from "./ATokenWombatStakerBaseTest.t.sol";
import {IAToken} from "../../../src/core/interfaces/IAToken.sol";
import {IERC20} from "../../../src/core/dependencies/openzeppelin/contracts/IERC20.sol";
import {IERC20} from "../../../src/core/dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {RewardsDataTypes} from '../../../src/periphery/rewards/libraries/RewardsDataTypes.sol';
import {ITransferStrategyBase} from '../../../src/periphery/rewards/interfaces/ITransferStrategyBase.sol';
import {IEACAggregatorProxy} from '../../../src/periphery/misc/interfaces/IEACAggregatorProxy.sol';
import {MOCK_WOM_ORACLE, WOM, POOL_ADMIN, EMISSION_MANAGER_ADMIN} from "test/utils/Addresses.sol";

contract rewardTest is ATokenWombatStakerBaseTest {
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
        address[] memory assets = new address[](1);
        assets[0] = address(ATokenProxyStaker);
        uint256 claimable = emissionManager.getRewardsController().getUserRewards(assets, bob, address(rewardToken));
        assertGt(claimable, 0);
    }

    // test if reward are split fairly
    function test_splitReward() public {
        // set up a depositor
        address bob = address(1);
        uint256 bob_amount = 1e18;
        address alice = address(2);
        uint256 alice_amount = 2e18;
        deposit(bob, bob_amount, address(underlying));
        deposit(alice, alice_amount, address(underlying));
        // passage of time
        uint256 TimeToPass = 1 days;
        vm.warp(TimeToPass + block.timestamp);
        // distribute 
        sendToEmissionManager();
        // assert the user has non-zero claimable
        uint256 TimeToPassForRewardToAccrue = 1 days;
        vm.warp(TimeToPassForRewardToAccrue + block.timestamp);
        address[] memory assets = new address[](1);
        assets[0] = address(ATokenProxyStaker);
        uint256 bob_claimable = emissionManager.getRewardsController().getUserRewards(assets, bob, address(rewardToken));
        uint256 alice_claimable = emissionManager.getRewardsController().getUserRewards(assets, alice, address(rewardToken));
        assertEq(bob_claimable * alice_amount / bob_amount, alice_claimable);

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