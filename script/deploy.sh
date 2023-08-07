# !/bin/bash
if $isProd
then
export chainId=$BSC_CHAINID
export RPC_URL=$BSC_RPC_URL
export VERIFIER_URL=$BSC_VERIFIER_URL
export ETHERSCAN_API_KEY=$BSC_ETHERSCAN_API_KEY
else
export chainId=$BSCTEST_CHAINID
export RPC_URL=$BSCTEST_RPC_URL
export VERIFIER_URL=$BSCTEST_VERIFIER_URL
export ETHERSCAN_API_KEY=$BSCTEST_ETHERSCAN_API_KEY
fi

# # forge verify-contract \
#     --chain-id  $chainId \
#     --num-of-optimizations 200 \
#     --watch \
#     --constructor-args $(cast abi-encode "constructor(address)" $deployer) \
#     --etherscan-api-key $ETHERSCAN_API_KEY \
#     --compiler-version v0.8.10+commit.fc410830 \
#     0xb62afd0f911af3ae28fb69a3eee3292b67fa8345 \
#     src/core/protocol/configuration/PoolAddressesProviderRegistry.sol:PoolAddressesProviderRegistry

# 1 - Logics
# 1.1 Supply Logic
forge create src/core/protocol/libraries/logic/SupplyLogic.sol:SupplyLogic --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY  > log/SupplyLogic.txt
SupplyLogic=$(grep 'Deployed to: ' log/SupplyLogic.txt | awk '{print $3}')
echo "SupplyLogic=$SupplyLogic" >> ".env"
# 1.2 Borrow Logic
forge create src/core/protocol/libraries/logic/BorrowLogic.sol:BorrowLogic --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY  > log/BorrowLogic.txt
BorrowLogic=$(grep 'Deployed to: ' log/BorrowLogic.txt | awk '{print $3}')
echo "BorrowLogic=$BorrowLogic" >> ".env"
# 1.3 LiquidationLogic
forge create src/core/protocol/libraries/logic/LiquidationLogic.sol:LiquidationLogic --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY  > log/LiquidationLogic.txt
LiquidationLogic=$(grep 'Deployed to: ' log/LiquidationLogic.txt | awk '{print $3}')
echo "LiquidationLogic=$LiquidationLogic" >> ".env"
# 1.4 EmodeLogic
forge create src/core/protocol/libraries/logic/EModeLogic.sol:EModeLogic --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY  > log/EModeLogic.txt
EModeLogic=$(grep 'Deployed to: ' log/EModeLogic.txt | awk '{print $3}')
echo "EModeLogic=$EModeLogic" >> ".env"
# 1.5 BridgeLogic
forge create src/core/protocol/libraries/logic/BridgeLogic.sol:BridgeLogic --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY  > log/BridgeLogic.txt
BridgeLogic=$(grep 'Deployed to: ' log/BridgeLogic.txt | awk '{print $3}')
echo "BridgeLogic=$BridgeLogic" >> ".env"
# 1.6 ConfiguratorLogic
forge create src/core/protocol/libraries/logic/ConfiguratorLogic.sol:ConfiguratorLogic --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY  > log/ConfiguratorLogic.txt
ConfiguratorLogic=$(grep 'Deployed to: ' log/ConfiguratorLogic.txt | awk '{print $3}')
echo "ConfiguratorLogic=$ConfiguratorLogic" >> ".env"
# 1.7 FlashLoanLogic
forge create src/core/protocol/libraries/logic/FlashLoanLogic.sol:FlashLoanLogic --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY > log/FlashLoanLogic.txt
FlashLoanLogic=$(grep 'Deployed to: ' log/FlashLoanLogic.txt | awk '{print $3}')
echo "FlashLoanLogic=$FlashLoanLogic" >> ".env"
# 1.8 PoolLogic
forge create src/core/protocol/libraries/logic/PoolLogic.sol:PoolLogic --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY  > log/PoolLogic.txt
PoolLogic=$(grep 'Deployed to: ' log/PoolLogic.txt | awk '{print $3}')
echo "PoolLogic=$PoolLogic" >> ".env"

