// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {Helpers} from '../helpers/Helpers.sol';
import {DataTypes} from '../types/DataTypes.sol';

import {BitMath} from '../math/BitMath.sol';
library BitmapLogic {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;
    /**
    * @notice Check if an asset can be borrowable by a user
    * @param reservesData The reservesData 
    * @param reservesList The reservesList
    * @param assetToBorrowReserveIndex reserveIndex of the asset to borrow
    * @param userConfig the userConfig to loop for the enabled collateral
    * @param reservesCount the number of reserves (including dropped reserve)
    * @return True if the the borrow works, False if any collateral is not allowed for such borrow
    */
    function isAssetBorrowable(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        uint16 assetToBorrowReserveIndex,
        DataTypes.UserConfigurationMap memory userConfig,
        uint256 reservesCount
    ) internal view returns (bool) {
        // if user has no collateral
        if (userConfig.isEmpty()) {
        return false;
        }
        uint16 i;
        // the bit to check
        uint256 mask = 1 << assetToBorrowReserveIndex;
        // check if the bitmap for the to-borrow asset is 0 or not 
        // for each enabled collateral
        while (i < reservesCount) {
            if (!userConfig.isUsingAsCollateral(i)) {
            unchecked {
                ++i;
            }
            continue;
            }
            // dropped reserve would have address 0
            address currentReserveAddress = reservesList[i];
            if (currentReserveAddress == address(0)) {
            unchecked {
                ++i;
            }
            continue;
            }
            uint128 bitmap = reservesData[currentReserveAddress].blacklistBitmap;
            // if the bit is set, it means the reserve is not allowed to borrow this asset
            if (bitmap & mask > 0) {
                return false;
            }
            unchecked {
            ++i;
            }
        }
    return true;
    }

    function isAssetCollateralizable(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap memory userConfig,
        address asset
    ) internal view returns(bool) {
        // if user has no borrowing
        if (!userConfig.isBorrowingAny()) {
            return true;
        }
        uint128 blacklistBitmap = reservesData[asset].blacklistBitmap;
        if (blacklistBitmap == 0) {
            return true;
        }
        // we loop through the bitmap, but only from the most signaficant bit
        uint16 mostSignaficantBit = uint16(BitMath.mostSignificantBit(blacklistBitmap));
        uint16 i;
        // check if the bitmap for the to-borrow asset is 0 or not 
        // for each enabled collateral
        while (i <= mostSignaficantBit) {
            if (!userConfig.isBorrowing(i)) {
            unchecked {
                ++i;
            }
            continue;
            }
            // if the bit on the bitmap of this borrowing is set, it means the reserve is not allowed to be used as collateral
            if (blacklistBitmap & (1 << i) > 0) {
                return false;
            }
            unchecked {
            ++i;
            }
        }
        return true;
    }
}