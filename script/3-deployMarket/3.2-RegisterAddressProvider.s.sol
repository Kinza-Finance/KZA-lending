// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/protocol/configuration/PoolAddressesProviderRegistry.sol";

contract DeployPoolAddressesProvider is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 id = vm.envUint("PoolAddressesProviderRegistry_ID");
        address provider = vm.envAddress("PoolAddressesProvider");
        address poolAddressesProviderRegistry = vm.envAddress("PoolAddressesProviderRegistry");
        vm.startBroadcast(deployerPrivateKey);

        PoolAddressesProviderRegistry(poolAddressesProviderRegistry).registerAddressesProvider(provider, id);

        vm.stopBroadcast();
    }
}
