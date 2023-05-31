// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IERC20} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol';

import '../../core/interfaces/IPoolAddressesProvider.sol';
import '../../core/interfaces/IPool.sol';
import '../../core/interfaces/IPoolDataProvider.sol';
import '../../core/interfaces/IAaveOracle.sol';
import '../../core/protocol/libraries/types/DataTypes.sol';

/**
 * @title BorrowableData contract
 * @author Kinza
 * @notice Implements a logic of getting max borrowable for a particular account
 * @dev NOTE: THIS CONTRACT IS NOT USED WITHIN THE LENDING PROTOCOL. It's an accessory contract used to reduce the number of calls
 * towards the blockchain from the backend.
 **/
contract BorrowableDataProvider {
  uint256 internal constant BORROWABLE_IN_ISOLATION_MASK =   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant MAX_LTV = 10000;
  IPoolAddressesProvider immutable public provider;

  constructor(address _provider) {
    provider = IPoolAddressesProvider(_provider);
  }
  

  // main function to call when fetching the max borrowable for a user for a particular asset
  function getUserMaxBorrowable(address user, address asset) public view returns(uint256 borrowable){
        // if user is in isolation, but asset is not borrowable for isolatedMode
        if (isUserInIsolationMode(user) && !isAssetBorrowableForIsolation(asset)) {
            return 0;
        }
        // eMode is considered inside
        uint256 borrowable = calculateBorrowable(user, asset);

        uint256 available = getBorrowableAvailable(asset);
        uint256 borrowableToCap = getBorrowableUnderBorrowCap(asset);
        uint256 borrowableToDebtCeiling = getBorrowableUnderDebtCeiling(asset);
        // min function applied to borrowable with reference to 3 caps above
        borrowable = borrowable < available ? borrowable : available;
        borrowable = borrowable < borrowableToCap ? borrowable : borrowableToCap;
        borrowable = borrowable < borrowableToDebtCeiling ? borrowable : borrowableToDebtCeiling;
        

  }

  function isUserInIsolationMode(address user) public view returns(bool inIsolation) {
        IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
        IPoolDataProvider.TokenData[] memory tokens = dataProvider.getAllReservesTokens();
        for (uint256 i; i < tokens.length;i++) {
            address token = tokens[i].tokenAddress;
            (,,,,,,,,bool usageAsCollateralEnabled) = dataProvider.getUserReserveData(token, user);
            // if user enable a a token with debt ceiling as collateral
            if (isCollateralIsolated(token) && usageAsCollateralEnabled) {
                inIsolation = true;
            }
        }
  }
  function isCollateralIsolated(address asset) public view returns(bool) {
        IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
        return dataProvider.getDebtCeiling(asset) > 0;
  }

  function getBorrowableUnderBorrowCap(address asset) public view returns(uint256) {
    IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
    (uint256 cap,) = dataProvider.getReserveCaps(asset);
    uint256 debt = dataProvider.getTotalDebt(asset);
    return cap > debt ? cap - debt : 0;
  }

  function getBorrowableAvailable(address asset) public view returns(uint256) {
    IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
    uint256 supply = dataProvider.getATokenTotalSupply(asset);
    uint256 debt = dataProvider.getTotalDebt(asset);
    return supply > debt ? supply - debt / 10**18 : 0;
  }

  function getBorrowableUnderDebtCeiling(address asset) public view returns(uint256) {
    IPool pool = IPool(provider.getPool());
    IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
    DataTypes.ReserveData memory reserveData = pool.getReserveData(asset);
    // debt ceiling has a decimal of 2
    return (dataProvider.getDebtCeiling(asset) - reserveData.isolationModeTotalDebt) / (10 ** dataProvider.getDebtCeilingDecimals());
  }

  function isAssetBorrowableForIsolation(address asset) public view returns(bool) {
    IPool pool = IPool(provider.getPool());
    DataTypes.ReserveConfigurationMap memory config = pool.getConfiguration(asset);
    return (config.data & ~BORROWABLE_IN_ISOLATION_MASK) != 0;
    
  }

  function calculateBorrowable(address user, address asset) public view returns(uint256) {
        IPool pool = IPool(provider.getPool());
        IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
        IAaveOracle oracle = IAaveOracle(provider.getPriceOracle());
        address[] memory assets = new address[](1);
        assets[0] = asset;
        uint256[] memory prices = oracle.getAssetsPrices(assets);
        uint256 price = prices[0];
        uint256 userEModeCategory = pool.getUserEMode(user);
        // if user Emode does not equal to the asset eMode and userEmode is non-zero
        if (dataProvider.getReserveEModeCategory(asset) != userEModeCategory && userEModeCategory != 0) {
            return 0;
            }

        (,,uint256 availableBorrowsBase,,,) = pool.getUserAccountData(user);
        if (userEModeCategory == 0) {
            // 10 ** 8 / 10 ** 8, the result would be nominal in unit.(to nominal);
            return availableBorrowsBase / price;
            }
        // use eMode LTV
        else {
            // the borrowableBase needs to multiplt
            uint256 emodeLTV = uint256(pool.getEModeCategoryData(uint8(userEModeCategory)).ltv);
            uint256 multiplier = MAX_LTV / emodeLTV;
            return multiplier * availableBorrowsBase / price;

        }
    }
}

