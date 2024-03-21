// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/protocol/tokenization/ATokenWombatStaker.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";
import "../../src/core/interfaces/IPool.sol";
import "../../src/core/interfaces/IAaveIncentivesController.sol";

contract DeployATokensImpl is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        vm.startBroadcast(deployerPrivateKey);

        IPool pool = IPool(IPoolAddressesProvider(provider).getPool());
        AToken atoken = new ATokenWombatStaker(pool);
        atoken.initialize(
            pool,
            address(0), // treasury
            address(0), // underlyingAsset
            IAaveIncentivesController(address(0)), // incentivesController
            0, // aTokenDecimals
            "ATOKEN_IMPL", // aTokenName
            "ATOKEN_IMPL", // aTokenSymbol
            "0x00" // param
        );

        vm.stopBroadcast();
    }
}
