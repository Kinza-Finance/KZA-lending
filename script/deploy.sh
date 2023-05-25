# !/bin/bash
export chainId=$MUMBAI_CHAINID
export RPC_URL=$MUMBAI_RPC_URL
export VERIFIER_URL=$MUMBAI_VERIFIER_URL
export ETHERSCAN_API_KEY=$MUMBAI_ETHERSCAN_API_KEY
export PRIVATE_KEY=$MUMBAI_PRIVATE_KEY
# 0 - PoolAddressesProviderRegistry
forge script script/0-PoolAddressesProviderRegistry.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
#source address of PoolAddressesProviderRegistry into env variable
PoolAddressesProviderRegistry=($(jq -r '.transactions[0].contractAddress' broadcast/0-PoolAddressesProviderRegistry.s.sol/${chainId}/run-latest.json))
echo "\n#deployment variables\nPoolAddressesProviderRegistry=$PoolAddressesProviderRegistry" >> ".env"

# 1 - Logics
# 1.1 Supply Logic
forge create src/contracts/protocol/libraries/logic/SupplyLogic.sol:SupplyLogic --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY  > log/SupplyLogic.txt
SupplyLogic=$(grep 'Deployed to: ' log/SupplyLogic.txt | awk '{print $3}')
echo "SupplyLogic=$SupplyLogic" >> ".env"
# 1.2 Borrow Logic
forge create src/contracts/protocol/libraries/logic/BorrowLogic.sol:BorrowLogic --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY  > log/BorrowLogic.txt
BorrowLogic=$(grep 'Deployed to: ' log/BorrowLogic.txt | awk '{print $3}')
echo "BorrowLogic=$BorrowLogic" >> ".env"
# 1.3 LiquidationLogic
forge create src/contracts/protocol/libraries/logic/LiquidationLogic.sol:LiquidationLogic --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY  > log/LiquidationLogic.txt
LiquidationLogic=$(grep 'Deployed to: ' log/LiquidationLogic.txt | awk '{print $3}')
echo "LiquidationLogic=$LiquidationLogic" >> ".env"
# 1.4 EmodeLogic
forge create src/contracts/protocol/libraries/logic/EModeLogic.sol:EModeLogic --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY  > log/EModeLogic.txt
EModeLogic=$(grep 'Deployed to: ' log/EModeLogic.txt | awk '{print $3}')
echo "EModeLogic=$EModeLogic" >> ".env"
# 1.5 BridgeLogic
forge create src/contracts/protocol/libraries/logic/BridgeLogic.sol:BridgeLogic --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY  > log/BridgeLogic.txt
BridgeLogic=$(grep 'Deployed to: ' log/BridgeLogic.txt | awk '{print $3}')
echo "BridgeLogic=$BridgeLogic" >> ".env"
# 1.6 ConfiguratorLogic
forge create src/contracts/protocol/libraries/logic/ConfiguratorLogic.sol:ConfiguratorLogic --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY  > log/ConfiguratorLogic.txt
ConfiguratorLogic=$(grep 'Deployed to: ' log/ConfiguratorLogic.txt | awk '{print $3}')
echo "ConfiguratorLogic=$ConfiguratorLogic" >> ".env"
# 1.7 FlashLoanLogic
forge create src/contracts/protocol/libraries/logic/FlashLoanLogic.sol:FlashLoanLogic --libraries src/contracts/protocol/libraries/logic/BorrowLogic.sol:BorrowLogic:$BorrowLogic  --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY > log/FlashLoanLogic.txt
FlashLoanLogic=$(grep 'Deployed to: ' log/FlashLoanLogic.txt | awk '{print $3}')
echo "FlashLoanLogic=$FlashLoanLogic" >> ".env"
# 1.8 PoolLogic
forge create src/contracts/protocol/libraries/logic/PoolLogic.sol:PoolLogic --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY  > log/PoolLogic.txt
PoolLogic=$(grep 'Deployed to: ' log/PoolLogic.txt | awk '{print $3}')
echo "PoolLogic=$PoolLogic" >> ".env"

