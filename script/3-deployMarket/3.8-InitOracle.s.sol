// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/misc/AaveOracle.sol";
import "../../src/core/misc/BinanceOracle/HAYBinanceOracleAggregator.sol";

contract InitOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address oracle = vm.envAddress("Oracle");
        address[] memory assets = new address[](1);
        address[] memory sources = new address[](1);
        
        vm.startBroadcast(deployerPrivateKey);

        assets[0] = vm.envAddress("USDT");
        sources[0] = vm.envAddress("USDT-BinanceAggregator");

        AaveOracle(oracle).setAssetSources(assets, sources);
        vm.stopBroadcast();
        
    }
}
