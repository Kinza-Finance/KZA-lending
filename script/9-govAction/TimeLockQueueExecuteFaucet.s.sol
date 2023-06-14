// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/periphery/misc/TimelockController.sol";
import "../../src/periphery/mocks/testnet-helpers/Faucet.sol";
contract deployTimeLock is Script {
    function run() external {
        uint256 govPrivateKey = vm.envUint("PRIVATE_KEY");
        address timelock = vm.envAddress("TimeLock");
        address gov = vm.envAddress("GOV");
        address faucet = vm.envAddress("Faucet");
        address testnetBNB = vm.envAddress("WBNB_TESTNET");
        vm.startBroadcast(govPrivateKey);
        TimeLockController tl = TimelockController(payable(timelock));
        uint256 value = 0;
        // here we would like to mint some testnet BUSD to ourselves
        uint256 amountToMint = 1e18;        
        address to = timelock;
        address token = testnetBNB;
        address target = faucet;
        bytes memory data = abi.encodeWithSelector(Faucet.mint.selector, testnetBNB, to, amountToMint);
        bytes32 predecessor = 0x0;
        // salt can be any arbitrary number just to find a unique id during hash
        bytes32 salt = "0x123";
        // custom delay that has to be larger/equal to the minimum requirement
        uint256 delay = 4 hours;
        bytes32 hashId = tl.hashOperation(target, value, data, predecessor, salt);
        // if queued and ready, execute
        if (tl.isOperation(hashId) && tl.isOperationReady(hashId)) {
            tl.execute(target, value, data, predecessor, salt);
        // if not queued, queue it
        } else {
            tl.schedule(target, value, data, predecessor, salt, delay);
        }
        
        vm.stopBroadcast();
    }
}
