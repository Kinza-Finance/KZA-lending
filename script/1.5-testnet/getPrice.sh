#!/bin/bash
# this is for price in the testnet so we casually peg everything to USDT
#export KEEPER_PRIVATE_KEY=
WBTC_PRICE=$(curl "https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT" | jq -r '.price')
WETH_PRICE=$(curl "https://api.binance.com/api/v3/ticker/price?symbol=ETHUSDT" | jq -r '.price')
WBNB_PRICE=$(curl "https://api.binance.com/api/v3/ticker/price?symbol=BNBUSDT" | jq -r '.price')

USDC_PRICE=$(curl "https://api.binance.com/api/v3/ticker/price?symbol=USDCUSDT" | jq -r '.price')
BUSD_PRICE=$(curl "https://api.binance.com/api/v3/ticker/price?symbol=BUSDUSDT" | jq -r '.price')
USDT_PRICE=1
MULTIPLIER=100000000
# multiple and make integer
LATEST_WBTC_PRICE=$(echo "$WBTC_PRICE*$MULTIPLIER" | bc)
export LATEST_WBTC_PRICE=${LATEST_WBTC_PRICE%.*}

LATEST_WETH_PRICE=$(echo "$WETH_PRICE*$MULTIPLIER" | bc)
export LATEST_WETH_PRICE=${LATEST_WETH_PRICE%.*}

LATEST_WBNB_PRICE=$(echo "$WBNB_PRICE*$MULTIPLIER" | bc)
export LATEST_WBNB_PRICE=${LATEST_WBNB_PRICE%.*}

LATEST_BUSD_PRICE=$(echo "$BUSD_PRICE*$MULTIPLIER" | bc)
export LATEST_BUSD_PRICE=${LATEST_BUSD_PRICE%.*}

LATEST_USDC_PRICE=$(echo "$USDC_PRICE*$MULTIPLIER" | bc)
export LATEST_USDC_PRICE=${LATEST_USDC_PRICE%.*}

LATEST_USDT_PRICE=$(echo "$USDT_PRICE*$MULTIPLIER" | bc)
export LATEST_USDT_PRICE=${LATEST_USDT_PRICE%.*}
# replace the one in .env

~/.foundry/bin/forge script script/1.5-testnet/updateAggregator.s.sol --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545/ --broadcast
~/.foundry/bin/forge script script/1.5-testnet/updateAggregatorSingle.s.sol --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545/ --broadcast