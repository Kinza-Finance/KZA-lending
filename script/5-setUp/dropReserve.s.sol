// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/deployments/ReservesSetupHelper.sol";
import "../../src/core/protocol/configuration/ACLManager.sol";
import "../../src/core/protocol/pool/PoolConfigurator.sol";
import "../../src/core/protocol/pool/Pool.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";

contract dropReserve is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        bool isProd = false;
        address provider = vm.envAddress("PoolAddressesProvider");
        //address helperAddr = vm.envAddress("ReservesSetupHelper");
        vm.startBroadcast(deployerPrivateKey);
        //add helper to pool admin

        PoolConfigurator configurator = PoolConfigurator(IPoolAddressesProvider(provider).getPoolConfigurator());
        //Pool pool = Pool(IPoolAddressesProvider(provider).getPool());
        //pool.withdraw(0xd97cfD1A555160ee2d5b1D9f204E72De8006778e, 0.000000013961055884 * 1 ether, 0xa445BC34f142808c5dCB0A68679159CC7Ac58329);
        //address[] memory asset = new address[](1);
        //asset[0] = 0xd97cfD1A555160ee2d5b1D9f204E72De8006778e;
        //pool.mintToTreasury(asset);
        configurator.dropReserve(0xd97cfD1A555160ee2d5b1D9f204E72De8006778e);
        vm.stopBroadcast();
    }
}