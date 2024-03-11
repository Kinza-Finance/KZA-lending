// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/misc/BinanceOracle/SNBNBBinanceOracleCustomAggregator.sol";

contract deployWbETHPriceAdaptor is Script {
    function run() external {
        uint256 deployerPrivateKey;
        address internalAgg = 0xd73D7f28EF7bA655f3095Bf6B0E2029eFC203e7F;
        address sigRegistry = 0x08CEd32a7f3eeC915Ba84415e9C07a7286977956;
        address twwapAgg = 0xDF377a331f37292abd6e024EB8cf680f3f47206d;
        int256 maxFallbackThreshold = 1e8 * 1000;
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        SNBNBBinanceOracleCustomAggregator c = new SNBNBBinanceOracleCustomAggregator(sigRegistry, internalAgg, maxFallbackThreshold);
        c.setTWAPAggregatorAddress(twwapAgg);
        
        vm.stopBroadcast();
    }
}
