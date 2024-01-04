// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/misc/BinanceOracle/SNBNBBinanceOracleCustomAggregator.sol";

contract deployWbETHPriceAdaptor is Script {
    function run() external {
        uint256 deployerPrivateKey;
        address internalAgg = 0x49D06F90FE754cCD6Db78a27A5a69018aDd941dc;
        address sigRegistry = 0xfFB52185b56603e0fd71De9de4F6f902f05EEA23;
        int256 maxFallbackThreshold = 1e8 * 500;
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        new SNBNBBinanceOracleCustomAggregator(sigRegistry, internalAgg, maxFallbackThreshold);
        
        vm.stopBroadcast();
    }
}
