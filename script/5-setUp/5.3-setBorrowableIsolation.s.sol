// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import "../../src/core/interfaces/IPoolConfigurator.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";
import "../../src/core/interfaces/IPoolDataProvider.sol";

contract setIsolation is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        address dataprovider = vm.envAddress("PoolDataProvider");
        vm.startBroadcast(deployerPrivateKey);

        IPoolConfigurator configurator = IPoolConfigurator(IPoolAddressesProvider(provider).getPoolConfigurator());
        IPoolDataProvider.TokenData[] memory reserves = IPoolDataProvider(dataprovider).getAllReservesTokens();

        string[] memory addressToAdd = new string[](4);
        addressToAdd[0] = "USDT";
        addressToAdd[1] = "USDC";
        addressToAdd[2] = "BUSD";
        addressToAdd[3] = "TUSD";
        for (uint256 i; i < reserves.length; i++) {
            address tokenAddress = reserves[i].tokenAddress;
            for (uint256 j; j < addressToAdd.length; j++) {
                if (keccak256(abi.encodePacked(addressToAdd[j])) == keccak256(abi.encodePacked(IERC20Detailed(tokenAddress).symbol()))) {
                    configurator.setBorrowableInIsolation(tokenAddress, true);
                }
            }
        }
        
        vm.stopBroadcast();
    }
}
