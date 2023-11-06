// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/interfaces/IPoolConfigurator.sol";
import "../../src/periphery/misc/LiquidationAdaptorPancakeV3FallBack.sol";

contract deployLiquidationAdaptorPancakeV3Fallback is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        new LiquidationAdaptorPancakeV3FallBack();
        
        vm.stopBroadcast();
    }
}
