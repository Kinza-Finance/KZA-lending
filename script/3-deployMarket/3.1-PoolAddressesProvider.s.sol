// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/protocol/configuration/PoolAddressesProvider.sol";

contract DeployPoolAddressesProvider is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory marketID = vm.envString("MARKET_ID");
        address GOV = vm.envAddress("GOV");
        vm.startBroadcast(deployerPrivateKey);

        new PoolAddressesProvider(marketID, GOV);

        vm.stopBroadcast();
    }
}
