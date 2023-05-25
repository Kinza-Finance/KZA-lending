// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/misc/AaveProtocolDataProvider.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";

contract DeployPoolAddressesProvider is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address addressprovider = vm.envAddress("PoolAddressesProvider");
        vm.startBroadcast(deployerPrivateKey);

        new AaveProtocolDataProvider(IPoolAddressesProvider(addressprovider));

        vm.stopBroadcast();
    }
}
