// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IERC20} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol';

import '../../core/interfaces/IPoolAddressesProvider.sol';
import '../../core/interfaces/IPool.sol';
import '../../core/interfaces/IPoolDataProvider.sol';
import '../../core/interfaces/IAaveOracle.sol';
import '../../core/protocol/libraries/types/DataTypes.sol';

/**
 * @title EmodeBorrowableData contract
 * @author Kinza
 * @notice Implements a logic of getting max borrowable for a particular account
 * @dev NOTE: THIS CONTRACT IS NOT USED WITHIN THE LENDING PROTOCOL. It's an accessory contract used to reduce the number of calls
 * towards the blockchain from the backend.
 **/
contract EmodeBorrowableDataProvider {
  uint256 internal constant BORROWABLE_IN_ISOLATION_MASK =   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant MAX_LTV = 10000;
  // some borrow needs bigger precision, for example borrowing bitcoin
  // we add 10 ** 8 for precision
  uint256 internal constant BORROWABLE_PRECISION = 10**8;
  // price from oracle is in 10 ** 8
  uint256 internal constant PRICE_PRECISION = 10**8;
  IPoolAddressesProvider immutable public provider;

  constructor(address _provider) {
    provider = IPoolAddressesProvider(_provider);
  }
  

  function getUserMaxBorrowables(address user, address[] memory assets) public view returns(uint256[] memory borrowables){
        if (assets.length > 0) {
            borrowables = new uint256[](assets.length);
            for (uint i;i < assets.length; i++) {
                borrowables[i] = getUserMaxBorrowable(user, assets[i]);
            }
        } 
        
  }
  // main function to call when fetching the max borrowable for a user for a particular asset
  function getUserMaxBorrowable(address user, address asset) public view returns(uint256){
        // if user is in isolation, but asset is not borrowable for isolatedMode
        (bool isInIsolation, address collateral) = isUserInIsolationMode(user);
        if (isInIsolation && !isAssetBorrowableForIsolation(asset)) {
            return 0;
        }
        // eMode is considered inside
        uint256 borrowable = calculateLTVBorrowable(user, asset);
        // all three variable are in nominal terms * 10 ** 8
        uint256 available = getBorrowableAvailable(asset);
        uint256 borrowableToCap = getBorrowableUnderBorrowCap(asset);
        // min function applied to borrowable with reference to 3 caps above
        if(borrowable > available) {
            borrowable = available;
        }
        if(borrowable > borrowableToCap) {
            borrowable = borrowableToCap;
        }
        if (isInIsolation) {
            // debt ceiling counts the collateral of the user (if in isolation ,there is only 1 collateral for the user)
            uint256 borrowableToDebtCeiling = getBorrowableUnderDebtCeiling(collateral);
            // since debt ceiling is in USD, we need to find the unit in asset to borrow
            uint256 price = getAssetPrice(asset);
            borrowableToDebtCeiling = PRICE_PRECISION * borrowableToDebtCeiling / price;
            if(borrowable > borrowableToDebtCeiling) {
                borrowable = borrowableToDebtCeiling;
            }    
        }
        
        return borrowable;
  }

  function isUserInIsolationMode(address user) public view returns(bool, address) {
        IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
        IPoolDataProvider.TokenData[] memory tokens = dataProvider.getAllReservesTokens();
        bool inIsolation;
        address collateral;
        for (uint256 i; i < tokens.length;i++) {
            address token = tokens[i].tokenAddress;
            (,,,,,,,,bool usageAsCollateralEnabled) = dataProvider.getUserReserveData(token, user);
            // if user enable a a token with debt ceiling as collateral
            // there would be only 1 positive instance only
            if (isCollateralIsolated(token) && usageAsCollateralEnabled) {
                inIsolation = true;
                collateral = token;
            }
        }
        return (inIsolation, collateral);
  }
  function isCollateralIsolated(address asset) public view returns(bool) {
        IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
        return dataProvider.getDebtCeiling(asset) > 0;
  }

  function getBorrowableUnderBorrowCap(address asset) public view returns(uint256) {
    IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
    // cap is in nominal unit
    (uint256 cap,) = dataProvider.getReserveCaps(asset);
    // debt is in 10 ** 18 for precision
    uint256 debt = dataProvider.getTotalDebt(asset) / 10 ** 18;
    return cap > debt ? BORROWABLE_PRECISION * (cap - debt) : 0;
  }

  function getBorrowableAvailable(address asset) public view returns(uint256) {
    IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
    uint256 supply = dataProvider.getATokenTotalSupply(asset);
    uint256 debt = dataProvider.getTotalDebt(asset);
    return supply > debt ? BORROWABLE_PRECISION * (supply - debt) / 10**18 : 0;
  }

  function getBorrowableUnderDebtCeiling(address asset) public view returns(uint256) {
    IPool pool = IPool(provider.getPool());
    IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
    DataTypes.ReserveData memory reserveData = pool.getReserveData(asset);
    // debt ceiling has a decimal of 2
    return BORROWABLE_PRECISION * (dataProvider.getDebtCeiling(asset) - reserveData.isolationModeTotalDebt) / (10 ** dataProvider.getDebtCeilingDecimals());
  }

  function isAssetBorrowableForIsolation(address asset) public view returns(bool) {
    IPool pool = IPool(provider.getPool());
    DataTypes.ReserveConfigurationMap memory config = pool.getConfiguration(asset);
    return (config.data & ~BORROWABLE_IN_ISOLATION_MASK) != 0;
    
  }

  function getAssetPrice(address asset) public view returns(uint256) {
        IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
        IAaveOracle oracle = IAaveOracle(provider.getPriceOracle());
        address[] memory assets = new address[](1);
        assets[0] = asset;
        uint256[] memory prices = oracle.getAssetsPrices(assets);
        uint256 price = prices[0];
        return price;
  }

  function calculateLTVBorrowable(address user, address asset) public view returns(uint256) {
        IPool pool = IPool(provider.getPool());
        IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
        uint256 price = getAssetPrice(asset);
        uint256 userEModeCategory = pool.getUserEMode(user);
        // if user Emode does not equal to the asset eMode and userEmode is non-zero
        if (dataProvider.getReserveEModeCategory(asset) != userEModeCategory && userEModeCategory != 0) {
            return 0;
            }

        (,,uint256 availableBorrowsBase,,,) = pool.getUserAccountData(user);

        
        if (userEModeCategory == 0) {
            // the result would be in 10 ** 8 of the nominal unit
            return BORROWABLE_PRECISION * availableBorrowsBase / price;
            }
        // use eMode LTV
        else {
            // the borrowableBase needs to multiply for an increased LTV
            uint256 emodeLTV = uint256(pool.getEModeCategoryData(uint8(userEModeCategory)).ltv);
            uint256 multiplier = MAX_LTV / emodeLTV;
            // the result would be in 10 ** 8 of the nominal unit
            return BORROWABLE_PRECISION * multiplier * availableBorrowsBase / price;

        }
    }

    function canUserToggleEmode(address user, uint256 eModeToToggle) public view returns(bool) {
        IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
        IPoolDataProvider.TokenData[] memory tokens = dataProvider.getAllReservesTokens();
        //if a user is not borrowing, then he can toggle to any eMode
        for (uint256 i; i < tokens.length;i++) {
            address token = tokens[i].tokenAddress;
            (,uint256 currentStableDebt, uint256 currentVariableDebt,,,,,,) = dataProvider.getUserReserveData(token, user);
            // if user has debt on this token
            if (currentStableDebt + currentVariableDebt > 0) {
                // check if the debt has the same eMode Category as the emode to enable
                if (dataProvider.getReserveEModeCategory(token) != eModeToToggle) {
                    return false;
                }
            }
        }
        return true;
    }
}

