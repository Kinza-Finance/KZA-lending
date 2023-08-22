#!/bin/bash
env=mainnet bash ./run-example.sh
# deploy pToken itself
forge script script/12-deployPToken/12.1-PToken.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
# deploy gateway
forge script script/12-deployPToken/12.2-PTokenGateway.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
# deploy native gateway
forge script script/12-deployPToken/12.3-PTokenNativeGateway.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
# init reserve
forge script script/12-deployPToken/init-Reserve.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
# setup risk parameter
forge script script/12-deployPToken/setup-RiskParameter.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
# setup debt ceiling (if applicable)
forge script script/12-deployPToken/adjust-DebtCeiling.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
# adjust borrowcap/supply cap for existing tokens
forge script script/12-deployPToken/adjust-BorrowSupplyCap.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
