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
contract AtomicReservesSetupHelper is Ownable {
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
        address internal constant aTokenImpl = 0xFfD80ae06987D8a14C4742f9998B926343fc8F35;
        address internal constant sdTokenImpl = 0xc3752D2ce05CD638523CcCaA090EF5e25A2B87B4;
        address internal constant vdTokenImpl = 0x00170FbBC27793837f1b7fb073F91F5ED8dBAEe8;
        address internal constant treasury = 0x65FDCD48c4807F67429Bdc731d6964f5553CdB36;
        address internal constant incentivesController = 0x30b1a8C1A4a9dD9146D1166F992f4e1962683a67;
        IPool internal constant pool = IPool(0xcB0620b181140e57D1C0D8b724cde623cA963c8C);
        IAaveOracle internal constant oracle = IAaveOracle(0xec203E7676C45455BF8cb43D28F9556F014Ab461);
        IPoolConfigurator internal constant configurator = IPoolConfigurator(0xA5776459837651ed4DE8Ed922e123D5898EfE5a2);
        IPoolAddressesProvider internal constant poolAddressProvider = IPoolAddressesProvider(0xCa20a50ea454Bd9F37a895182ff3309F251Fd7cE);

        // fdUSD
        address internal constant asset = 0xc5f0f7b66764F6ec8C8Dff7BA683102295E16409;
        // chainlink fdUSD feed
        address internal constant feed = 0x390180e80058A8499930F0c13963AD3E0d86Bfc9;
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
            DataTypes.ReserveData memory data = pool.getReserveData(asset);
            require(IERC20(data.aTokenAddress).totalSupply() == seedValue, "supply asset mismatches");
        }


        /** @dev Converts basis points to RAY units
        * e.g. 10_00 (10.00%) will return 100000000000000000000000000
        */
        function _bpsToRay(uint256 amount) internal pure returns (uint256) {
          return (amount * 1e27) / 10_000;
        }

}
