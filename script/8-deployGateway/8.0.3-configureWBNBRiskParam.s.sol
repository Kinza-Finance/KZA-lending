// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/deployments/ReservesSetupHelper.sol";
import "../../src/core/protocol/configuration/ACLManager.sol";
import "../../src/core/protocol/pool/PoolConfigurator.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";

// please put in double gas since gas simulation on this tx is wrong
contract configureWBNBIntoRiskParam is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("KEEPER_PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        address aclAddress = vm.envAddress("ACLManager");
        address helperAddr = vm.envAddress("ReservesSetupHelper");
        vm.startBroadcast(deployerPrivateKey);

        // ReservesSetupHelper helper = new ReservesSetupHelper();
        //add helper to pool admin
        ReservesSetupHelper helper = ReservesSetupHelper(helperAddr);
        ACLManager acl = ACLManager(aclAddress);
        acl.addPoolAdmin(address(helper));

        PoolConfigurator configurator = PoolConfigurator(IPoolAddressesProvider(provider).getPoolConfigurator());
        ReservesSetupHelper.ConfigureReserveInput[] memory inputs = new ReservesSetupHelper.ConfigureReserveInput[](1);
        string[] memory tokens = new string[](1);
        tokens[0] = "WBNB";

        
        for (uint256 i; i < tokens.length; i++) {
            address token = vm.envAddress(string(abi.encodePacked(tokens[i], "_TESTNET_REAL")));

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
