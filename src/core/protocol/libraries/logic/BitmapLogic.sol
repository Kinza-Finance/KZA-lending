// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {Helpers} from '../helpers/Helpers.sol';
import {DataTypes} from '../types/DataTypes.sol';
library BitmapLogic {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;
    /**
    * @notice Check if an asset can be borrowable by a user
    * @param reservesList The reserveList 
    * @param reservesBlacklistBitmap The bitmap for reserve blacklist
    * @param assetToBorrowReserveIndex reserveIndex of the asset to borrowuserConfig
    * @param userConfig the userConfig to loop enabled collateral
    * @param reservesCount the number of reserves (including dropped reserve)
    * @return True if the the borrow works, False if any collateral is not allowed for such borrow
    */
    function isAssetBorrowable(
        mapping(uint256 => address) storage reservesList,
        mapping(uint16 => uint128) storage reservesBlacklistBitmap,
        uint16 assetToBorrowReserveIndex,
        DataTypes.UserConfigurationMap memory userConfig,
        uint256 reservesCount
    ) internal view returns (bool) {
        // if user has no collateral
        if (userConfig.isEmpty()) {
        return false;
        }
        uint16 i;
        // check if the bitmap for the to-borrow asset is 0 or not 
        // for each enabled collateral
        uint256 mask = 1 << assetToBorrowReserveIndex;
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
            uint128 bitmap = reservesBlacklistBitmap[i];
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
}