// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/interfaces/IPoolConfigurator.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";
import "../../src/core/interfaces/IPoolDataProvider.sol";

contract UnpausePool is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        address dataprovider = vm.envAddress("PoolDataProvider");
        vm.startBroadcast(deployerPrivateKey);

        IPoolConfigurator configurator = IPoolConfigurator(IPoolAddressesProvider(provider).getPoolConfigurator());
        bool enabled = false;
        IPoolDataProvider.TokenData[] memory reserves = IPoolDataProvider(dataprovider).getAllReservesTokens();
        for (uint256 i; i < reserves.length; i++) {
            address tokenAddress = reserves[i].tokenAddress;
            configurator.setReserveStableRateBorrowing(tokenAddress, enabled);
        }
        
        vm.stopBroadcast();
    }
}
