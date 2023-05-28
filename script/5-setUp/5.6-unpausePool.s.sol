// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/interfaces/IPoolConfigurator.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";

contract UnpausePool is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        vm.startBroadcast(deployerPrivateKey);

        IPoolConfigurator configurator = IPoolConfigurator(IPoolAddressesProvider(provider).getPoolConfigurator());
        configurator.setPoolPause(false);
        vm.stopBroadcast();
    }
}
