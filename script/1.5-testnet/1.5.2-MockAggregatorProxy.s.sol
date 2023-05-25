// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/mocks/oracle/MockEACAggregatorProxy.sol";

// lateest chainlink aggregator are of type "EACAggregatorProxy"
contract DeployMockAggregatorProxy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // the first one is a test aggregator deployed on mumbai
        // BUSD
        new MockEACAggregatorProxy("BUSD", address(0), 1e8);
        // USDC
        new MockEACAggregatorProxy("USDC", address(0), 1e8);
        // USDT
        new MockEACAggregatorProxy("USDT", address(0), 1e8);
        // WBTC
        new MockEACAggregatorProxy("WBTC", address(0), 27000 * 1e8);
        // WETH
        new MockEACAggregatorProxy("WETH", address(0), 1800 * 1e8);
        // WBNB
        new MockEACAggregatorProxy("WBNB", address(0), 304 * 1e8);

        vm.stopBroadcast();
    }
}
