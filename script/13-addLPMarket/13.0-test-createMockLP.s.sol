// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/periphery/mocks/testnet-helpers/TestnetERC20.sol";
import "../../src/periphery/mocks/testnet-helpers/Faucet.sol";

contract DeployMockTokens is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address f = vm.envAddress("Faucet");
        vm.startBroadcast(deployerPrivateKey);
        // the first one is a test aggregator deployed on mumbai
        // LP-USDT
        new TestnetERC20("Wombat Tether Stablecoin Asset", "LP-USDT", 18, f);
        // LP-USDC
        new TestnetERC20("Wombat USDC Coin Asset", "LP-USDC", 18, f);
        // LP-HAY
        new TestnetERC20("Wombat Hay Stablecoin Asset", "LP-HAY", 18, f);

        vm.stopBroadcast();
    }
}
