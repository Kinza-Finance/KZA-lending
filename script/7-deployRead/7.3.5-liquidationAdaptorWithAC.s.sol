// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/periphery/misc/AaveV2CrossTokenLiqAdatorAccessControl.sol";

contract deployLiquidationDataProvider is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        vm.startBroadcast(deployerPrivateKey);

        new AaveV2CrossTokenLiqAdatorAccessControl(provider);
        
        vm.stopBroadcast();
    }
}
