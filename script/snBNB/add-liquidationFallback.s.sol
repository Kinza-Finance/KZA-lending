// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "forge-std/Script.sol";
import "../../src/core/interfaces/IPoolConfigurator.sol";
import "../../src/periphery/misc/LiquidationAdaptorPancakeV3FallBack.sol";

contract deployLiquidationAdaptorPancakeV3Fallback is Script {
    struct Tmp {
        address snbnb;
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
        tmp.snbnb = vm.envAddress("SNBNB");
        tmp.hay = vm.envAddress("HAY");
        tmp.usdc = vm.envAddress("USDC");
        tmp.usdt = vm.envAddress("USDT");
        tmp.busd = vm.envAddress("BUSD");
        tmp.tusd = vm.envAddress("TUSD");
        tmp.eth = vm.envAddress("WETH");
        tmp.btc = vm.envAddress("BTCB");
        tmp.wbeth = vm.envAddress("WBETH");
        tmp.bnb = vm.envAddress("WBNB");

        vm.startBroadcast(deployerPrivateKey);

        // snBNB => USDC
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.snbnb, tmp.usdc, 
        abi.encodePacked(tmp.snbnb, uint24(500), tmp.bnb, uint24(500), tmp.busd, uint24(100), tmp.usdc));
        // snBNB => USDT
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.snbnb, tmp.usdt,
            abi.encodePacked(tmp.snbnb, uint24(500), tmp.bnb, uint24(500), tmp.usdt) );
        // snBNB => BUSD
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.snbnb, tmp.busd,
            abi.encodePacked(tmp.snbnb, uint24(500), tmp.bnb,  uint24(500), tmp.busd));
        // snBNB => TUSD
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.snbnb, tmp.tusd, 
            abi.encodePacked(tmp.snbnb, uint24(500), tmp.bnb,  uint24(500),  tmp.usdt, uint24(100), tmp.tusd));
        // snBNB => ETH
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.snbnb, tmp.eth, 
            abi.encodePacked(tmp.snbnb, uint24(500), tmp.bnb, uint24(2500), tmp.eth));
        // snBNB => WBETH
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.snbnb, tmp.wbeth, 
            abi.encodePacked(tmp.snbnb, uint24(500), tmp.bnb, uint24(2500), tmp.eth, uint24(500), tmp.wbeth));
        // snBNB => BTC
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.snbnb, tmp.btc, 
            abi.encodePacked(tmp.snbnb, uint24(500), tmp.bnb, uint24(2500), tmp.btc));
        // snBNB => BNB
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.snbnb, tmp.bnb, 
            abi.encodePacked(tmp.snbnb, uint24(500), tmp.bnb));
        // snBNB => HAY
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.snbnb, tmp.hay, 
            abi.encodePacked(tmp.snbnb, uint24(500), tmp.bnb, uint24(2500), tmp.hay));

        // HAY => snBNB
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.hay, tmp.snbnb, 
            abi.encodePacked(tmp.hay, uint24(2500), tmp.bnb, uint24(500), tmp.snbnb));
        // USDC => snBNB
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.usdc, tmp.snbnb, 
            abi.encodePacked(tmp.usdc, uint24(100), tmp.busd, uint24(500), tmp.bnb, uint24(500),  tmp.snbnb));
        // USDT => snBNB
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.usdt, tmp.snbnb,
            abi.encodePacked(tmp.usdt, uint24(500), tmp.bnb, uint24(500), tmp.snbnb));
        // BUSD => snBNB
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.busd, tmp.snbnb,
            abi.encodePacked(tmp.busd, uint24(500), tmp.bnb, uint24(500), tmp.snbnb));
        // TUSD => snBNB
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.tusd, tmp.snbnb,
            abi.encodePacked(tmp.tusd, uint24(100), tmp.usdt, uint24(500), tmp.bnb, uint24(500), tmp.snbnb));
        // ETH => snBNB
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.eth, tmp.snbnb,
            abi.encodePacked(tmp.eth, uint24(500), tmp.bnb, uint24(2500), tmp.snbnb));
        // WBETH => snBNB
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.wbeth, tmp.snbnb,
            abi.encodePacked(tmp.wbeth, uint24(500), tmp.eth, uint24(2500), tmp.bnb, uint24(500), tmp.snbnb));
        // BTC => snBNB
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.btc, tmp.snbnb,
            abi.encodePacked(tmp.btc, uint24(2500), tmp.bnb, uint24(500), tmp.snbnb));
        // BNB => snBNB
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.bnb, tmp.snbnb,
            abi.encodePacked(tmp.bnb, uint24(500), tmp.snbnb));
        
        vm.stopBroadcast();
    }
}