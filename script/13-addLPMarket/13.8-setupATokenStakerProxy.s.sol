// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/protocol/tokenization/ATokenWombatStaker.sol";
import "../../src/core/interfaces/IPoolDataProvider.sol";

contract DeployATokensImpl is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address dataProvider = vm.envAddress("PoolDataProvider");
        address underlying = vm.envAddress("SMART_LP_HAY");
        address masterWombat = vm.envAddress("MasterWombat");
        address emissionAdmin = vm.envAddress("EmissionAdmin");
        vm.startBroadcast(deployerPrivateKey);

        (address ATokenProxyAddress,,) = IPoolDataProvider(dataProvider).getReserveTokensAddresses(underlying);
        ATokenWombatStaker(ATokenProxyAddress).updateEmissionAdmin(emissionAdmin);
        ATokenWombatStaker(ATokenProxyAddress).updateMasterWombat(masterWombat);
        vm.stopBroadcast();
    }
}
