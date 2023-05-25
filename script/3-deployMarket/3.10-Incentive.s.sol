// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/protocol/configuration/PoolAddressesProvider.sol";
import "../../src/periphery/rewards/EmissionManager.sol";
import "../../src/periphery/rewards/RewardsController.sol";

contract DeployIncentive is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.envAddress("deployer");
        address provider = vm.envAddress("PoolAddressesProvider");
        vm.startBroadcast(deployerPrivateKey);

        EmissionManager manager = new EmissionManager(deployer);
        RewardsController controller = new RewardsController(address(manager));
        controller.initialize(address(0));
        // id of incentiveController at addressProvider
        bytes32 incentivesControllerId = 0x703c2c8634bed68d98c029c18f310e7f7ec0e5d6342c590190b3cb8b3ba54532;
        PoolAddressesProvider(provider).setAddressAsProxy(incentivesControllerId, address(controller));

        address controllerProxy = PoolAddressesProvider(provider).getAddress(incentivesControllerId);
        manager.setRewardsController(controllerProxy);

        vm.stopBroadcast();

        
    }
}
