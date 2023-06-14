// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/periphery/misc/TimelockController.sol";

contract deployTimeLock is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.envAddress("deployer");
        address gov = vm.envAddress("GOV");
        vm.startBroadcast(deployerPrivateKey);
        uint256 minDelay = 4 hours;
        address[] memory proposers = new address[](1);
        proposers[0] = gov;
        address[] memory executors = new address[](1);
        // this mean anyone can execute;
        executors[0] = address(0);
        address admin = deployer;
        new TimelockController(minDelay, proposers, executors, admin);
        
        vm.stopBroadcast();
    }
}
