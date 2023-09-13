// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/misc/WombatOracle/SmartHayPoolOracle.sol";
import "../../src/core/dependencies/openzeppelin/contracts/IERC20Detailed.sol";
contract DeployLPOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address _lp = vm.envAddress("SMART_LP_HAY");
        address _hay =  vm.envAddress("HAY");
        address _usdc =  vm.envAddress("USDC");
        address _usdt =  vm.envAddress("USDT");
        address _usdcAggregator = vm.envAddress("USDC_AGGREGATOR");
        address _hayAggregator = vm.envAddress("HAY_AGGREGATOR");
        address _usdtAggregator = vm.envAddress("USDT_AGGREGATOR");


        //address underlying_aggregator =  vm.envAddress("HAY_AGGREGATOR");
        vm.startBroadcast(deployerPrivateKey);
        //string memory description = string(abi.encodePacked(IERC20Detailed(underlying).symbol(), "-LP/USD"));
        new SmartHayPoolOracle(_usdcAggregator, _usdtAggregator, _hayAggregator,
                _usdc, _usdt, _hay);

        vm.stopBroadcast();
    }
}