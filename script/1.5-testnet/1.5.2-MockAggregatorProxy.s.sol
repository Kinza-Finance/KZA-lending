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
        string[] memory tokens = new string[](6);
        tokens[0] = "BUSD";
        tokens[1] = "USDC";
        tokens[2] = "USDT";
        tokens[3] = "WBTC";
        tokens[4] = "WETH";
        tokens[5] = "WBNB";

        uint256[] memory tokensPrice = new uint256[](6);
        tokensPrice[0] = 1e8;
        tokensPrice[1] = 1e8;
        tokensPrice[2] = 1e8;
        tokensPrice[3] = 28000 * 1e8;
        tokensPrice[4] = 1900 * 1e8;
        tokensPrice[5] = 311 * 1e8;
        address token;
        uint256 price;
        for (uint256 i; i < tokens.length; i++) {
                token = vm.envAddress(string(abi.encodePacked(tokens[i], "_TESTNET")));
                price = tokensPrice[i];
                new MockEACAggregatorProxy(tokens[0], token, int256(price));
            }

        vm.stopBroadcast();
    }
}