# 1.1.1 - PoolAddressesProviderRegistry -- POST LOGIC
forge script script/1.1.1-PoolAddressesProviderRegistry.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
#source address of PoolAddressesProviderRegistry into env variable
PoolAddressesProviderRegistry=($(jq -r '.transactions[0].contractAddress' broadcast/1.1.1-PoolAddressesProviderRegistry.s.sol/${chainId}/run-latest.json))
echo "\n#deployment variables\nPoolAddressesProviderRegistry=$PoolAddressesProviderRegistry" >> ".env"


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

forge script script/1.5-testnet/1.5.3-MockWBETH.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
WBETH=($(jq -r '.transactions[0].contractAddress' broadcast/1.5.3-MockWBETH.s.sol/${chainId}/run-latest.json))
echo "WBETH_TESTNET=$WBETH" >> ".env"

forge script script/1.5-testnet/updateAggregatorSingle.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
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
PoolDataProvider=($(jq -r '.transactions[0].contractAddress' broadcast/3.3-PoolDataProvider.s.sol/${chainId}/run-latest.json))
echo "PoolDataProvider=$PoolDataProvider" >> ".env"
#3.4 - deploy PoolImpl
forge script script/3-deployMarket/3.4-PoolImpl.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
PoolImpl=($(jq -r '.transactions[0].contractAddress' broadcast/3.4-PoolImpl.s.sol/${chainId}/run-latest.json))
echo "PoolImpl=$PoolImpl" >> ".env"
# 3.5 - deploy configuratorImpl
forge script script/3-deployMarket/3.5-PoolConfiguratorImpl.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
PoolConfiguratorImpl=($(jq -r '.transactions[0].contractAddress' broadcast/3.5-PoolConfiguratorImpl.s.sol/${chainId}/run-latest.json))
echo "PoolConfiguratorImpl=$PoolConfiguratorImpl" >> ".env"
# 3.6 - deploy ACL Manager
forge script script/3-deployMarket/3.6-ACLManager.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
ACLManager=($(jq -r '.transactions[1].contractAddress' broadcast/3.6-ACLManager.s.sol/${chainId}/run-latest.json))
echo "ACLManager=$ACLManager" >> ".env"
# 3.7 - deploy Oracle
forge script script/3-deployMarket/3.7-Oracle.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
Oracle=($(jq -r '.transactions[0].contractAddress' broadcast/3.7-Oracle.s.sol/${chainId}/run-latest.json))
echo "Oracle=$Oracle" >> ".env"
# 3.8 init oracle
forge script script/3-deployMarket/3.8-InitOracle.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
# 3.9 init pool
forge script script/3-deployMarket/3.9-InitPool.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
# 3.10 init EmissionManager, RewardsController
# address of RewardsController need to be fetched on-chain since it's a proxy
forge script script/3-deployMarket/3.10-Incentive.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
EmissionManager=($(jq -r '.transactions[0].contractAddress' broadcast/3.10-Incentive.s.sol/${chainId}/run-latest.json))
echo "EmissionManager=$EmissionManager" >> ".env"
# 3.11 init a, sd, vdToken
forge script script/3-deployMarket/3.11-tokensImpl.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
ATokenImpl=($(jq -r '.transactions[0].contractAddress' broadcast/3.11-tokensImpl.s.sol/${chainId}/run-latest.json))
echo "ATokenImpl=$ATokenImpl" >> ".env"
sdTokenImpl=($(jq -r '.transactions[1].contractAddress' broadcast/3.11-tokensImpl.s.sol/${chainId}/run-latest.json))
echo "sdTokenImpl=$sdTokenImpl" >> ".env"
vdTokenImpl=($(jq -r '.transactions[2].contractAddress' broadcast/3.11-tokensImpl.s.sol/${chainId}/run-latest.json))
echo "vdTokenImpl=$vdTokenImpl" >> ".env"
# 3.12 init rateStrat, add all 6 tokens to reserve
forge script script/3-deployMarket/3.12-initReserve.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv

# 4.1 deploy mock flashloanreceiver
forge script script/4-testnet/4.1-MockFlashloanReceiver.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv

# 5.1 set risk parameter, some gas estimation was wrong so we bump up the limit
forge script script/5-setUp/5.1-setupRiskParameter.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv --gas-estimate-multiplier 200
# 5.2 set stableborrow to false (neligible since 5.1 set it aldy)
# forge script script/5-setUp/5.2-reviewStableBorrowing.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
# 5.3 set isolation
forge script script/5-setUp/5.3-setBorrowableIsolation.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
# 5.4 set debt ceiling
forge script script/5-setUp/5.4-setDebtCeiling.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv

