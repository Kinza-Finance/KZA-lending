// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/periphery/misc/AaveV2CrossTokenLiqAdatorAccessControl.sol";

contract deployLiquidationDataProvider is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        address v3Fallback = vm.envAddress("PancakeV3Fallback");
        vm.startBroadcast(deployerPrivateKey);

        AaveV2CrossTokenLiqAdatorAccessControl liq = new AaveV2CrossTokenLiqAdatorAccessControl(provider);
        liq.updateV3Fallback(v3Fallback);
        
        vm.stopBroadcast();
    }
}
