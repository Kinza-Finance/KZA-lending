// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";

interface Factory {
    function createPair(address token0, address token1) external returns (address);
}

interface Pair {
    function mint(address to) external;
}

interface Faucet {
    function mint(address token, address to, uint256 amount) external;
}


contract CreatePairs is Script {
    function run() external {
        uint256 govPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.envAddress("deployer");
        address factory = vm.envAddress("PANCAKE_FACTORY_TESTNET");
        address faucet = vm.envAddress("Faucet");
        bool deployed = true;
        vm.startBroadcast(govPrivateKey);
        address[] memory assets = new address[](6);
        assets[0] = vm.envAddress("BUSD_TESTNET");
        assets[1] = vm.envAddress("USDC_TESTNET");
        assets[2] = vm.envAddress("USDT_TESTNET");
        assets[3] = vm.envAddress("WBTC_TESTNET");
        assets[4] = vm.envAddress("WETH_TESTNET");
        assets[5] = vm.envAddress("WBNB_TESTNET_FAKE");
        
        if (!deployed) {
            // basically match each pool with WBNB, then pair them appropriately
            address BUSDBNB = Factory(factory).createPair(assets[0], assets[5]);
            address USDCBNB = Factory(factory).createPair(assets[1], assets[5]);
            address USDTBNB = Factory(factory).createPair(assets[2], assets[5]);
            address WBTCBNB = Factory(factory).createPair(assets[3], assets[5]);
            address WETHBNB = Factory(factory).createPair(assets[4], assets[5]);
        } else {
            address BUSDBNB = 0x20BeAdcf9EAa6201659680c00D33e3eA57BE9093;
            address USDCBNB = 0x11b987523BB7A3B4D457b0e016F92B5C108F1764;
            address USDTBNB = 0x10A384d507D52C0F37Cdf13eA768F8721A535F48;
            address WBTCBNB = 0x9a8F0c1b5c44Ae70Bf0CD57eD71794BddAa3E1fA;
            address WETHBNB = 0x5E3d6937Df8d3FD93f95722259A5A7f8dd394b7f;
            // send them the right amount, to represent the price for 1e15/ 10 BNB
            Faucet f = Faucet(faucet);
            f.mint(assets[0], BUSDBNB, 1e21 * 2.5);
            f.mint(assets[1], USDCBNB, 1e21 * 2.5);
            f.mint(assets[2], USDTBNB, 1e21 * 2.5);
            f.mint(assets[3], WBTCBNB, 1e17);
            // 1ETH = 6.6 BNB  | 10 BNB = 1.6 ETH
            f.mint(assets[4], WETHBNB, 1e18 * 1.6);
            // Then send 0.01 WBNB to all of them
            f.mint(assets[5], BUSDBNB, 1e19);
            f.mint(assets[5], USDCBNB, 1e19);
            f.mint(assets[5], USDTBNB, 1e19);
            f.mint(assets[5], WBTCBNB, 1e19);
            // 1ETH = 6.6 BNB  | 10 BNB = 1.6 ETH
            f.mint(assets[5], WETHBNB, 1e19);
            // create the pool and mint LP to deployer
            Pair(BUSDBNB).mint(deployer);
            Pair(USDCBNB).mint(deployer);
            Pair(USDTBNB).mint(deployer);
            Pair(WBTCBNB).mint(deployer);
            Pair(WETHBNB).mint(deployer);
        }
        
        
        vm.stopBroadcast();
    }
}