// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";
import "../../src/periphery/misc/WrappedTokenGatewayV3.sol";

contract deployGateway is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        address gov = vm.envAddress("GOV");
        bool isProd = vm.envBool("isProd");
        address WBNB;
        if (isProd) {
            WBNB = vm.envAddress("WBNB_PROD");
        } else {
            // since we created a testnetBNB for facuet, but need a real WBNB for testing the gateway
            WBNB = vm.envAddress("WBNB_TESTNET_REAL");
        }
        
        vm.startBroadcast(deployerPrivateKey);

        address pool = IPoolAddressesProvider(provider).getPool();
        new WrappedTokenGatewayV3(WBNB, gov, IPool(pool));
        
        vm.stopBroadcast();
    }
}
