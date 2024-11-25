// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/protocol/configuration/PoolAddressesProviderRegistry.sol";

contract SetGovOnRegistry is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address addressesProviderRegistry = vm.envAddress("PoolAddressesProviderRegistry");
        address GOV = vm.envAddress("GOV");
        vm.startBroadcast(deployerPrivateKey);

        PoolAddressesProviderRegistry reg = PoolAddressesProviderRegistry(addressesProviderRegistry);
        reg.transferOwnership(GOV);

        vm.stopBroadcast();
    }
}
