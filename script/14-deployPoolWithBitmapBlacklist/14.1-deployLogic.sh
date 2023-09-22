# deploy logic and put them into foundry.toml
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
# 1.5 BridgeLogic
forge create src/core/protocol/libraries/logic/BridgeLogic.sol:BridgeLogic --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY  > log/BridgeLogic.txt
BridgeLogic=$(grep 'Deployed to: ' log/BridgeLogic.txt | awk '{print $3}')
echo "BridgeLogic=$BridgeLogic" >> ".env"
# 1.7 FlashLoanLogic
forge create src/core/protocol/libraries/logic/FlashLoanLogic.sol:FlashLoanLogic --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY > log/FlashLoanLogic.txt
FlashLoanLogic=$(grep 'Deployed to: ' log/FlashLoanLogic.txt | awk '{print $3}')
echo "FlashLoanLogic=$FlashLoanLogic" >> ".env"