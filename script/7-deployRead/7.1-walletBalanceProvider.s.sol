// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/interfaces/IPoolConfigurator.sol";
import "../../src/periphery/misc/WalletBalanceProvider.sol";

contract deployWalletBalances is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");

        address wbnb = vm.envAddress("WBNB");

        vm.startBroadcast(deployerPrivateKey);

        new WalletBalanceProvider(provider, wbnb);
        
        vm.stopBroadcast();
    }
}
