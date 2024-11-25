// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/deployments/ReservesSetupHelper.sol";
import "../../src/core/protocol/configuration/ACLManager.sol";
import "../../src/core/protocol/pool/PoolConfigurator.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";

contract setupRiskParameter is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        bool isProd = vm.envBool("isProd");
        address provider = vm.envAddress("PoolAddressesProvider");
        address aclAddress = vm.envAddress("ACLManager");
        address helperAddr = vm.envAddress("ReservesSetupHelper");
        vm.startBroadcast(deployerPrivateKey);

        ReservesSetupHelper helper = ReservesSetupHelper(helperAddr);
        //add helper to pool admin
        ACLManager acl = ACLManager(aclAddress);
        acl.addPoolAdmin(address(helper));

        PoolConfigurator configurator = PoolConfigurator(IPoolAddressesProvider(provider).getPoolConfigurator());
        ReservesSetupHelper.ConfigureReserveInput[] memory inputs = new ReservesSetupHelper.ConfigureReserveInput[](6);
        string[] memory tokens = new string[](6);
        tokens[0] = "BUSD";
        tokens[1] = "USDC";
        tokens[2] = "USDT";
        tokens[3] = "WBTC";
        tokens[4] = "WETH";
        tokens[5] = "WBNB";

        address token;
        for (uint256 i; i < tokens.length; i++) {
            if (isProd) {
                token = vm.envAddress(string(abi.encodePacked(tokens[i], "_PROD")));
            } else {
                token = vm.envAddress(string(abi.encodePacked(tokens[i], "_TESTNET")));
            }

            inputs[i] = ReservesSetupHelper.ConfigureReserveInput(
                token,
                vm.envUint(string(abi.encodePacked(tokens[i], "_baseLTV"))),
                vm.envUint(string(abi.encodePacked(tokens[i], "_liquidationThreshold"))),
                vm.envUint(string(abi.encodePacked(tokens[i], "_liquidationBonus"))),
                vm.envUint(string(abi.encodePacked(tokens[i], "_reserveFactor"))),
                vm.envUint(string(abi.encodePacked(tokens[i], "_borrowCap"))),
                vm.envUint(string(abi.encodePacked(tokens[i], "_supplyCap"))),
                vm.envBool(string(abi.encodePacked(tokens[i], "_stableBorrowingEnabled"))),
                vm.envBool(string(abi.encodePacked(tokens[i], "_borrowingEnabled"))),
                vm.envBool(string(abi.encodePacked(tokens[i], "_flashLoanEnabled")))
                );
        }

        helper.configureReserves(configurator, inputs);

        //remove helper from pool admin
        acl.removePoolAdmin(address(helper));
        vm.stopBroadcast();
    }
}
