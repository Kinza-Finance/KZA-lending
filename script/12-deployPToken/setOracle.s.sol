// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/misc/AaveOracle.sol";
import "../../src/periphery/misc/PTokenPriceAdaptor.sol";

contract InitBinanceOracle is Script {
    function run() external {
        address deployer = vm.envAddress("Deployer");
        address asset = vm.envAddress("PUSDC");
        address dependentAsset = vm.envAddress("USDC");
        address aggregator = vm.envAddress("USDC_AGGREGATOR");
        address oracle = vm.envAddress("Oracle");

        vm.startBroadcast(deployer);
        PTokenPriceAdaptor adaptor = new PTokenPriceAdaptor(aggregator, dependentAsset);
        address[] memory assets = new address[](1);
        address[] memory sources = new address[](1);
        assets[0] = asset;
        sources[0] = address(adaptor);
        AaveOracle(oracle).setAssetSources(assets, sources);
        vm.stopBroadcast();
    }
}