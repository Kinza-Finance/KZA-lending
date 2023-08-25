#!/bin/bash
env=mainnet bash ./run-example.sh
# deploy pToken itself
forge script script/12-deployPToken/12.1-PToken.s.sol --sender $Deployer --ledger --hd-paths "m/44'/60'/$LEDGER_NUMBER'/0/0" --rpc-url $RPC_URL --broadcast --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
# deploy gateway
forge script script/12-deployPToken/12.2-PTokenGateway.s.sol --sender $Deployer --ledger --hd-paths "m/44'/60'/$LEDGER_NUMBER'/0/0" --rpc-url $RPC_URL --broadcast --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
# deploy native gateway
forge script script/12-deployPToken/12.3-PTokenNativeGateway.s.sol --sender $Deployer --ledger --hd-paths "m/44'/60'/$LEDGER_NUMBER'/0/0" --rpc-url $RPC_URL --broadcast --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
# init reserve
forge script script/12-deployPToken/init-Reserve.s.sol --rpc-url $RPC_URL --broadcast --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
# setup risk parameter
forge script script/12-deployPToken/setup-RiskParameter.s.sol --rpc-url $RPC_URL --broadcast --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY -vvvv --gas-estimate-multiplier 200
# setup debt ceiling (if applicable)
forge script script/12-deployPToken/adjust-DebtCeiling.s.sol --rpc-url $RPC_URL --broadcast --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
# adjust borrowcap/supply cap for existing tokens
forge script script/12-deployPToken/adjust-BorrowSupplyCap.s.sol --rpc-url $RPC_URL --broadcast --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
