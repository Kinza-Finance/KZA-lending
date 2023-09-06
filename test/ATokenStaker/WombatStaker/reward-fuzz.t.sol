// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './reward.t.sol';
// import { console2 } from "forge-std/console2.sol";

contract rewardFuzzTest is rewardTest {
    function setUp() public virtual override(rewardTest) {
        rewardTest.setUp();
    }

    function testFuzz_claimWOM(uint16 TimeToPass) public {
        vm.assume(TimeToPass > 1);
        address bob = address(1);
        deposit(bob, 1e18, address(underlying));
        vm.warp(TimeToPass + block.timestamp);
        claimRewardFromMasterWombat();
    }

    function testFuzz_distribute(uint32 _TimeToPass, uint32 _TimeToPassForRewardToAccrue) public {
        uint256 timeToPass = bound(_TimeToPass, 1, 2**31);
        // console2.log('REWARD_PERIOD', emissionAdmin.REWARD_PERIOD());
        uint256 timeToPassForRewardToAccrue = bound(_TimeToPassForRewardToAccrue, 1, emissionAdmin.REWARD_PERIOD());
        // set up a depositor
        address bob = address(1);
        uint256 amount = 1e18;
        deposit(bob, amount, address(underlying));
        // passage of time
        vm.warp(timeToPass + block.timestamp);

        (address ATokenProxyAddress,,) = dataProvider.getReserveTokensAddresses(underlying);

        uint256 beforeReward = IERC20(rewardToken).balanceOf(ATokenProxyAddress);
        IMasterWombat masterWombat = ATokenProxyStaker._masterWombat();
        (uint256 pendingReward,,,) = masterWombat.pendingTokens(ATokenProxyStaker._pid(), ATokenProxyAddress);
        assertGt(pendingReward, 0);
        uint256 totalReward = pendingReward + beforeReward;
        // console2.log("totalReward", totalReward);

        address[] memory assets = new address[](1);
        assets[0] = address(ATokenProxyStaker);
        uint256 claimableBefore = emissionManager.getRewardsController().getUserRewards(assets, bob, address(rewardToken));
        assertEq(claimableBefore, 0);

        // distribute 
        sendToEmissionManager();
        // assert the user has non-zero claimable
        vm.warp(timeToPassForRewardToAccrue + block.timestamp);
        uint256 claimable = emissionManager.getRewardsController().getUserRewards(assets, bob, address(rewardToken));
        assertEq(claimable, totalReward / emissionAdmin.REWARD_PERIOD() * timeToPassForRewardToAccrue);
    }
}
