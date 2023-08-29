// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Foundation. All rights reserved.
pragma solidity > 0.8.0;

// solhint-disable max-states-count

import { Test } from "forge-std/Test.sol";
import {EmissionAdminAndDirectTransferStrategy} from "../../src/core/protocol/tokenization/EmissionAdminAndDirectTransferStrategy.sol";
import { ACL_MANAGER, POOL, POOL_CONFIGURATOR, EMISSION_MANAGER, 
        MASTER_MAGPIE, SMART_HAY_LP, WOMBAT_HELPER_SMART_HAY_LP} from "test/utils/Addresses.sol";



contract BaseTest is Test {
    // if forking is required at specific block, set this in sub-contract's setup before calling parent
    uint256 internal forkBlock;

    EmissionAdminAndDirectTransferStrategy public emissionAdmin;
    AToken public lp_hay_ATokenProxy;
    function setUp() public virtual {
            fork();

            EmissionAdminAndDirectTransferStrategy = new EmissionAdminAndDirectTransferStrategy(POOL, EMISSION_MANAGER);


        }

    function fork() internal {
        // BEFORE WE DO ANYTHING, FORK!!
        uint256 mainnetFork;
        if (forkBlock == 0) {
            mainnetFork = vm.createFork(vm.envString("BSC_RPC_URL"));
        } else {
            mainnetFork = vm.createFork(vm.envString("BSC_RPC_URL"), forkBlock);
        }

        vm.selectFork(mainnetFork);
        assertEq(vm.activeFork(), mainnetFork, "forks don't match");
    }
}