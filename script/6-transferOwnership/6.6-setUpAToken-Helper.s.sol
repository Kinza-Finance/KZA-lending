// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/deployments/ATokenSetupHelper.sol";
import "../../src/core/protocol/configuration/ACLManager.sol";
// !!!! remember to bump up the AToken Version at the AToken contract, otherwise configurator would fail to initialize
contract setTreasuryUsingHelper is Script {
    function run() external {
        // Treasury can only be updated by updateATokenImpl / per asset 
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        address aclAddress = vm.envAddress("ACLManager");
        address treasury = vm.envAddress("Treasury");
        vm.startBroadcast(deployerPrivateKey);
        ATokenSetupHelper helper = new ATokenSetupHelper();
        ACLManager acl = ACLManager(aclAddress);
        acl.addPoolAdmin(address(helper));
        // make the helper a pool admin
        helper.updateATokensTreasury(provider, treasury);
        // remove the helper from pool admin
        acl.removePoolAdmin(address(helper));
        vm.stopBroadcast();
    }
}
