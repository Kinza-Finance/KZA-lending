// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/periphery/misc/LiquidationAdaptor.sol";

contract ExecuteLiquidation is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address adaptorAddr = vm.envAddress("LiquidationAdaptor");
        vm.startBroadcast(deployerPrivateKey);

        LiquidationAdaptor adaptor = LiquidationAdaptor(adaptorAddr);

        address liquidated = 0x6358787B98202367F1fFb64c31A1F472FB6b5a95;
        address collateral = 0x004448093f9a9609B23B78c0FD39D3c432aFAb0B;
        address debtToken = 0x4FEc155A250922a9A16B3bDc84a5F855fcd67472;
        uint256 debtAmount = 10000;
        bytes memory param = "0x0";
        adaptor.liquidateWithFlashLoan(liquidated, collateral, debtToken, debtAmount);
        
        vm.stopBroadcast();
    }
}
