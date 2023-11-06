// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/protocol/configuration/ACLManager.sol";

contract RemoveDeployer is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.envAddress("deployer");
        address aclAddress = vm.envAddress("ACLManager");
        vm.startBroadcast(deployerPrivateKey);

        ACLManager acl = ACLManager(aclAddress);
        acl.removePoolAdmin(deployer);

        
        vm.stopBroadcast();
    }
}
