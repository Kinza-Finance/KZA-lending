// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/misc/AaveOracle.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";

contract DeployOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        vm.startBroadcast(deployerPrivateKey);

        address[] memory assets;
        address[] memory sources;

        AaveOracle oracle = new AaveOracle(
                IPoolAddressesProvider(provider),
                assets,
                sources,
                address(0),
                address(0),
                1 * 1e8
        );

        IPoolAddressesProvider(provider).setPriceOracle(address(oracle));

        vm.stopBroadcast();
        
    }
}
