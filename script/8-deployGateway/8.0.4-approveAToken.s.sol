// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/misc/AaveProtocolDataProvider.sol";
import "../../src/core/dependencies/openzeppelin/contracts/IERC20.sol";

contract deployWBNB is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("KEEPER_PRIVATE_KEY");
        address gateway = vm.envAddress("GATEWAY");
        address dataProvider = vm.envAddress("PoolDataProvider");
        address wbnb = vm.envAddress("WBNB_TESTNET_REAL");
        vm.startBroadcast(deployerPrivateKey);
        
        (address atoken,,) = AaveProtocolDataProvider(dataProvider).getReserveTokensAddresses(wbnb);
        IERC20(atoken).approve(gateway, type(uint256).max);
    }
}
