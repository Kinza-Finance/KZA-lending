// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import "../../src/core/interfaces/IPoolConfigurator.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";
import "../../src/core/interfaces/IPoolDataProvider.sol";

contract setDebtCeiling is Script {
    function run() external {
        address provider = vm.envAddress("PoolAddressesProvider");
        address dataprovider = vm.envAddress("PoolDataProvider");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        IPoolConfigurator configurator = IPoolConfigurator(IPoolAddressesProvider(provider).getPoolConfigurator());
        IPoolDataProvider.TokenData[] memory reserves = IPoolDataProvider(dataprovider).getAllReservesTokens();
        string[] memory addressToAdd = new string[](1);
        addressToAdd[0] = "USDT";
        uint256 newDebtCeiling = 4000 * 1e2; // nominal, 2 decimals
        for (uint256 i; i < reserves.length; i++) {
            address tokenAddress = reserves[i].tokenAddress;
            for (uint256 j; j < addressToAdd.length; j++) {
                if (keccak256(abi.encodePacked(addressToAdd[j])) == keccak256(abi.encodePacked(IERC20Detailed(tokenAddress).symbol()))) {
                    configurator.setDebtCeiling(tokenAddress, newDebtCeiling);
                }
            }
        }
        
        vm.stopBroadcast();
    }
}
