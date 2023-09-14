#13.0.5
forge script script/13-addLPMarket/13.0.5-deployZeroReserveInterestRateStrategy.s.sol --rpc-url $RPC_URL --broadcast --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
#13.0.6
forge script script/13-addLPMarket/13.0.6-deployATokenStakerImpl.s.sol --rpc-url $RPC_URL --broadcast --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
#13.1
forge script script/13-addLPMarket/13.1-addMarketWithATokenStaker.s.sol --rpc-url $RPC_URL --broadcast --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
#13.2
forge script script/13-addLPMarket/13.2-setupRiskParameter.s.sol --rpc-url $RPC_URL --broadcast --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
#13.3
forge script script/13-addLPMarket/13.3-deployLPOracle.s.sol --rpc-url $RPC_URL --broadcast --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
# 13.4
forge script script/13-addLPMarket/13.4-addEmode.s.sol --rpc-url $RPC_URL --broadcast --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
# 13.5
forge create src/core/protocol/libraries/logic/SupplyLogic.sol:SupplyLogic --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY  > log/SupplyLogic.txt
SupplyLogic=$(grep 'Deployed to: ' log/SupplyLogic.txt | awk '{print $3}')
echo "SupplyLogic=$SupplyLogic" >> ".env"
#13.5.5 put the new SupplyLogic into foundry.toml, ensure POOL_REVISION is pumped to 0x2
forge script script/13-addLPMarket/13.5.5-deployAndInitialNewPoolImpl.s.sol --rpc-url $RPC_URL --broadcast --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
PoolV2=($(jq -r '.transactions[0].contractAddress' broadcast/13.5.5-deployAndInitialNewPoolImpl.s.sol/${chainId}/run-latest.json))
echo "PoolV2=$PoolV2" >> ".env"

#13.6 upgrade
forge script script/13-addLPMarket/13.6-upgradePoolImpl.s.sol --rpc-url $RPC_URL --broadcast --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY -vvvv

forge script script/13-addLPMarket/13.7-deployEmissionAdmin.s.sol --rpc-url $RPC_URL --broadcast --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY -vvvv