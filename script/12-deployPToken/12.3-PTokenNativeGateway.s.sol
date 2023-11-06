// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/periphery/pToken/ProtectedNativeTokenGateway.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";

contract DeployProtectedNativeGateway is Script {
    function run() external {
        address deployer = vm.envAddress("Deployer");
        address provider = vm.envAddress("PoolAddressesProvider");
        address wbnb = vm.envAddress("WBNB");
        address pwbnb = vm.envAddress("PWBNB");
        vm.startBroadcast(deployer);
        
        IPool pool = IPool(IPoolAddressesProvider(provider).getPool());
        new ProtectedNativeTokenGateway(wbnb, pwbnb, pool);
        vm.stopBroadcast();
    }
}
