// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/misc/AaveOracle.sol";
import "../../src/core/misc/BinanceOracle/HAYBinanceOracleAggregator.sol";

contract InitOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address oracle = vm.envAddress("Oracle");
        bool isProd = vm.envBool("isProd");
        address BSCTEST_SID_Registry = vm.envAddress("BSCTEST_SID_Registry");
        address[] memory assets = new address[](1);
        address[] memory sources = new address[](1);
        
        vm.startBroadcast(deployerPrivateKey);

        if (isProd) {
            assets[0] = vm.envAddress("BUSD_PROD");
            assets[1] = vm.envAddress("USDC_PROD");
            assets[2] = vm.envAddress("USDT_PROD");
            assets[3] = vm.envAddress("WBTC_PROD");
            assets[4] = vm.envAddress("WETH_PROD");
            assets[5] = vm.envAddress("WBNB_PROD");
            sources[0] = vm.envAddress("BUSD_AGGREGATOR_PROD");
            sources[1] = vm.envAddress("USDC_AGGREGATOR_PROD");
            sources[2] = vm.envAddress("USDT_AGGREGATOR_PROD");
            sources[3] = vm.envAddress("WBTC_AGGREGATOR_PROD");
            sources[4] = vm.envAddress("WETH_AGGREGATOR_PROD");
            sources[5] = vm.envAddress("WBNB_AGGREGATOR_PROD");
        } else {
            // assets[0] = vm.envAddress("BUSD_TESTNET");
            // assets[1] = vm.envAddress("USDC_TESTNET");
            // assets[2] = vm.envAddress("USDT_TESTNET");
            // assets[3] = vm.envAddress("WBTC_TESTNET");
            // assets[4] = vm.envAddress("WETH_TESTNET");
            // assets[5] = vm.envAddress("WBNB_TESTNET");
            // sources[0] = vm.envAddress("BUSD_AGGREGATOR_TESTNET");
            // sources[1] = vm.envAddress("USDC_AGGREGATOR_TESTNET");
            // sources[2] = vm.envAddress("USDT_AGGREGATOR_TESTNET");
            // sources[3] = vm.envAddress("WBTC_AGGREGATOR_TESTNET");
            // sources[4] = vm.envAddress("WETH_AGGREGATOR_TESTNET");
            // sources[5] = vm.envAddress("WBNB_AGGREGATOR_TESTNET");

            // binance oracle
            // assets[0] = vm.envAddress("HAY_TESTNET");
            // bytes32 HAY_NODE_HASH_TESTNET = vm.envBytes32("HAY_NODE_HASH_TESTNET");
            HAYBinanceOracleAggregator hayAggregator = new HAYBinanceOracleAggregator(BSCTEST_SID_Registry);
            sources[0] = address(hayAggregator);
        }

        AaveOracle(oracle).setAssetSources(assets, sources);
        vm.stopBroadcast();
        
    }
}
