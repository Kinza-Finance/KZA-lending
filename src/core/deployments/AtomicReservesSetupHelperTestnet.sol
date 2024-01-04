// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IPoolConfigurator} from '../interfaces/IPoolConfigurator.sol';
import {IPool} from '../interfaces/IPool.sol';
import {IAaveOracle} from '../interfaces/IAaveOracle.sol';
import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';
import {IERC20Detailed} from "../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {DefaultReserveInterestRateStrategy} from "../protocol/pool/DefaultReserveInterestRateStrategy.sol";
import {IPoolAddressesProvider} from "../interfaces/IPoolAddressesProvider.sol";
import {ConfiguratorInputTypes} from "../protocol/libraries/types/ConfiguratorInputTypes.sol";
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';



/**
 * @notice Deployment helper to onbaord reserve, set risk parameters as well as conduct an initial deposit 
 * @dev The AtomicReservesSetupHelper is an Ownable contract, so only the deployer or future owners can call this contract.
 */
contract AtomicReservesSetupHelperTestnet is Ownable {
        struct RateStrategyInput {
            uint256 optimalUsageRatio;
            uint256 baseVariableBorrowRate;
            uint256 variableRateSlope1;
            uint256 variableRateSlope2;
            uint256 stableRateSlope1;
            uint256 stableRateSlope2;
            uint256 baseStableRateOffset;
            uint256 stableRateExcessOffset;
            uint256 optimalStableToTotalDebtRatio;
        }
        
        struct ConfigureReserveInput {
            uint256 reserveFactor;
            uint256 borrowCap;
            uint256 supplyCap;
            bool stableBorrowingEnabled;
            bool borrowingEnabled;
            bool flashLoanEnabled;
        }
        address internal constant aTokenImpl = 0xACeF8022Ae19723ee9e749EefC5665bA7570f195;
        address internal constant sdTokenImpl = 0x1a637c6282E0B86CB138020747506164C9aCd38F;
        address internal constant vdTokenImpl = 0x67e8C47B383923ac495d3D282BB61a248Ec0a35E;
        address internal constant treasury = 0xDE6A2451A4ACeb6D540Bd216578C84503639EbF1;
        address internal constant incentivesController = 0xd642291EBBD364679F9387E0C41Cf30444A661e4;
        IPool internal constant pool = IPool(0x9ef44747E904263299258cC44DD91E9D4902464f);
        IAaveOracle internal constant oracle = IAaveOracle(0xBee779e5998295B514E0A92A1449a83090a06F3F);
        IPoolConfigurator internal constant configurator = IPoolConfigurator(0x3B727Cbd6aCc6C3AbA80F2756c3c880098eC4634);
        IPoolAddressesProvider internal constant poolAddressProvider = IPoolAddressesProvider(0x5Add4de8a8577bA3B5fb50Dc89571130a20FaCD8);

        // fdUSD
        address internal constant asset = 0xcB4bF535E92Eb3618b6b5f35690e2bEF0CD55ECe;
        // chainlink fdUSD feed
        address internal constant feed = 0xdC5e2Ef123F6B0e22bFAE48DAe9c212A1b21E6Bb;
        uint256 internal constant seedValue = 1e18;

        function newListing() external onlyOwner {
                RateStrategyInput memory rateInput = RateStrategyInput({
                  optimalUsageRatio: _bpsToRay(80_00),
                  baseVariableBorrowRate: _bpsToRay(0),
                  variableRateSlope1: _bpsToRay(5_00),
                  variableRateSlope2: _bpsToRay(60_00),
                  stableRateSlope1: _bpsToRay(13_00),
                  stableRateSlope2: _bpsToRay(300_00),
                  baseStableRateOffset: _bpsToRay(3_00),
                  stableRateExcessOffset: _bpsToRay(8_00),
                  optimalStableToTotalDebtRatio: _bpsToRay(20_00)
                });
                ConfigureReserveInput memory configureInput = ConfigureReserveInput({
                  reserveFactor: 1500,
                  borrowCap: 4000000,
                  supplyCap: 5000000,
                  stableBorrowingEnabled :false,
                  borrowingEnabled: true,
                  flashLoanEnabled: false 
                });

              // actual workflow
              _setPriceFeed();
        
              address strategy = _deployRateStrategy(rateInput);

              _initializeReserve(strategy);

              _configureReserve(configureInput);

              _supplySeedValue(seedValue);
        }


        function _setPriceFeed() internal {
          address[] memory assets = new address[](1);
          address[] memory sources = new address[](1);
          assets[0] = asset;
          sources[0] = feed;
          oracle.setAssetSources(assets, sources);
        }
        
        function _deployRateStrategy(RateStrategyInput memory rateInput) internal returns(address) {
          DefaultReserveInterestRateStrategy interestRateStrategy = new DefaultReserveInterestRateStrategy(
            poolAddressProvider,
            rateInput.optimalUsageRatio,
            rateInput.baseVariableBorrowRate,
            rateInput.variableRateSlope1,
            rateInput.variableRateSlope2,
            rateInput.stableRateSlope1,
            rateInput.stableRateSlope2,
            rateInput.baseStableRateOffset,
            rateInput.stableRateExcessOffset,
            rateInput.optimalStableToTotalDebtRatio
          );
          return address(interestRateStrategy);
        }

        function _initializeReserve(address interestRateStrategyAddress) internal {
            uint8 decimal = IERC20Detailed(asset).decimals();
            string memory symbol = IERC20Detailed(asset).symbol();
    
            ConfiguratorInputTypes.InitReserveInput[] memory inputs = new ConfiguratorInputTypes.InitReserveInput[](1);
            inputs[0] = ConfiguratorInputTypes.InitReserveInput(
                aTokenImpl,
                sdTokenImpl,
                vdTokenImpl,
                decimal,
                interestRateStrategyAddress,
                asset,
                treasury,
                incentivesController,
                string(abi.encodePacked("Kinza ", symbol)),
                string(abi.encodePacked("k", symbol)),
                string(abi.encodePacked("Kinza Variable Debt ", symbol)),
                string(abi.encodePacked("vDebt", symbol)),
                string(abi.encodePacked("Kinza Stable Debt ", symbol)),
                string(abi.encodePacked("sDebt", symbol)),
                abi.encodePacked("0x10")
                );
            configurator.initReserves(inputs);
        }



        function _configureReserve(ConfigureReserveInput memory inputParams) internal {
            // init with zero LTV in the beginning to prevent hundred finance type of frontrunning
            configurator.configureReserveAsCollateral(
              asset,
              0, // LTV
              0, // liqT
              0 // bonus
            );

            if (inputParams.borrowingEnabled) {
              configurator.setReserveBorrowing(asset, true);

              configurator.setBorrowCap(asset, inputParams.borrowCap);
              configurator.setReserveStableRateBorrowing(
                asset,
                inputParams.stableBorrowingEnabled
              );
            }
            configurator.setReserveFlashLoaning(asset, inputParams.flashLoanEnabled);
            configurator.setSupplyCap(asset, inputParams.supplyCap);
            configurator.setReserveFactor(asset, inputParams.reserveFactor);
        }

        function _supplySeedValue(uint256 seedValue) internal {
                // expect fund available
            IERC20(asset).approve(address(pool), seedValue);
            pool.supply(asset, seedValue, owner(), 0);
        }


        /** @dev Converts basis points to RAY units
        * e.g. 10_00 (10.00%) will return 100000000000000000000000000
        */
        function _bpsToRay(uint256 amount) internal pure returns (uint256) {
          return (amount * 1e27) / 10_000;
        }

}
