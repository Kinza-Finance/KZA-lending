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
        address tusd;
        address eth;
        address wbeth;
        address wbnb;
        address snbnb;
        address fdusd;
    }
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address V3Fallback = 0x5fA0108775Dd5Af2D8c53C51279E4111d9b751cd;

        Tmp memory tmp;
        tmp.hay = 0x0782b6d8c4551B9760e74c0545a9bCD90bdc41E5;
        tmp.usdc = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
        tmp.usdt = 0x55d398326f99059fF775485246999027B3197955;
        tmp.snbnb = 0xB0b84D294e0C75A6abe60171b70edEb2EFd14A1B;
        tmp.tusd = 0x40af3827F39D0EAcBF4A168f8D4ee67c121D11c9;
        tmp.eth = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
        tmp.btc = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
        tmp.wbeth = 0xa2E3356610840701BDf5611a53974510Ae27E2e1;
        tmp.wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        tmp.fdusd = 0xc5f0f7b66764F6ec8C8Dff7BA683102295E16409;

        vm.startBroadcast(deployerPrivateKey);

        // HAY => USDC
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.fdusd, tmp.usdc, 
        abi.encodePacked(tmp.fdusd, uint24(100), tmp.usdt, uint24(100), tmp.usdc));
        // HAY => USDT
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.fdusd, tmp.usdt,
            abi.encodePacked(tmp.fdusd, uint24(100), tmp.usdt));
        // HAY => TUSD
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.fdusd, tmp.tusd, 
            abi.encodePacked(tmp.fdusd, uint24(100),  tmp.usdt, uint24(100), tmp.tusd));
        // HAY => ETH
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.fdusd, tmp.eth, 
            abi.encodePacked(tmp.fdusd, uint24(100),  tmp.usdt, uint24(500), tmp.wbnb, uint24(500), tmp.eth) );
        // HAY => WBETH
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.fdusd, tmp.wbeth, 
            abi.encodePacked(tmp.fdusd, uint24(100),  tmp.usdt, uint24(500), tmp.wbnb, uint24(500), tmp.eth, uint24(500), tmp.wbeth));
        // HAY => BTC
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.fdusd, tmp.btc, 
            abi.encodePacked(tmp.fdusd, uint24(100),  tmp.usdt, uint24(500), tmp.wbnb, uint24(2500), tmp.btc));
        // HAY => BNB
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.fdusd, tmp.wbnb, 
            abi.encodePacked(tmp.fdusd, uint24(100),  tmp.usdt, uint24(500), tmp.wbnb));

        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.fdusd, tmp.hay, 
            abi.encodePacked(tmp.fdusd, uint24(100),  tmp.usdt, uint24(500), tmp.hay));

        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.fdusd, tmp.snbnb, 
            abi.encodePacked(tmp.fdusd, uint24(100),  tmp.usdt, uint24(500), tmp.wbnb, uint24(500), tmp.snbnb));


        ///////////////
        
        // USDC => HAY
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.usdc, tmp.fdusd, 
            abi.encodePacked(tmp.usdc, uint24(100), tmp.usdt, uint24(100), tmp.fdusd));
        // USDT => HAY
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.usdt, tmp.fdusd,
            abi.encodePacked(tmp.usdt, uint24(100), tmp.fdusd));
        // TUSD => HAY
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.tusd, tmp.fdusd,
            abi.encodePacked(tmp.tusd, uint24(100), tmp.usdt, uint24(100), tmp.fdusd));
        // ETH => HAY
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.eth, tmp.fdusd,
            abi.encodePacked(tmp.eth, uint24(500), tmp.wbnb, uint24(500), tmp.usdt, uint24(100), tmp.fdusd));
        // WBETH => HAY
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.wbeth, tmp.fdusd,
            abi.encodePacked(tmp.wbeth, uint24(500), tmp.eth, uint24(500), tmp.wbnb, uint24(500), tmp.usdt, uint24(100), tmp.fdusd));
        // BTC => HAY
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.btc, tmp.fdusd,
            abi.encodePacked(tmp.btc, uint24(2500), tmp.wbnb, uint24(500), tmp.usdt, uint24(100), tmp.fdusd));
        // BNB => HAY
        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.wbnb, tmp.fdusd,
            abi.encodePacked(tmp.wbnb, uint24(500), tmp.usdt, uint24(100), tmp.fdusd));

        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.hay, tmp.fdusd,
            abi.encodePacked(tmp.hay, uint24(500), tmp.usdt, uint24(100), tmp.fdusd));

        LiquidationAdaptorPancakeV3FallBack(V3Fallback).updatePath(tmp.snbnb, tmp.fdusd,
            abi.encodePacked(tmp.snbnb, uint24(500), tmp.wbnb, uint24(500), tmp.usdt, uint24(100), tmp.fdusd));

        vm.stopBroadcast();
    }
}