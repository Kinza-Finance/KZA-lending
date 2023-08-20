export env=mainnet
# dump deployment into env for foundry
jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]' deployment/${env}.json > .env
# dump reserve config if needed; for initilization of new reserve
jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]' config/reserve.json > .env
# dump riskParameter config if needed; for onboarding/changeing risk parameter
jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]' config/riskParameter.json > .env
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