# logic lib can be automatically deployed during deploying of the contract that uses them
#  but that create problems since each lib would be created repeatedly.

# consider deploy lib first, and then put the address in foundry.toml under libraries

# Logic are all libraries that can be deployed without constructor
# refer to deploy scripts 
# examples are 
## forge create src/contracts/protocol/libraries/logic/SupplyLogic.sol:SupplyLogic --private-key $PRIVATE_KEY --rpc-url $RPC_URL --verify --verifier-url $VERIFIER_URL --etherscan-api-key $ETHERSCAN_API_KEY | tee SupplyLogic_log.txt 

