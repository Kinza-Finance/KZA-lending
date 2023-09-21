# deploy logic and put them into foundry.toml
forge create src/core/protocol/libraries/logic/BorrowLogic.sol:BorrowLogic --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY  > log/BorrowLogic.txt
BorrowLogic=$(grep 'Deployed to: ' log/BorrowLogic.txt | awk '{print $3}')
echo "BorrowLogic=$BorrowLogic" >> ".env"

forge create src/core/protocol/libraries/logic/FlashLoanLogic.sol:FlashLoanLogic --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY  > log/FlashLoanLogic.txt
FlashLoanLogic=$(grep 'Deployed to: ' log/FlashLoanLogic.txt | awk '{print $3}')
echo "FlashLoanLogic=$FlashLoanLogic" >> ".env"