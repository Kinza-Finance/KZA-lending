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
        uint256 deployerPrivateKey;
        bool isProd = vm.envBool("isProd");
        if (isProd) {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY_TESTNET");
        }
        vm.startBroadcast(deployerPrivateKey);

        IPoolConfigurator configurator = IPoolConfigurator(IPoolAddressesProvider(provider).getPoolConfigurator());
        string[] memory addressToAdd = new string[](2);
        addressToAdjust[0] = "USDT";
        addressToAdjust[1] = "USDC";
        for (uint256 j; j < addressToAdjust.length; j++) {
            uint256 newBorrowCap = vm.envUint(string(abi.encodePacked(addressToAdd[j], "_borrowCap"))); // nominal, 2 decimals
            uint256 newSupplyCap = vm.envUint(string(abi.encodePacked(addressToAdd[j], "_supplyCap"))); // nominal, 2 decimals
            token = vm.envAddress(addressToAdjust[i]);
            configurator.setBorrowCap(asset, newBorrowCap);
            configurator.setSupplyCap(asset, newSupplyCap);

        }
        
        vm.stopBroadcast();
    }
}
