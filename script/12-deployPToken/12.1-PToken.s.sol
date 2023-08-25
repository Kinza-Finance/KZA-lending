// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/periphery/pToken/ProtectedERC20.sol";

contract DeployProtectedERC20 is Script {
    function run() external {
        address deployer = vm.envAddress("Deployer");
        address token = vm.envAddress("USDT");
        //address token = vm.envAddress("USDT");
        vm.startBroadcast(deployer);
        string memory name = IERC20Metadata(token).name();
        string memory symbol = IERC20Metadata(token).symbol();
        new ProtectedERC20(token, name, symbol);

        vm.stopBroadcast();
    }
}
