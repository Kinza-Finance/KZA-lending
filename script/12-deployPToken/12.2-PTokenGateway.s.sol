// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/periphery/pToken/ProtectedERC20Gateway.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";

contract DeployProtectedERC20Gateway is Script {
    function run() external {
        address deployer = vm.envAddress("Deployer");
        address provider = vm.envAddress("PoolAddressesProvider");
        vm.startBroadcast(deployer);
        IPool pool = IPool(IPoolAddressesProvider(provider).getPool());
        new ProtectedERC20Gateway(pool);

        vm.stopBroadcast();
    }
}
