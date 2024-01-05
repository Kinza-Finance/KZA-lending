// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/deployments/AtomicReservesSetupHelper.sol";

contract DeployAtomicHelper is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        new AtomicReservesSetupHelper();

        vm.stopBroadcast();
    }
}
