// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/deployments/ATokenSetupHelperV2.sol";
import "../../src/core/protocol/configuration/ACLManager.sol";
// !!!! remember to bump up the AToken Version at the AToken contract, otherwise configurator would fail to initialize
contract setTreasuryUsingHelper is Script {
    function run() external {
        // Treasury can only be updated by updateATokenImpl / per asset 
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        address treasury = vm.envAddress("Treasury");
        vm.startBroadcast(deployerPrivateKey);
        ATokenSetupHelper helper = new ATokenSetupHelper();
        // make the helper a pool admin
        address[] memory tokens = new address(1);
        // update 1 by 1; HAY address for example 
        tokens[0] = 0x0782b6d8c4551B9760e74c0545a9bCD90bdc41E5;
        helper.updateATokensTreasury(provider, treasury, tokens);
        vm.stopBroadcast();
    }
}
