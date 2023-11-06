// create a function that works exactly like getUserAccountData on Pool
// except it also counts deposit that is not enabled as collateral

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IERC20} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IERC20Detailed} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';

import '../../core/interfaces/IPoolAddressesProvider.sol';
import '../../core/interfaces/IPool.sol';
import '../../core/interfaces/IPoolDataProvider.sol';
import '../../core/interfaces/IAaveOracle.sol';
import '../../core/interfaces/IScaledBalanceToken.sol';

/**
 * @title BorrowableDataProvider contract
 * @author Kinza
 * @notice Implements a logic of getting max borrowable for a particular account
 * @dev NOTE: THIS CONTRACT IS NOT USED WITHIN THE LENDING PROTOCOL. It's an accessory contract used to reduce the number of calls
 * towards the blockchain from the backend.
 **/
contract TVLReader {
    IPoolAddressesProvider immutable public provider;

    constructor(address _provider) {
        provider = IPoolAddressesProvider(_provider);
    }
    
    function read_TVL_batch(address[] memory users) public view returns(uint256[] memory) {
        uint256[] memory users_tvl = new uint256[](users.length);
        for (uint256 i; i < users.length; i++) {
            users_tvl[i] = read_TVL(users[i]);
        }
        return users_tvl;
    }

    // 8 decimals in notional
    function read_TVL(address user) public view returns(uint256) {
        IPool pool = IPool(provider.getPool());
        IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
        address[] memory reservesList = pool.getReservesList();
        uint256 totalCollateralInBaseCurrency;
        for (uint256 i; i < reservesList.length; ++i) {
            address currentReserveAddress = reservesList[i];
            if (currentReserveAddress == address(0)) {
                continue;
            }
            (address aTokenAddress,,) = dataProvider.getReserveTokensAddresses(currentReserveAddress);
            IAaveOracle oracle = IAaveOracle(provider.getPriceOracle());
            uint256 normalizedIncome = pool.getReserveNormalizedIncome(currentReserveAddress);
            totalCollateralInBaseCurrency += rayMul(IScaledBalanceToken(aTokenAddress).scaledBalanceOf(user), normalizedIncome) * oracle.getAssetPrice(currentReserveAddress) / 10 ** 18;
        }
        return totalCollateralInBaseCurrency;
    }

    function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
      // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
        uint256 RAY = 1e27;
        uint256 HALF_RAY = 0.5e27;
        assembly {
            if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) {
            revert(0, 0)
            }

            c := div(add(mul(a, b), HALF_RAY), RAY)
        }
    }

}
