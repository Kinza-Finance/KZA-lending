// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract LiquidationAdaptorPancakeV3FallBack is Ownable {
    // intended for pancakeRouter
    // address constant public pancakeRouter = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4;

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
        
        // ETH => WBETH cross 0.05 V3 pool 
        callDataMap[keccak256(abi.encode(ETH, WBETH))] = 
        abi.encodePacked(ETH, uint24(500), WBETH);
        // ETH => BTC cross 0.3 V3 pool
        callDataMap[keccak256(abi.encode(ETH, BTC))] = 
        abi.encodePacked(ETH, uint24(2500), BTC);
        // ETH => BNB
        callDataMap[keccak256(abi.encode(ETH, WBNB))] = 
        abi.encodePacked(ETH, uint24(2500), WBNB);
        // ETH => USDT
        callDataMap[keccak256(abi.encode(ETH, USDT))] = 
        abi.encodePacked(ETH, uint24(500), USDC, uint24(100), USDT);
        // ETH => USDC
        callDataMap[keccak256(abi.encode(ETH, USDC))] = 
        abi.encodePacked(ETH, uint24(500), USDC);
        // ETH => BUSD
        callDataMap[keccak256(abi.encode(ETH, BUSD))] = 
        abi.encodePacked(ETH, uint24(500), USDC, uint24(100), BUSD);
        // ETH => TUSD
        callDataMap[keccak256(abi.encode(ETH, TUSD))] = 
        abi.encodePacked(ETH, uint24(500), USDC, uint24(100), USDT, uint24(100), TUSD);

        // WBETH => ETH
        callDataMap[keccak256(abi.encode(WBETH, ETH))] = 
        abi.encodePacked(WBETH, uint24(500), ETH);
        // WBETH => BTC
        callDataMap[keccak256(abi.encode(WBETH, BTC))] = 
        abi.encodePacked(WBETH, uint24(500), ETH, uint24(2500), BTC);
        // WBETH => WBNB
        callDataMap[keccak256(abi.encode(WBETH, WBNB))] = 
        abi.encodePacked(WBETH, uint24(500), ETH, uint24(2500), WBNB);
        // WBETH => USDT
        callDataMap[keccak256(abi.encode(WBETH, USDT))] = 
        abi.encodePacked(WBETH, uint24(500), ETH, uint24(500), USDC, uint24(100), USDT);
        // WBETH => USDC
        callDataMap[keccak256(abi.encode(WBETH, USDC))] = 
        abi.encodePacked(WBETH, uint24(500), ETH, uint24(500), USDC);
        // WBETH => BUSD
        callDataMap[keccak256(abi.encode(WBETH, BUSD))] = 
        abi.encodePacked(WBETH, uint24(500), ETH, uint24(500), USDC, uint24(100), BUSD);
        // WBETH => TUSD
        callDataMap[keccak256(abi.encode(WBETH, USDC))] = 
        abi.encodePacked(WBETH, uint24(500), ETH, uint24(500), USDC, uint24(100), USDT, uint24(100), TUSD);

        // BTC => ETH
        callDataMap[keccak256(abi.encode(BTC, ETH))] = 
        abi.encodePacked(BTC, uint24(2500), ETH);
        // BTC => WBETH
        callDataMap[keccak256(abi.encode(BTC, WBETH))] = 
        abi.encodePacked(BTC, uint24(2500), ETH, uint24(500), WBETH);
        // BTC => BNB
        callDataMap[keccak256(abi.encode(BTC, WBNB))] = 
        abi.encodePacked(BTC, uint24(2500), WBNB);
        // BTC => USDT
        callDataMap[keccak256(abi.encode(BTC, USDT))] = 
        abi.encodePacked(BTC,  uint24(500), USDT);
        // BTC => USDC
        callDataMap[keccak256(abi.encode(BTC, USDC))] = 
        abi.encodePacked(BTC,  uint24(500), USDT, uint24(100), USDC);
        // BTC => BUSD
        callDataMap[keccak256(abi.encode(BTC, BUSD))] = 
        abi.encodePacked(BTC, uint24(500), BUSD);
        // BTC => TUSD
        callDataMap[keccak256(abi.encode(BTC, TUSD))] = 
        abi.encodePacked(BTC,  uint24(500), USDT, uint24(100), TUSD);

        // BNB => ETH
        callDataMap[keccak256(abi.encode(WBNB, ETH))] = 
        abi.encodePacked(WBNB,  uint24(2500), ETH);
        // BNB => WBETH
        callDataMap[keccak256(abi.encode(WBNB, WBETH))] = 
        abi.encodePacked(WBNB,  uint24(2500), ETH, uint24(500), WBETH);
        // BNB => BTC
        callDataMap[keccak256(abi.encode(WBNB, BTC))] = 
        abi.encodePacked(WBNB,  uint24(2500), BTC);
        // BNB => USDT
        callDataMap[keccak256(abi.encode(WBNB, USDT))] = 
        abi.encodePacked(WBNB,  uint24(500), USDT);
        // BNB => USDC
        callDataMap[keccak256(abi.encode(WBNB, USDC))] = 
        abi.encodePacked(WBNB,  uint24(500), BUSD, uint24(100), USDC);
        // BNB => BUSD
        callDataMap[keccak256(abi.encode(WBNB, BUSD))] = 
        abi.encodePacked(WBNB,  uint24(500), BUSD);
        // BNB => TUSD
        callDataMap[keccak256(abi.encode(WBNB, TUSD))] = 
        abi.encodePacked(WBNB,  uint24(500), USDT, uint24(100), TUSD);

        // USDT => ETH
        callDataMap[keccak256(abi.encode(USDT, ETH))] = 
        abi.encodePacked(USDT, uint24(100), USDC, uint24(500), ETH);
        // USDT => WBETH
        callDataMap[keccak256(abi.encode(USDT, WBETH))] = 
        abi.encodePacked(USDT, uint24(100), USDC, uint24(500), ETH, uint24(500), WBETH);
        // USDT => BNB
        callDataMap[keccak256(abi.encode(USDT, WBNB))] = 
        abi.encodePacked(USDT, uint24(500), WBNB);
        // USDT => BTC
        callDataMap[keccak256(abi.encode(USDT, BTC))] = 
        abi.encodePacked(USDT, uint24(500), BTC);
        // USDT => USDC
        callDataMap[keccak256(abi.encode(USDT, USDC))] = 
        abi.encodePacked(USDT, uint24(100), USDC);
        // USDT => BUSD
        callDataMap[keccak256(abi.encode(USDT, BUSD))] = 
        abi.encodePacked(USDT, uint24(100), BUSD);
        // USDT => TUSD
        callDataMap[keccak256(abi.encode(USDT, TUSD))] = 
        abi.encodePacked(USDT, uint24(100), TUSD);

        // USDC => ETH
        callDataMap[keccak256(abi.encode(USDC, ETH))] = 
        abi.encodePacked(USDC, uint24(500), ETH);
        // USDC => WBETH
        callDataMap[keccak256(abi.encode(USDC, WBETH))] = 
        abi.encodePacked(USDC, uint24(500), ETH, uint24(500), WBETH);
        // USDC => BNB
        callDataMap[keccak256(abi.encode(USDC, WBNB))] = 
        abi.encodePacked(USDC, uint24(100), BUSD, uint24(500), WBNB);
        // USDC => USDT
        callDataMap[keccak256(abi.encode(USDC, USDT))] = 
        abi.encodePacked(USDC, uint24(100), ETH);
        // USDC => BTC
        callDataMap[keccak256(abi.encode(USDC, BTC))] = 
        abi.encodePacked(USDC, uint24(100), USDT, uint24(500), BTC);
        // USDC => BUSD
        callDataMap[keccak256(abi.encode(USDC, BUSD))] = 
        abi.encodePacked(USDC, uint24(100), BUSD);
        // USDC => TUSD
        callDataMap[keccak256(abi.encode(USDC, TUSD))] = 
        abi.encodePacked(USDC, uint24(100), USDT, uint24(100), TUSD);

        // BUSD => ETH
        callDataMap[keccak256(abi.encode(BUSD, ETH))] = 
        abi.encodePacked(BUSD, uint24(100), USDC, uint24(500), ETH);
        // BUSD => WBETH
        callDataMap[keccak256(abi.encode(BUSD, WBETH))] = 
        abi.encodePacked(BUSD, uint24(100), USDC, uint24(500), ETH, uint24(500), WBETH);
        // BUSD => BNB
        callDataMap[keccak256(abi.encode(BUSD, WBNB))] = 
        abi.encodePacked(BUSD, uint24(500), WBNB);
        // BUSD => USDT
        callDataMap[keccak256(abi.encode(BUSD, USDT))] = 
        abi.encodePacked(BUSD, uint24(100), USDT);
        // BUSD => USDC
        callDataMap[keccak256(abi.encode(BUSD, USDC))] = 
        abi.encodePacked(BUSD, uint24(100), USDC);
        // BUSD => BTC
        callDataMap[keccak256(abi.encode(BUSD, BTC))] = 
        abi.encodePacked(BUSD, uint24(500), BTC);
        // BUSD => TUSD
        callDataMap[keccak256(abi.encode(BUSD, TUSD))] = 
        abi.encodePacked(BUSD, uint24(100), USDT, uint24(100), TUSD);

        // TUSD => ETH
        callDataMap[keccak256(abi.encode(TUSD, ETH))] = 
        abi.encodePacked(TUSD, uint24(100), USDT, uint24(100), USDC, uint24(500), ETH);
        // TUSD => WBETH
        callDataMap[keccak256(abi.encode(TUSD, ETH))] = 
        abi.encodePacked(TUSD, uint24(100), USDT, uint24(100), USDC, uint24(500), ETH, uint24(500), WBETH);
        // TUSD => BNB
        callDataMap[keccak256(abi.encode(TUSD, WBNB))] = 
        abi.encodePacked(TUSD, uint24(100), USDT, uint24(500), WBNB);
        // TUSD => USDT
        callDataMap[keccak256(abi.encode(TUSD, USDT))] = 
        abi.encodePacked(TUSD, uint24(100), USDT);
        // TUSD => USDC
        callDataMap[keccak256(abi.encode(TUSD, USDC))] = 
        abi.encodePacked(TUSD, uint24(100), USDT, uint24(100), USDC);
        // TUSD => BTC
        callDataMap[keccak256(abi.encode(TUSD, BTC))] = 
        abi.encodePacked(TUSD, uint24(100), USDT, uint24(500), BTC);
        // TUSD => BUSD
        callDataMap[keccak256(abi.encode(TUSD, BUSD))] = 
        abi.encodePacked(TUSD, uint24(100), USDT, uint24(100), BUSD);
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