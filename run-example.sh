export env=opbnb-testnet
# dump deployment into env for foundry
jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]' deployment/${env}.json > .env
# dump reserve config if needed; for initilization of new reserve
jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]' config/reserve.json >> .env
# dump riskParameter config if needed; for onboarding/changeing risk parameter
jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]' config/riskParameter.json >> .env
# dump constant config if needed
jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]' config/constant.json >> .env

source .env
# replace logic in foundry toml for dynamic linking if needed
sed -re "s/(SupplyLogic:)[0-9a-xA-X]+/\1${SupplyLogic}/" \
    -re "s/(BorrowLogic:)[0-9a-xA-X]+/\1${BorrowLogic}/" \
    -re "s/(LiquidationLogic:)[0-9a-xA-X]+/\1${LiquidationLogic}/" \
    -re "s/(EModeLogic:)[0-9a-xA-X]+/\1${EModeLogic}/" \
    -re "s/(BridgeLogic:)[0-9a-xA-X]+/\1${BridgeLogic}/" \
    -re "s/(ConfiguratorLogic:)[0-9a-xA-X]+/\1${ConfiguratorLogic}/" \
    -re "s/(FlashLoanLogic:)[0-9a-xA-X]+/\1${FlashLoanLogic}/" \
    -re "s/(PoolLogic:)[0-9a-xA-X]+/\1${PoolLogic}/" foundry.toml > tmp.toml
# cant sort -re and -inplace in the same sed command so rather split into two lines
mv tmp.toml foundry.toml
# then run whatever script now
# depends on what network u wanna run, fill in for the foundry.toml
export CHAPEL_ETHERSCAN_API_KEY=
# specific to opBNB
export NODEREAL_KEY=

# EXAMPLE of using ledger
export LEDGER=
export LEDGER_NUMBER=
# forge script script/5-setUp/5.1-setupRiskParameter.s.sol --sender $LEDGER --ledger --hd-paths "m/44'/60'/$LEDGER_NUMBER'/0/0" --rpc-url bsc --broadcast --verify -vvvv
# EXAMPLE of using an EOA with private key, where PRIVATE_KEY is read in the script
export PRIVATE_KEY=
# forge script script/4-testnet/4.1-MockFlashloanReceiver.s.sol --rpc-url bsc --broadcast --verify -vvvv