# 1.5.1 deploy testnet token 
forge script script/1.5-testnet/1.5.1-MockToken.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
BUSD_TESTNET=($(jq -r '.transactions[1].contractAddress' broadcast/1.5.1-MockToken.s.sol/${chainId}/run-latest.json))
USDC_TESTNET=($(jq -r '.transactions[2].contractAddress' broadcast/1.5.1-MockToken.s.sol/${chainId}/run-latest.json))
USDT_TESTNET=($(jq -r '.transactions[3].contractAddress' broadcast/1.5.1-MockToken.s.sol/${chainId}/run-latest.json))
WBTC_TESTNET=($(jq -r '.transactions[4].contractAddress' broadcast/1.5.1-MockToken.s.sol/${chainId}/run-latest.json))
WETH_TESTNET=($(jq -r '.transactions[5].contractAddress' broadcast/1.5.1-MockToken.s.sol/${chainId}/run-latest.json))
WBNB_TESTNET=($(jq -r '.transactions[6].contractAddress' broadcast/1.5.1-MockToken.s.sol/${chainId}/run-latest.json))
echo "BUSD_TESTNET=$BUSD_TESTNET" >> ".env"
echo "USDC_TESTNET=$USDC_TESTNET" >> ".env"
echo "USDT_TESTNET=$USDT_TESTNET" >> ".env"
echo "WBTC_TESTNET=$WBTC_TESTNET" >> ".env"
echo "WETH_TESTNET=$WETH_TESTNET" >> ".env"
echo "WBNB_TESTNET=$WBNB_TESTNET" >> ".env"
# 1.5.2 deploy testnet aggregatorProxy
forge script script/1.5-testnet/1.5.2-MockAggregatorProxy.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
BUSD_AGGREGATOR_TESTNET=($(jq -r '.transactions[0].contractAddress' broadcast/1.5.2-MockAggregatorProxy.s.sol/${chainId}/run-latest.json))
USDC_AGGREGATOR_TESTNET=($(jq -r '.transactions[1].contractAddress' broadcast/1.5.2-MockAggregatorProxy.s.sol/${chainId}/run-latest.json))
USDT_AGGREGATOR_TESTNET=($(jq -r '.transactions[2].contractAddress' broadcast/1.5.2-MockAggregatorProxy.s.sol/${chainId}/run-latest.json))
WBTC_AGGREGATOR_TESTNET=($(jq -r '.transactions[3].contractAddress' broadcast/1.5.2-MockAggregatorProxy.s.sol/${chainId}/run-latest.json))
WETH_AGGREGATOR_TESTNET=($(jq -r '.transactions[4].contractAddress' broadcast/1.5.2-MockAggregatorProxy.s.sol/${chainId}/run-latest.json))
WBNB_AGGREGATOR_TESTNET=($(jq -r '.transactions[5].contractAddress' broadcast/1.5.2-MockAggregatorProxy.s.sol/${chainId}/run-latest.json))
echo "BUSD_AGGREGATOR_TESTNET=$BUSD_AGGREGATOR_TESTNET" >> ".env"
echo "USDC_AGGREGATOR_TESTNET=$USDC_AGGREGATOR_TESTNET" >> ".env"
echo "USDT_AGGREGATOR_TESTNET=$USDT_AGGREGATOR_TESTNET" >> ".env"
echo "WBTC_AGGREGATOR_TESTNET=$WBTC_AGGREGATOR_TESTNET" >> ".env"
echo "WETH_AGGREGATOR_TESTNET=$WETH_AGGREGATOR_TESTNET" >> ".env"
echo "WBNB_AGGREGATOR_TESTNET=$WBNB_AGGREGATOR_TESTNET" >> ".env"

#source address of PoolAddressesProviderRegistry into env variable
PoolAddressesProviderRegistry=($(jq -r '.transactions[0].contractAddress' broadcast/0-PoolAddressesProviderRegistry.s.sol/${chainId}/run-latest.json))
echo "\n#deployment variables\nPoolAddressesProviderRegistry=$PoolAddressesProviderRegistry" >> ".env"
# 2 Treasury Proxy

# 3.1 - PoolAddressesProvider
forge script script/3-deployMarket/3.1-PoolAddressesProvider.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
#source address of PoolAddressesProviderRegistry into env variable
PoolAddressesProvider=($(jq -r '.transactions[0].contractAddress' broadcast/3.1-PoolAddressesProvider.s.sol/${chainId}/run-latest.json))
echo "PoolAddressesProvider=$PoolAddressesProvider" >> ".env"
# 3.2 - Set PoolAddressesProvider into registry
forge script script/3-deployMarket/3.2-RegisterAddressProvider.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
#3.3 - deploy PoolDataProvider
forge script script/3-deployMarket/3.3-PoolDataProvider.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
echo "PoolDataProvider=$PoolDataProvider" >> ".env"