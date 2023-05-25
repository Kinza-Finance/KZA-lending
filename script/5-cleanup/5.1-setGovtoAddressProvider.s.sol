// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/protocol/configuration/PoolAddressesProvider.sol";

contract DeployPoolConfiguratorImpl is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        address GOV = vm.envAddress("GOV");
        vm.startBroadcast(deployerPrivateKey);

        PoolAddressesProvider(provider).transferOwnership(GOV);

        vm.stopBroadcast();
    }
}
