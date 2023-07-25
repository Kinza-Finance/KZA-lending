// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/misc/AaveOracle.sol";
import "../../src/core/misc/BinanceOracle/HAYBinanceOracleAggregator.sol";
import "../../src/core/misc/BinanceOracle/WBETHBinanceOracleAggregator.sol";

contract InitBinanceOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        bool isProd = vm.envBool("isProd");
        address SID_Registry;
        if (isProd) {
            SID_Registry = vm.envAddress("BSC_SID_Registry");
        } else {
            SID_Registry = vm.envAddress("BSCTEST_SID_Registry");
        }

        vm.startBroadcast(deployerPrivateKey);

        require(SID_Registry != address(0));
        new HAYBinanceOracleAggregator(SID_Registry);
        new WBETHBinanceOracleAggregator(SID_Registry);
        // aggregator.setTWAPAggregatorAddress(HAYTWAPAggregator);

        vm.stopBroadcast();
    }
}
