// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/misc/AaveOracle.sol";
import "../../src/core/misc/BinanceOracle/SNBNBBinanceOracleAggregator.sol";

contract InitBinanceOracle is Script {
    function run() external {
        address deployer = vm.envAddress("Deployer");
        address asset = vm.envAddress("PUSDT");
        address agg = vm.envAddress("USDT_AGGREGATOR");
        address oracle = vm.envAddress("Oracle");

        vm.startBroadcast(deployer);
        address[] memory assets = new address[](1);
        address[] memory sources = new address[](1);
        assets[0] = asset;
        sources[0] = address(aggregator);
        AaveOracle(oracle).setAssetSources(assets, sources);
        vm.stopBroadcast();
    }
}