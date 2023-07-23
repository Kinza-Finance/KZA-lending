// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/periphery/pToken/ProtectedNativeTokenGateway.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";

contract DeployProtectedNativeGateway is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        bool isProd = vm.envBool("isProd");
        address wbnb;
        address pwbnb;
        if (isProd) {
            wbnb = vm.envAddress("WBNB_PROD");
            pwbnb = vm.envAddress("PWBNB_PROD");
        } else {
            wbnb = vm.envAddress("WBNB_TESTNET");
            pwbnb = vm.envAddress("PWBNB_TESTNET");
        }
        vm.startBroadcast(deployerPrivateKey);
        
        IPool pool = IPool(IPoolAddressesProvider(provider).getPool());
        new ProtectedNativeTokenGateway(wbnb, pwbnb, pool);
        vm.stopBroadcast();
    }
}
