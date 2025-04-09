// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/protocol/tokenization/AToken.sol";
import "../../src/core/protocol/tokenization/StableDebtToken.sol";
import "../../src/core/protocol/tokenization/VariableDebtToken.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";
import "../../src/core/interfaces/IPool.sol";
import "../../src/core/interfaces/IAaveIncentivesController.sol";

contract DeployTokensImpl is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        vm.startBroadcast(deployerPrivateKey);

        IPool pool = IPool(IPoolAddressesProvider(provider).getPool());
        AToken atoken = new AToken(pool);
        StableDebtToken sdtoken = new StableDebtToken(pool);
        VariableDebtToken vdtoken = new VariableDebtToken(pool);
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

        sdtoken.initialize(
            pool,
            address(0), // underlyingAsset
            IAaveIncentivesController(address(0)), // incentivesController
            0, // vdTokenDecimals
            "STALBE_DEBT_TOKEN_IMPL", // aTokenName
            "STALBE_DEBT_TOKEN_IMPL", // aTokenSymbol
            "0x00" // param
            );


        vdtoken.initialize(
            pool,
            address(0), // underlyingAsset
            IAaveIncentivesController(address(0)), // incentivesController
            0, // vdTokenDecimals
            "VARIABLE_DEBT_TOKEN_IMPL", // aTokenName
            "VARIABLE_DEBT_TOKEN_IMPL", // aTokenSymbol
            "0x00" // param
            );

        vm.stopBroadcast();
    }
}
