// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/misc/AaveOracle.sol";
import "../../src/core/misc/BinanceOracle/SNBNBBinanceOracleAggregator.sol";

contract InitBinanceOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address SID_Registry = vm.envAddress("SID_Registry");
        address snbnb = vm.envAddress("SNBNB");
        address oracle = vm.envAddress("Oracle");

        vm.startBroadcast(deployerPrivateKey);

        require(SID_Registry != address(0));
        SNBNBBinanceOracleAggregator aggregator = new SNBNBBinanceOracleAggregator(SID_Registry);
        address[] memory assets = new address[](1);
        address[] memory sources = new address[](1);
        assets[0] = snbnb;
        sources[0] = address(aggregator);
        AaveOracle(oracle).setAssetSources(assets, sources);
        vm.stopBroadcast();
    }
}
