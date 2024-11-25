// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import "../../src/core/protocol/pool/DefaultReserveInterestRateStrategy.sol";
import "../../src/core/interfaces/IPoolConfigurator.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";
import "../../src/core/protocol/libraries/types/ConfiguratorInputTypes.sol";
contract InitNewRateStrategy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        bool isProd = vm.envBool("isProd");
        vm.startBroadcast(deployerPrivateKey);

        IPoolConfigurator configurator = IPoolConfigurator(IPoolAddressesProvider(provider).getPoolConfigurator());
        string[] memory tokens = new string[](1);
        tokens[0] = "USDC";
        tokens[1] = "BUSD";
        tokens[2] = "USDT";
        tokens[3] = "BTCB";
        tokens[4] = "WETH";
        tokens[5] = "WBNB";
        tokens[6] = "WETH";

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
            address token;
            if (isProd) {
                token = vm.envAddress(string(abi.encodePacked(tokens[i], "_PROD")));
            } else {
                token = vm.envAddress(string(abi.encodePacked(tokens[i], "_TESTNET")));
            }
            configurator.setReserveInterestRateStrategyAddress(token, interestRateStrategyAddress);
        }


    }
}
