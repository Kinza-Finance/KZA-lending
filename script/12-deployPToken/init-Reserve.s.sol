// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import "../../src/core/protocol/pool/DefaultReserveInterestRateStrategy.sol";
import "../../src/core/interfaces/IPoolConfigurator.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";
import "../../src/core/protocol/libraries/types/ConfiguratorInputTypes.sol";
contract InitReserve is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        address treasury = vm.envAddress("Treasury");
        address aTokenImpl = vm.envAddress("ATokenImpl");
        address sdTokenImpl = vm.envAddress("sdTokenImpl");
        address vdTokenImpl = vm.envAddress("vdTokenImpl");
        vm.startBroadcast(deployerPrivateKey);
        IPoolConfigurator configurator = IPoolConfigurator(IPoolAddressesProvider(provider).getPoolConfigurator());
        bytes32 incentivesControllerId = 0x703c2c8634bed68d98c029c18f310e7f7ec0e5d6342c590190b3cb8b3ba54532;
        address incentivesController = IPoolAddressesProvider(provider).getAddress(incentivesControllerId);

        string[] memory tokens = new string[](1);
        tokens[0] = "PUSDT";

        ConfiguratorInputTypes.InitReserveInput[] memory inputs = new ConfiguratorInputTypes.InitReserveInput[](1);

        for (uint i; i < tokens.length; ++i) {
            DefaultReserveInterestRateStrategy interestRateStrategy = new DefaultReserveInterestRateStrategy(
                    IPoolAddressesProvider(provider),
                    vm.envUint(string(abi.encodePacked(tokens[i], "_optimalUsageRatio"))),
                    vm.envUint(string(abi.encodePacked(tokens[i], "_baseVariableBorrowRate"))),
                    vm.envUint(string(abi.encodePacked(tokens[i], "_variableRateSlope1"))),
                    vm.envUint(string(abi.encodePacked(tokens[i], "_variableRateSlope2"))),
                    vm.envUint(string(abi.encodePacked(tokens[i], "_stableRateSlope1"))),
                    vm.envUint(string(abi.encodePacked(tokens[i], "_stableRateSlope2"))),
                    vm.envUint(string(abi.encodePacked(tokens[i], "_baseStableRateOffset"))),
                    vm.envUint(string(abi.encodePacked(tokens[i], "_stableRateExcessOffset"))),
                    vm.envUint(string(abi.encodePacked(tokens[i], "_optimalStableToTotalDebtRatio")))
            );

            address interestRateStrategyAddress = address(interestRateStrategy);
            address token = vm.envAddress(string(abi.encodePacked(tokens[i])));
            uint8 decimals = IERC20Detailed(token).decimals();
            inputs[i] = ConfiguratorInputTypes.InitReserveInput(
                aTokenImpl,
                sdTokenImpl,
                vdTokenImpl,
                decimals,
                interestRateStrategyAddress,
                token,
                treasury,
                incentivesController,
                string(abi.encodePacked("Kinza", tokens[i])),
                string(abi.encodePacked("k", tokens[i])),
                string(abi.encodePacked("Kinza Variable Debt ", tokens[i])),
                string(abi.encodePacked("vDebt", tokens[i])),
                string(abi.encodePacked("Kinza Stable Debt ", tokens[i])),
                string(abi.encodePacked("sDebt", tokens[i])),
                abi.encodePacked("0x10")
                );
            
        }
        configurator.initReserves(inputs);   
    }
}