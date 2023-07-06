// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/periphery/misc/WbETHPriceAdaptor.sol";

contract deployWbETHPriceAdaptor is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        bool isProd = vm.envBool("isProd");
        address wbeth;
        address ethAggregator;
        if (isProd) {
            wbeth = vm.envAddress("WBETH_PROD");
            ethAggregator = vm.envAddress("WETH_AGGREGATOR_PROD");
        } else {
            wbeth = vm.envAddress("WBETH_TESTNET");
            ethAggregator = vm.envAddress("WETH_AGGREGATOR_TESTNET");
        }
        vm.startBroadcast(deployerPrivateKey);

        new WbETHPriceAdaptor(ethAggregator, wbeth);
        
        vm.stopBroadcast();
    }
}