# 5.5 set emode
forge script script/5-setUp/5.5-setEmode.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
forge script script/5-setUp/5.5.5-disableEmode.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
# 5.6 deploy mock flashloanreceiver
forge script script/5-setUp/5.6-unpausePool.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv

forge script script/6-transferOwnership/6.0-deployTimeLock.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
TimeLock=($(jq -r '.transactions[0].contractAddress' broadcast/6.0-deployTimeLock.s.sol/${chainId}/run-latest.json))
echo "TimeLock=$TimeLock" >> ".env"

# 6.1 update GOV on emissionManager
forge script script/6-transferOwnership/6.1-setGovOnEManager.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
# 6.2 update GOV on Address Provider
forge script script/6-transferOwnership/6.2-setGovOnAddressProvider.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
# 6.3 remove from ACL
forge script script/6-transferOwnership/6.3-removeDeployerFromACL.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
# 6.4 update GOV on Registry
forge script script/6-transferOwnership/6.4-setGovOnRegistry.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
# 6.5 update AToken
forge script script/6-transferOwnership/6.5-setUpAToken.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
# 6.6 update ATokenTreausry using Helper
forge script script/6-transferOwnership/6.6-setUpAToken-Helper.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv

# forge script script/1.5-testnet/updateAggregator.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
# 7.1 WalletBalanceProvider
forge script script/7-deployRead/7.1-walletBalanceProvider.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
WalletBalanceProvider=($(jq -r '.transactions[0].contractAddress' broadcast/7.1-walletBalanceProvider.s.sol/${chainId}/run-latest.json))
echo "WalletBalanceProvider=$WalletBalanceProvider" >> ".env"

forge script script/7-deployRead/7.2-borrowableProvider.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
BorrowableDataProvider=($(jq -r '.transactions[0].contractAddress' broadcast/7.2-borrowableProvider.s.sol/${chainId}/run-latest.json))
echo "BorrowableDataProvider=$BorrowableDataProvider" >> ".env"

forge script script/7-deployRead/7.3-liquidationAdaptor.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
LiquidationAdaptor=($(jq -r '.transactions[0].contractAddress' broadcast/7.3-liquidationAdaptor.s.sol/${chainId}/run-latest.json))
echo "LiquidationAdaptor=$LiquidationAdaptor" >> ".env"

forge script script/8-deployGateway/8.0.1-WBNB.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
WBNB_TESTNET_REAL=($(jq -r '.transactions[0].contractAddress' broadcast/8.0.1-WBNB.s.sol/${chainId}/run-latest.json))
echo "WBNB_TESTNET_REAL=$WBNB_TESTNET_REAL" >> ".env"

forge script script/8-deployGateway/8.0.2-addWBNBToReserve.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv

forge script script/8-deployGateway/8.0.3-configureWBNBRiskParam.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv --gas-estimate-multiplier 200

forge script script/8-deployGateway/8.0.4-approveAToken.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv

forge script script/8-deployGateway/8.1-gateway.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
GATEWAY=($(jq -r '.transactions[0].contractAddress' broadcast/8.1-gateway.s.sol/${chainId}/run-latest.json))
echo "GATEWAY=$GATEWAY" >> ".env"


# gov action
forge script script/9-govAction/TimeLockQueueExecuteFaucet.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv

forge script script/10-deployPairForLiquidation/CreatePairs.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv

# remember which number of wallet is it; first is on "m/44'/60'/0'/0/0", second is on "m/44'/60'/1'/0/0"
# enable Debug, contract data, nonce in the ledger setting; choose Ethereum network
forge script script/10-deployPairForLiquidation/ExecuteLiquidationWithLedger.s.sol --sender $LEDGER --ledger --hd-paths "m/44'/60'/$LEDGER_NUMBER'/0/0" --rpc-url $RPC_URL --broadcast --verify -vvvv


# 11 deploy custom oracle
forge script script/11-deployCustomOracle/deployMockWbETH.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
forge script script/11-deployCustomOracle/wbETHOracle.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
