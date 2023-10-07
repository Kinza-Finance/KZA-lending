// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Foundation. All rights reserved.
pragma solidity > 0.8.0;

import { Test } from "forge-std/Test.sol";
import {IPoolAddressesProvider} from "../../src/core/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "../../src/core/interfaces/IPool.sol";
import {IAaveOracle} from "../../src/core/interfaces/IAaveOracle.sol";
import {IACLManager} from '../../src/core/interfaces/IACLManager.sol';
import {IAaveIncentivesController} from '../../src/core/interfaces/IAaveIncentivesController.sol';
import {IEmissionManager} from "../../src/periphery/rewards/interfaces/IEmissionManager.sol";

import {IPoolConfigurator} from "../../src/core/interfaces/IPoolConfigurator.sol";
import {IPoolDataProvider} from '../../src/core/interfaces/IPoolDataProvider.sol';
import {ReservesSetupHelper} from "../../src/core/deployments/ReservesSetupHelper.sol";

import {ADDRESSES_PROVIDER, POOLDATA_PROVIDER, ACL_MANAGER, POOL, POOL_CONFIGURATOR, EMISSION_MANAGER, 
        ATOKENIMPL, SDTOKENIMPL, VDTOKENIMPL, TREASURY, POOL_ADMIN, RESERVES_SETUP_HELPER, ORACLE, 
        SMART_HAY_LP} from "test/utils/AddressesTest.sol";

contract BaseTest is Test {
    // if forking is required at specific block, set this in sub-contract's setup before calling parent
    uint256 internal forkBlock;
    // the fork id to roll if needed
    uint256 internal mainnetFork;
    IPoolConfigurator internal configurator = IPoolConfigurator(POOL_CONFIGURATOR);
    IPool internal pool = IPool(POOL);
    IPoolAddressesProvider internal provider = IPoolAddressesProvider(ADDRESSES_PROVIDER);
    IPoolDataProvider internal dataProvider = IPoolDataProvider(POOLDATA_PROVIDER);
    IEmissionManager internal emissionManager = IEmissionManager(EMISSION_MANAGER);
    ReservesSetupHelper internal helper = ReservesSetupHelper(RESERVES_SETUP_HELPER);
    IACLManager internal aclManager = IACLManager(ACL_MANAGER);
    IAaveOracle internal oracle = IAaveOracle(ORACLE);
    function setUp() public virtual {
            fork();
        }

    function fork() internal {
        // BEFORE WE DO ANYTHING, FORK!!
        //uint256 mainnetFork;
        if (forkBlock == 0) {
            mainnetFork = vm.createFork(vm.envString("BSC_RPC_URL"));
        } else {
            mainnetFork = vm.createFork(vm.envString("BSC_RPC_URL"), forkBlock);
        }

        vm.selectFork(mainnetFork);
        assertEq(vm.activeFork(), mainnetFork, "forks don't match");
    }

}