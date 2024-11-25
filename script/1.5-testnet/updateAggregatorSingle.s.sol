// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/mocks/oracle/MockEACAggregatorProxy.sol";

// lateest chainlink aggregator are of type "EACAggregatorProxy"
contract UpdateMockAggregatorProxy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("KEEPER_PRIVATE_KEY");

        string[] memory tokens = new string[](1);
        tokens[0] = "WBNB";
        vm.startBroadcast(deployerPrivateKey);

        for (uint i; i < tokens.length; ++i) {
            // make sure this is price in 1e8
            uint256 latest_price = 255 * 1e8;
            address aggregator = 0xa21728C737b24DC85568c129a937EEA601A67ebf;
            MockEACAggregatorProxy(aggregator).updateAnswer(int256(latest_price));
       }
       vm.stopBroadcast();
    }
}