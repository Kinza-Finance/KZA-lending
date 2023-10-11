// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";
import "../../src/periphery/misc/WrappedTokenGatewayV3.sol";

contract deployGateway is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        address gov = 0xCCB8F7Cb8C49aB596E6F0EdDCEd3d3A6B1912c92;
        address WBNB = 0x4200000000000000000000000000000000000006;
        
        vm.startBroadcast(deployerPrivateKey);

        address pool = IPoolAddressesProvider(provider).getPool();
        new WrappedTokenGatewayV3(WBNB, gov, IPool(pool));
        
        vm.stopBroadcast();
    }
}