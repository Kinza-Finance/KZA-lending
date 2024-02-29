// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";
import "../../src/core/protocol/configuration/ACLManager.sol";
import "../../src/core/libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol";
// !!!! remember to bump up the AToken Version at the AToken contract, otherwise configurator would fail to initialize
contract setTreasuryUsingHelper is Script {
    function run() external {
        // Treasury can only be updated by updateATokenImpl / per asset 
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("Provider");
        address treasury = vm.envAddress("Treasury");
        vm.startBroadcast(deployerPrivateKey);
        bytes32 private constant DATA_PROVIDER = 'RESERVE_DISTRIBUTOR';
        ReserveDistributor impl = new ReserveDistributor();
        IPoolAddressProvider(provider).setAddressAsProxy(DATA_PROVIDER, impl);
        // impl does not matter, pass the provider
        vm.stopBroadcast();
    }
}
