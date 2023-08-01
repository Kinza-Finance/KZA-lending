// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/interfaces/IPoolConfigurator.sol";
import "../../src/periphery/misc/LiquidationAdaptorPancakeV3FallBack.sol";

contract deployLiquidationAdaptorPancakeV3Fallback is Script {
    struct Tmp {
        address hay;
        address btc;
        address usdc;
        address usdt;
        address busd;
        address tusd;
        address eth;
        address wbeth;
        address bnb;
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address V3Fallback = vm.envAddress("LiquidationAdaptorFallbackV3");

        Tmp memory tmp;
        tmp.hay = vm.envAddress("HAY_PROD");
        tmp.usdc = vm.envAddress("USDC_PROD");
        tmp.usdt = vm.envAddress("USDT_PROD");
        tmp.busd = vm.envAddress("BUSD_PROD");
        tmp.tusd = vm.envAddress("TUSD_PROD");
        tmp.eth = vm.envAddress("WETH_PROD");
        tmp.btc = vm.envAddress("BTCB_PROD");
        tmp.wbeth = vm.envAddress("WBETH_PROD");
        tmp.bnb = vm.envAddress("WBNB_PROD");

        vm.startBroadcast(deployerPrivateKey);

        // HAY => USDC
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.hay, tmp.usdc, 
        abi.encodePacked(tmp.hay, uint24(2500), tmp.bnb, uint24(500), tmp.busd, uint24(100), tmp.usdc));
        // HAY => USDT
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.hay, tmp.usdt,
            abi.encodePacked(tmp.hay, uint24(2500), tmp.bnb, uint24(500), tmp.usdt) );
        // HAY => BUSD
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.hay, tmp.busd,
            abi.encodePacked(tmp.hay, uint24(2500), tmp.bnb,  uint24(500), tmp.busd));
        // HAY => TUSD
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.hay, tmp.tusd, 
            abi.encodePacked(tmp.hay, uint24(2500), tmp.bnb,  uint24(500),  tmp.usdt, uint24(100), tmp.tusd));
        // HAY => ETH
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.hay, tmp.eth, 
            abi.encodePacked(tmp.hay, uint24(2500), tmp.eth) );
        // HAY => WBETH
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.hay, tmp.wbeth, 
            abi.encodePacked(tmp.hay, uint24(2500), tmp.eth, uint24(500), tmp.wbeth));
        // HAY => BTC
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.hay, tmp.btc, 
            abi.encodePacked(tmp.hay, uint24(2500), tmp.btc));
        // HAY => BNB
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.hay, tmp.bnb, 
            abi.encodePacked(tmp.hay, uint24(2500), tmp.bnb));

        // USDC => HAY
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.usdc, tmp.hay, 
            abi.encodePacked(tmp.usdc, uint24(100), tmp.busd, uint24(500), tmp.bnb, uint24(2500),  tmp.hay));
        // USDT => HAY
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.usdt, tmp.hay,
            abi.encodePacked(tmp.usdt, uint24(500), tmp.bnb, uint24(2500), tmp.hay));
        // BUSD => HAY
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.busd, tmp.hay,
            abi.encodePacked(tmp.busd, uint24(500), tmp.bnb, uint24(2500), tmp.hay));
        // TUSD => HAY
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.tusd, tmp.hay,
            abi.encodePacked(tmp.tusd, uint24(100), tmp.usdt, uint24(500), tmp.bnb, uint24(2500), tmp.hay));
        // ETH => HAY
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.eth, tmp.hay,
            abi.encodePacked(tmp.eth, uint24(2500), tmp.hay));
        // WBETH => HAY
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.wbeth, tmp.hay,
            abi.encodePacked(tmp.wbeth, uint24(500), tmp.eth, uint24(2500), tmp.hay));
        // BTC => HAY
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.btc, tmp.hay,
            abi.encodePacked(tmp.btc, uint24(2500), tmp.hay));
        // BNB => HAY
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.bnb, tmp.hay,
            abi.encodePacked(tmp.bnb, uint24(2500), tmp.hay));
        
        vm.stopBroadcast();
    }
}
