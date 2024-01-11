// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/interfaces/IPoolConfigurator.sol";
import "../../src/periphery/misc/ThenaLiqAdaptorAccessControl.sol";
import "../../src/periphery/misc/ThenaRouterV2Path.sol";

contract deployLiquidationAdaptorPancakeV3Fallback is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address ADDRESSES_PROVIDER = 0x993E9A7E2dEC99b86F982deb0f37ade278949fa4;
        ThenaLiqAdaptorAccessControl liqAdaptor = new ThenaLiqAdaptorAccessControl(ADDRESSES_PROVIDER);
        ThenaRouterV2Path V2FallBack = new ThenaRouterV2Path();
        liqAdaptor.updateV2Fallback(address(V2FallBack));
        vm.stopBroadcast();
    }
}    