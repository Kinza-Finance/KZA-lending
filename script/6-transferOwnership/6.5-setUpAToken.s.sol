// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/protocol/tokenization/AToken.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";
import "../../src/core/interfaces/IPool.sol";
import "../../src/core/interfaces/IPoolConfigurator.sol";
import "../../src/core/interfaces/IPoolDataProvider.sol";
import "../../src/core/interfaces/IAaveIncentivesController.sol";
import "../../src/core/dependencies/openzeppelin/contracts/IERC20Detailed.sol";

// !!!! remember to bump up the AToken Version at the AToken contract, otherwise configurator would fail to initialize
contract setTreasury is Script {
    function run() external {
        // Treasury can only be updated by updateATokenImpl / per asset 
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        address treasury = vm.envAddress("Treasury");
        vm.startBroadcast(deployerPrivateKey);

        IPool pool = IPool(IPoolAddressesProvider(provider).getPool());
        IPoolConfigurator configurator = IPoolConfigurator(IPoolAddressesProvider(provider).getPoolConfigurator());
        IPoolDataProvider dataProvider = IPoolDataProvider(IPoolAddressesProvider(provider).getPoolDataProvider());

        bytes32 incentivesControllerId = 0x703c2c8634bed68d98c029c18f310e7f7ec0e5d6342c590190b3cb8b3ba54532;
        address controllerProxy = IPoolAddressesProvider(provider).getAddress(incentivesControllerId);

        IPoolDataProvider.TokenData[] memory reserves = dataProvider.getAllReservesTokens();
        // deploy new aToken first, then initialize it with new parameter
        AToken atoken = new AToken(pool);
        ConfiguratorInputTypes.UpdateATokenInput memory input;
        for (uint i;i< reserves.length;i++) {
            address tokenAddress = reserves[i].tokenAddress;
            input.asset = tokenAddress;
            input.treasury = treasury;
            input.incentivesController = controllerProxy;
            input.name = string(abi.encodePacked("asset", IERC20Detailed(tokenAddress).name()));
            input.symbol = string(abi.encodePacked("a", IERC20Detailed(tokenAddress).symbol()));
            input.implementation = address(atoken);
            input.params = abi.encodePacked("0x10");
            configurator.updateAToken(input);
            }
        // initialize the impl itself @TODO verify if this is needed
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
