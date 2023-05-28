// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/dependencies/openzeppelin/contracts/IERC20Detailed.sol";
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
        uint8 categoryId = 1;
        uint16 ltv = 9700;
        uint16 liquidationThreshold = 9750;
        uint16 liquidationBonus = 10100;
        address oracle = address(0);
        string memory label = "Stablecoins";
        configurator.setEModeCategory(categoryId, ltv, liquidationThreshold, liquidationBonus, oracle, label);

        IPoolDataProvider.TokenData[] memory reserves = IPoolDataProvider(dataprovider).getAllReservesTokens();
        string[] memory addressToAdd = new string[](3);
        addressToAdd[0] = "USDC";
        addressToAdd[1] = "USDT";
        addressToAdd[2] = "BUSD";
        for (uint256 i; i < reserves.length; i++) {
            address tokenAddress = reserves[i].tokenAddress;
            for (uint256 j; j < addressToAdd.length; j++) {
                if (keccak256(abi.encodePacked(addressToAdd[j])) == keccak256(abi.encodePacked(IERC20Detailed(tokenAddress).name()))) {
                    configurator.setAssetEModeCategory(tokenAddress, categoryId);
                }
            }
        }
        
        vm.stopBroadcast();
    }
}
