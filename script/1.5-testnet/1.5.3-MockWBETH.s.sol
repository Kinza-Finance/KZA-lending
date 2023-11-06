// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/mocks/tokens/WBETHMocked.sol";

contract DeployMockWbETH is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
        vm.startBroadcast(deployerPrivateKey);
        // the first one is a test aggregator deployed on mumbai
        new WBETHMocked();

        vm.stopBroadcast();
    }
}
