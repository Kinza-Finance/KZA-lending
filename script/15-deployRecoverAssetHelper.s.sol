// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";
import "../../src/core/misc/RecoverAssetHelper.sol";
contract DeployRecoverAssetHelper is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new RecoverAssetHelper(0xCa20a50ea454Bd9F37a895182ff3309F251Fd7cE);
        vm.stopBroadcast();

    }
}