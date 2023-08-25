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
        string[] memory addressToAdjust = new string[](1);
        addressToAdjust[0] = "USDT";
        for (uint256 j; j < addressToAdjust.length; j++) {
            uint256 newBorrowCap = vm.envUint(string(abi.encodePacked(addressToAdjust[j], "_borrowCap"))); // nominal, 2 decimals
            uint256 newSupplyCap = vm.envUint(string(abi.encodePacked(addressToAdjust[j], "_supplyCap"))); // nominal, 2 decimals
            address token = vm.envAddress(addressToAdjust[j]);
            configurator.setBorrowCap(token, newBorrowCap);
            configurator.setSupplyCap(token, newSupplyCap);

        }
        
        vm.stopBroadcast();
    }
}
