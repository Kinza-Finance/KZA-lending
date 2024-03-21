
// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/periphery/rewards/interfaces/IEmissionManager.sol";
import "../../src/periphery/rewards/interfaces/ITransferStrategyBase.sol";
import "../../src/periphery/misc/interfaces/IEACAggregatorProxy.sol";
import "../../src/core/interfaces/IPoolDataProvider.sol";

contract DeployATokensImpl is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address emissionManagerOwner = vm.envAddress("EmissionManagerOwner");
        address dataProvider = vm.envAddress("PoolDataProvider");
        address underlying = vm.envAddress("SMART_LP_HAY");
        address emissionManager = vm.envAddress("EmissionManager");
        address emissionAdmin = vm.envAddress("EmissionAdmin");
        address rewardToken = vm.envAddress("WOM");
        address rewardOracle = vm.envAddress("WomOracle");
        vm.startBroadcast(deployerPrivateKey);

        (address ATokenProxyAddress,,) = IPoolDataProvider(dataProvider).getReserveTokensAddresses(underlying);
        RewardsDataTypes.RewardsConfigInput[] memory config = new RewardsDataTypes.RewardsConfigInput[](1);
        config[0].asset = ATokenProxyAddress;
        config[0].reward = rewardToken;
        config[0].transferStrategy = ITransferStrategyBase(emissionAdmin);
        config[0].rewardOracle = IEACAggregatorProxy(rewardOracle);
        // set admin itself as the reward emission admin, which later would be replaced by the contract
        IEmissionManager(emissionManager).setEmissionAdmin(rewardToken, emissionManagerOwner);
        IEmissionManager(emissionManager).configureAssets(config);
        IEmissionManager(emissionManager).setEmissionAdmin(rewardToken, emissionAdmin);
        vm.stopBroadcast();
    }
}


