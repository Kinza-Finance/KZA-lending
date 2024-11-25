// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/periphery/mocks/testnet-helpers/TestnetERC20.sol";
import "../../src/periphery/mocks/testnet-helpers/Faucet.sol";

contract DeployMockTokens is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address GOV = vm.envAddress("GOV");
        vm.startBroadcast(deployerPrivateKey);
        // the first one is a test aggregator deployed on mumbai
        Faucet faucet = new Faucet(GOV, false);
        address f = address(faucet);
        // BUSD
        new TestnetERC20("BUSD", "BUSD", 18, f);
        // USDC
        new TestnetERC20("USDC", "USDC", 18, f);
        // USDT
        new TestnetERC20("USDT", "USDT", 18, f);
        // WBTC
        new TestnetERC20("WBTC", "WBTC", 18, f);
        // WETH
        new TestnetERC20("WETH", "WETH", 18, f);
        // WBNB
        new TestnetERC20("WBNB", "WBNB", 18, f);

        vm.stopBroadcast();
    }
}
