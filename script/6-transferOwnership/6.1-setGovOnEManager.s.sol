// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/periphery/rewards/EmissionManager.sol";

contract UpdateGovForEmissionManager is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address manager = vm.envAddress("EmissionManager");
        address GOV = vm.envAddress("GOV");
        vm.startBroadcast(deployerPrivateKey);

        EmissionManager(manager).transferOwnership(GOV);

        vm.stopBroadcast();
    }
}
