// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/misc/AaveOracle.sol";
import "../../src/core/misc/BinanceOracle/HAYBinanceOracleAggregator.sol";

contract InitBinanceOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        bool isProd = vm.envBool("isProd");
        address BSCTEST_SID_Registry = vm.envAddress("BSCTEST_SID_Registry");
        // address BSC_SID_Registry = vm.envAddress("BSC_SID_Registry");
        // address HAYTWAPAggregator = vm.envAddress("HAYTWAPAggregator");

        vm.startBroadcast(deployerPrivateKey);

        address SID_Registry;

        if (isProd) {
            // SID_Registry = BSC_SID_Registry;
        } else {
            SID_Registry = BSCTEST_SID_Registry;
        }

        require(SID_Registry != address(0));
        HAYBinanceOracleAggregator aggregator = new HAYBinanceOracleAggregator(SID_Registry);
        // aggregator.setTWAPAggregatorAddress(HAYTWAPAggregator);

        vm.stopBroadcast();
    }
}
