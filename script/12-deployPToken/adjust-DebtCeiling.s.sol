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
        address deployer = vm.envAddress("Deployer");
        vm.startBroadcast(deployer);

        IPoolConfigurator configurator = IPoolConfigurator(IPoolAddressesProvider(provider).getPoolConfigurator());
        IPoolDataProvider.TokenData[] memory reserves = IPoolDataProvider(dataprovider).getAllReservesTokens();
        string[] memory addressToAdd = new string[](2);
        addressToAdd[0] = "PUSDT";
        addressToAdd[1] = "USDT";
        uint256 newDebtCeiling;
        address token;
        for (uint256 j; j < addressToAdd.length; j++) {
            newDebtCeiling = vm.envUint(string(abi.encodePacked(addressToAdd[j], "_debtCeiling"))); // nominal, 2 decimals
            token = vm.envAddress(addressToAdd[j]);
            configurator.setDebtCeiling(token, newDebtCeiling);
        }
        
        vm.stopBroadcast();
    }
}
