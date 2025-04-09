// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/misc/AaveOracle.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";
import "../../src/core/interfaces/IPoolConfigurator.sol";

contract InitPool is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 FlashloanPremiumToProtocol = vm.envUint("FlashloanPremiumToProtocol");
        uint256 FlashloanPremiumTotal = vm.envUint("FlashloanPremiumTotal");
        address PoolImpl = vm.envAddress("PoolImpl");
        address ConfiguratorImpl = vm.envAddress("PoolConfiguratorImpl");
        address provider = vm.envAddress("PoolAddressesProvider");
        vm.startBroadcast(deployerPrivateKey);

        // this would init a proxy at the first time
        IPoolAddressesProvider(provider).setPoolImpl(PoolImpl);
        IPoolAddressesProvider(provider).setPoolConfiguratorImpl(ConfiguratorImpl);

        address configurator = IPoolAddressesProvider(provider).getPoolConfigurator();

        // set flashloanpremium
        IPoolConfigurator(configurator).updateFlashloanPremiumToProtocol(uint128(FlashloanPremiumToProtocol));
        IPoolConfigurator(configurator).updateFlashloanPremiumTotal(uint128(FlashloanPremiumTotal));

        vm.stopBroadcast();
    }
}