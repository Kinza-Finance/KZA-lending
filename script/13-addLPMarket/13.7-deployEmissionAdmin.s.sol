// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/interfaces/IPoolAddressesProvider.sol";
import "../../src/core/interfaces/IPoolDataProvider.sol";
import "../../src/core/interfaces/IPool.sol";
import "../../src/core/protocol/tokenization/EmissionAdminAndDirectTransferStrategy.sol";
import {IEmissionManager} from '../../src/periphery/rewards/interfaces/IEmissionManager.sol';
contract upgradePoolImpl is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address provider = vm.envAddress("PoolAddressesProvider");
        address dataProvider = vm.envAddress("PoolDataProvider");
        address emissionManager = vm.envAddress("EmissionManager");
        address underlying = vm.envAddress("SMART_LP_HAY");
        vm.startBroadcast(deployerPrivateKey);
        address pool = IPoolAddressesProvider(provider).getPool();
        EmissionAdminAndDirectTransferStrategy t = new EmissionAdminAndDirectTransferStrategy(
            IPool(pool), IEmissionManager(emissionManager)
        );
        (address ATokenProxyAddress,,) = IPoolDataProvider(dataProvider).getReserveTokensAddresses(underlying);
        t.toggleATokenWhitelist(IAToken(ATokenProxyAddress));
        vm.stopBroadcast();

    }
}