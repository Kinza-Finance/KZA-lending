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
        IPoolDataProvider.TokenData[] memory reserves = IPoolDataProvider(dataprovider).getAllReservesTokens();
        string[] memory addressToAdd = new string[](2);
        addressToAdd[0] = "PUSDT";
        addressToAdd[1] = "USDT";
        uint256 newDebtCeiling;
        address token;
        for (uint256 j; j < addressToAdd.length; j++) {
            newDebtCeiling = vm.envUint(string(abi.encodePacked(addressToAdd[j], "_debtCeiling"))); // nominal, 2 decimals
            token = vm.envAddress(addressToAdd[i]);
            configurator.setDebtCeiling(token, newDebtCeiling);
        }
        
        vm.stopBroadcast();
    }
}
