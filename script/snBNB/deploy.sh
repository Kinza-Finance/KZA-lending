#!/bin/bash
env=mainnet bash ./run-example.sh
# deploy snBNB oracle (binance oracle feed)
network=bsc forge script script/snBNB/deploy-binanceOralce.s.sol --rpc-url $network --broadcast --verify -vvvv
# add liquidation path for liquidation adaptor
network=bsc forge script script/snBNB/add-liquidationFallback.s.sol --rpc-url $network --broadcast --verify -vvvv
# onboard snBNB as a reserve
network=bsc forge script script/snBNB/init-Reserve.s.sol --rpc-url $network --broadcast --verify -vvvv
# onboard snBNB as an open collateral and borrowable
network=bsc forge script script/snBNB/setup-RiskParameter.s.sol --rpc-url $network --broadcast --verify -vvvv
# @TODO setup TWAPAggregator from a separate repo and add it to the binanceOracleAggregator (setTWAPAggregator)