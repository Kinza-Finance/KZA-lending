// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";
import "../../src/core/protocol/pool/Pool.sol";
contract deployPoolImpl is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        vm.startBroadcast(deployerPrivateKey);
        Pool pool = new Pool(IPoolAddressesProvider(provider));
        pool.initialize(IPoolAddressesProvider(provider));
        vm.stopBroadcast();

    }
}