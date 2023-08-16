// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/misc/WombatOracle/GenericLPFallbackOracle.sol";
import "../../src/core/dependencies/openzeppelin/contracts/IERC20Detailed.sol";
contract DeployGenericLPOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        //address underlying =  vm.envAddress("HAY");
        //address underlying_aggregator =  vm.envAddress("HAY_AGGREGATOR");
        vm.startBroadcast(deployerPrivateKey);
        //string memory description = string(abi.encodePacked(IERC20Detailed(underlying).symbol(), "-LP/USD"));
        new GenericLPFallbackOracle();

        vm.stopBroadcast();
    }
}