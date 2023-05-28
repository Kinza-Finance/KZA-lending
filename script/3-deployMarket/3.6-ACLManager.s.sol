// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/protocol/configuration/ACLManager.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";

contract DeployPoolConfiguratorImpl is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        address deployer = vm.envAddress("deployer");
        address aclAdmin = vm.envAddress("aclAdmin");
        address poolAdmin = vm.envAddress("poolAdmin");
        address emergencyAdmin = vm.envAddress("emergencyAdmin");
        vm.startBroadcast(deployerPrivateKey);

        IPoolAddressesProvider(provider).setACLAdmin(aclAdmin);

        ACLManager acl = new ACLManager(IPoolAddressesProvider(provider));

        IPoolAddressesProvider(provider).setACLManager(address(acl));
        acl.addPoolAdmin(poolAdmin);
        acl.addPoolAdmin(deployer);
        acl.addEmergencyAdmin(emergencyAdmin);
        vm.stopBroadcast();
    }
}
