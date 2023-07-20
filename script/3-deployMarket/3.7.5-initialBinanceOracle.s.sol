// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/misc/BinanceOracle/WBETHBinanceOracleAggregator.sol";

contract InitBinanceOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        bool isProd = vm.envBool("isProd");
        
        vm.startBroadcast(deployerPrivateKey);
        address ChainlinkAggregator;
        address SID_Registry;

        if (isProd) {
            SID_Registry = vm.envAddress("BSC_SID_Registry");
            ChainlinkAggregator = vm.envAddress("WBETH_AGGREGATOR_PROD");
        } else {
            SID_Registry = vm.envAddress("BSCTEST_SID_Registry");
            ChainlinkAggregator = vm.envAddress("WBETH_AGGREGATOR_TESTNET");
        }

        require(SID_Registry != address(0));
        new WBETHBinanceOracleAggregator(SID_Registry, ChainlinkAggregator);
        // aggregator.setTWAPAggregatorAddress(HAYTWAPAggregator);

        vm.stopBroadcast();
    }
}