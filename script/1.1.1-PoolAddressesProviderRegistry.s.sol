// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../src/core/protocol/configuration/PoolAddressesProviderRegistry.sol";

contract DeployPoolAddressesProviderRegistry is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address addressesProviderRegistryOwner = vm.envAddress("AddressesProviderRegistryOwner");
        vm.startBroadcast(deployerPrivateKey);

        PoolAddressesProviderRegistry reg = new PoolAddressesProviderRegistry(addressesProviderRegistryOwner);

        vm.stopBroadcast();
    }
}
