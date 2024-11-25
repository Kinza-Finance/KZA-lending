// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/mocks/oracle/MockEACAggregatorProxy.sol";

// lateest chainlink aggregator are of type "EACAggregatorProxy"
contract UpdateMockAggregatorProxy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("KEEPER_PRIVATE_KEY");

        string[] memory tokens = new string[](6);
        tokens[0] = "BUSD";
        tokens[1] = "USDC";
        tokens[2] = "USDT";
        tokens[3] = "WBTC";
        tokens[4] = "WETH";
        tokens[5] = "WBNB";
        vm.startBroadcast(deployerPrivateKey);

        for (uint i; i < tokens.length; ++i) {
            // make sure this is price in 1e8
            uint256 latest_price = vm.envUint(string(abi.encodePacked("LATEST_", tokens[i], "_PRICE")));
            address aggregator = vm.envAddress(string(abi.encodePacked(tokens[i], "_AGGREGATOR_TESTNET")));
            MockEACAggregatorProxy(aggregator).updateAnswer(int256(latest_price));
       }
       vm.stopBroadcast();
    }
}