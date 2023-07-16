// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract LiquidationAdaptorPancakeV2FallBack is Ownable {
    address constant public pancakeRouter = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4;

    address constant public ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address constant public WBETH = 0xa2E3356610840701BDf5611a53974510Ae27E2e1;
    address constant public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant public BTC = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address constant public USDT = 0x55d398326f99059fF775485246999027B3197955;
    address constant public BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address constant public USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address constant public TUSD = 0x40af3827F39D0EAcBF4A168f8D4ee67c121D11c9;

    mapping(bytes32 => bytes) public callDataMap;

    event NewPath(address _tokenIn, address _tokenOut, bytes path);

    // with 8 assets there are 56 path pre-computed
    constructor() {
        
        // ETH => WBETH NA
        // ETH => BTC
        callDataMap[keccak256(abi.encode(ETH, BTC))] = 
        abi.encodePacked(ETH, BTC);
        // ETH => BNB
        callDataMap[keccak256(abi.encode(ETH, WBNB))] = 
        abi.encodePacked(ETH, WBNB);
        // ETH => USDT
        callDataMap[keccak256(abi.encode(ETH, USDT))] = 
        abi.encodePacked(ETH, USDT);
        // ETH => USDC
        callDataMap[keccak256(abi.encode(ETH, USDT))] = 
        abi.encodePacked(ETH, USDC);
        // ETH => BUSD
        callDataMap[keccak256(abi.encode(ETH, USDT))] = 
        abi.encodePacked(ETH, USDT, BUSD);
        // the only TUSD liquidity pool is in V3
        // ETH => TUSD 

        // the only wbeth liquidity pool is in V3
        // WBETH => ETH
        // WBETH => BTC
        // WBETH => BNB
        // WBETH => USDT
        // WBETH => USDC
        // WBETH => BUSD
        // WBETH => TUSD

        // BTC => ETH
        callDataMap[keccak256(abi.encode(BTC, ETH))] = 
        abi.encodePacked(BTC, ETH);
        // BTC => WBETH
        // BTC => BNB
        callDataMap[keccak256(abi.encode(BTC, WBNB))] = 
        abi.encodePacked(BTC, WBNB);
        // BTC => USDT
        callDataMap[keccak256(abi.encode(BTC, USDT))] = 
        abi.encodePacked(BTC, USDT);
        // BTC => USDC
        callDataMap[keccak256(abi.encode(BTC, WBNB))] = 
        abi.encodePacked(BTC, USDT, USDC);
        // BTC => BUSD
        callDataMap[keccak256(abi.encode(BTC, BUSD))] = 
        abi.encodePacked(BTC, BUSD);
        // BTC => TUSD

        // BNB => ETH
        callDataMap[keccak256(abi.encode(WBNB, ETH))] = 
        abi.encodePacked(WBNB, ETH);
        // BNB => WBETH
        // BNB => BTC
        callDataMap[keccak256(abi.encode(WBNB, BTC))] = 
        abi.encodePacked(WBNB, ETH);
        // BNB => USDT
        callDataMap[keccak256(abi.encode(WBNB, USDT))] = 
        abi.encodePacked(WBNB, ETH);
        // BNB => USDC
        callDataMap[keccak256(abi.encode(WBNB, USDT, USDC))] = 
        abi.encodePacked(WBNB, ETH);
        // BNB => BUSD
        callDataMap[keccak256(abi.encode(WBNB, BUSD))] = 
        abi.encodePacked(WBNB, ETH);
        // BNB => TUSD

        // USDT => ETH
        callDataMap[keccak256(abi.encode(USDT, ETH))] = 
        abi.encodePacked(USDT, ETH);
        // USDT => WBETH
        // USDT => BNB
        callDataMap[keccak256(abi.encode(USDT, WBNB))] = 
        abi.encodePacked(USDT, WBNB);
        // USDT => BTC
        callDataMap[keccak256(abi.encode(USDT, BTC))] = 
        abi.encodePacked(USDT, BUSD, BTC);
        // USDT => USDC
        callDataMap[keccak256(abi.encode(USDT, USDC))] = 
        abi.encodePacked(USDT, USDC);
        // USDT => BUSD
        callDataMap[keccak256(abi.encode(USDT, BUSD))] = 
        abi.encodePacked(USDT, BUSD);
        // USDT => TUSD

        // USDC => ETH
        callDataMap[keccak256(abi.encode(USDC, ETH))] = 
        abi.encodePacked(USDC, ETH);
        // USDC => WBETH
        // USDC => BNB
        callDataMap[keccak256(abi.encode(USDC, WBNB))] = 
        abi.encodePacked(USDC, WBNB);
        // USDC => USDT
        callDataMap[keccak256(abi.encode(USDC, USDT))] = 
        abi.encodePacked(USDC, USDT);
        // USDC => BTC
        callDataMap[keccak256(abi.encode(USDC, BTC))] = 
        abi.encodePacked(USDC, USDT, BTC);
        // USDC => BUSD
        callDataMap[keccak256(abi.encode(USDC, USDT))] = 
        abi.encodePacked(USDC, BUSD);
        // USDC => TUSD

        // BUSD => ETH
        callDataMap[keccak256(abi.encode(BUSD, ETH))] = 
        abi.encodePacked(BUSD, USDT, ETH);
        // BUSD => WBETH
        // BUSD => BNB
        callDataMap[keccak256(abi.encode(BUSD, WBNB))] = 
        abi.encodePacked(BUSD, WBNB);
        // BUSD => USDT
        callDataMap[keccak256(abi.encode(BUSD, USDT))] = 
        abi.encodePacked(BUSD, USDT);
        // BUSD => USDC
        callDataMap[keccak256(abi.encode(BUSD, USDC))] = 
        abi.encodePacked(BUSD, USDC);
        // BUSD => BTC
        callDataMap[keccak256(abi.encode(BUSD, BTC))] = 
        abi.encodePacked(BUSD, BTC);
        // BUSD => TUSD

        // TUSD => ETH
        // TUSD => WBETH
        // TUSD => BNB
        // TUSD => USDT
        // TUSD => USDC
        // TUSD => BTC
        // TUSD => BUSD


    }
    // path that is generalized off-chain, it's a deterministic path to go pass
    function getPath(address _tokenIn, address _tokenOut) public view returns(bytes memory) {
        require(_tokenIn != _tokenOut);
        bytes32 hash = keccak256(abi.encode(_tokenIn, _tokenOut));
        return callDataMap[hash];
    }

    function updatePath(address _tokenIn, address _tokenOut, bytes memory newPath) external onlyOwner {
        require(_tokenIn != _tokenOut);
        bytes32 hash = keccak256(abi.encode(_tokenIn, _tokenOut));
        callDataMap[hash] = newPath;
        emit NewPath(_tokenIn, _tokenOut , newPath);
        
    }
}