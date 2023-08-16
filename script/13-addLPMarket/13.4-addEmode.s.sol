// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import "../../src/core/interfaces/IPoolConfigurator.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";
import "../../src/core/interfaces/IPoolDataProvider.sol";

contract setUpEmode is Script {
    function run() external {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        address dataprovider = vm.envAddress("PoolDataProvider");
        string memory token = "HAY";
        vm.startBroadcast(deployerPrivateKey);
        IPoolConfigurator configurator = IPoolConfigurator(IPoolAddressesProvider(provider).getPoolConfigurator());
        uint8 categoryId = 2;
        uint16 ltv = 9700;
        uint16 liquidationThreshold = 9750;
        uint16 liquidationBonus = 10100;
        // since wombat LP collected so little fee, we use the underlying price directlys
        address eModeAssetToFetchPrice = vm.envAddress(string(abi.encodePacked(token)));
        string memory label = string(abi.encodePacked("SMART_LP_", token));
        configurator.setEModeCategory(categoryId, ltv, liquidationThreshold, liquidationBonus, eModeAssetToFetchPrice, label);    
        string[] memory addressToAdd = new string[](2);
        addressToAdd[0] = token;
        addressToAdd[1] = string(abi.encodePacked("SMART_LP_", token));
        for (uint256 i; i < addressToAdd.length; i++) {
            address tokenAddress = vm.envAddress(string(abi.encodePacked(addressToAdd[i])));
            configurator.setAssetEModeCategory(tokenAddress, categoryId);
        }
        vm.stopBroadcast();
    }
}
