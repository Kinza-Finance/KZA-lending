// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract LiquidationAdaptorPancakeV3FallBack is Ownable {
    // intended for pancakeRouter
    // address constant public pancakeRouter = 0x678Aa4bF4E210cf2166753e054d5b7c31cc7fa86;
    address constant public WBNB = 0x4200000000000000000000000000000000000006;
    address constant public BTC = 0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2;

    mapping(bytes32 => bytes) public callDataMap;

    event NewPath(address _tokenIn, address _tokenOut, bytes path);

    // with 8 assets there are 56 path pre-computed
    constructor() {
        // BTC => BNB
        callDataMap[keccak256(abi.encode(BTC, WBNB))] = 
        abi.encodePacked(BTC, uint24(2500), WBNB);

        // BNB => BTC
        callDataMap[keccak256(abi.encode(WBNB, BTC))] = 
        abi.encodePacked(WBNB,  uint24(2500), BTC);
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