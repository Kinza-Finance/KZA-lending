// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IERC20} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import '../../core/interfaces/IPoolAddressesProvider.sol';
import '../../core/interfaces/IPool.sol';
import '../../core/interfaces/IPoolDataProvider.sol';
import '../../core/interfaces/IAaveOracle.sol';
import '../../core/protocol/libraries/types/DataTypes.sol';

/**
 * @title LiquidationAdaptor contract
 * @author Kinza
 * @notice Implements a friendly handler for liquidation
 **/

interface IPancakeV3SwapCallback {
    function pancakeV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}


 interface IV2SwapRouter {
    // V2 interface
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountOut);
    
 }

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via PancakeSwap V3
interface IV3SwapRouter is IPancakeV3SwapCallback {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

interface IAdaptorFallBack {
    function getPath(address _tokenIn, address _tokenOut) external returns(bytes memory);
}

contract LiquidationAdaptor is Ownable {
    // FALLBACK means the flows "try V3" first, if fails it attempts V2
    enum ROUTE {FALLBACK, V2FALLBACK, V3FALLBACK, V2CUSTOMED, V3CUSTOMED}

    address constant public smartRouter = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4;
    address public V2Fallback;
    address public V3Fallback;
    // this struct for getting away with "stack too depp"
    struct UserReserve{
        uint256 currentATokenBalance;
        uint256 currentStableDebt;
        uint256 currentVariableDebt;
        bool usageAsCollateralEnabled;
    }
    // result from the liquidation check
    struct LiquidationCheckResult {
        bool isLiquidable;
        address MostValuableCollateral;
        address MostValuableDebt;
        uint256 CollateralPrice;
        uint256 DebtPrice;
        uint256 CollateralAmountSeizable;
        uint256 DebtAmountRepayable;
    }

    // to get away from stack too deep
    struct ExecuteOperationInput {
        address collateralAsset; 
        address liquidatedUser; 
        address liquidator;
        ROUTE route;
        bytes customPath;
    }

    uint256 internal constant HEALTH_THRESHOLD = 1 * 10 ** 18;

    IPoolAddressesProvider immutable public provider;

    modifier onlyPool() {
        require(msg.sender == provider.getPool());
        _;
    }
    constructor(address _provider) {
        provider = IPoolAddressesProvider(_provider);
    }
    
    function getUserReserveData(address token, address user) public view returns(UserReserve memory r) {
        IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
        (uint256 currentATokenBalance, 
        uint256 currentStableDebt,
        uint256 currentVariableDebt,,,,,,
        bool usageAsCollateralEnabled) = dataProvider.getUserReserveData(token, user);
        r.currentATokenBalance = currentATokenBalance;
        r.currentStableDebt  = currentStableDebt;
        r.currentVariableDebt = currentVariableDebt;
        r.usageAsCollateralEnabled = usageAsCollateralEnabled;
    }
    function getUsersHealth(address[] memory users) public view returns(LiquidationCheckResult[] memory) {
            IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
            IPool pool = IPool(provider.getPool());
            LiquidationCheckResult[] memory result = new LiquidationCheckResult[](users.length);
            for (uint256 i; i < users.length;i++) {
                LiquidationCheckResult memory r;
                (,,,,,uint256 healthFactor) = pool.getUserAccountData(users[i]);
                if (healthFactor >= HEALTH_THRESHOLD) {
                    result[i] = r;
                } else {
                    // user is subject to liqidation
                    // loop each asset to find user's most worthy aToken/debtToken
                    r.isLiquidable = true;
                    IPoolDataProvider.TokenData[] memory tokens = dataProvider.getAllReservesTokens();
                    for (uint256 j;j<tokens.length;j++) {
                        UserReserve memory reserveData = getUserReserveData(tokens[j].tokenAddress, users[i]);
                        uint256 price = getAssetPrice(tokens[j].tokenAddress);
                        if (r.CollateralPrice * r.CollateralAmountSeizable < reserveData.currentATokenBalance * price && reserveData.usageAsCollateralEnabled) {
                            r.CollateralAmountSeizable = reserveData.currentATokenBalance;
                            r.MostValuableCollateral = tokens[j].tokenAddress;
                            r.CollateralPrice = price;
                        }
                        // over-estimate of debtAmountToRepay
                        // dummpy algorithm, not smart but more readable aim for off-chain purposes
                        if (r.DebtAmountRepayable * r.DebtPrice < (reserveData.currentStableDebt + reserveData.currentVariableDebt) * price) {
                            r.MostValuableDebt = tokens[j].tokenAddress;
                            r.DebtPrice = price;
                            r.DebtAmountRepayable = reserveData.currentStableDebt + reserveData.currentVariableDebt;
                        }
                    }
                    // minimum of close factor(0.5) or the amount equivalent to the most valuable collateral to seize
                    r.DebtAmountRepayable = r.DebtAmountRepayable / 2 > r.CollateralPrice * r.CollateralAmountSeizable / r.DebtPrice ?
                                            r.CollateralPrice * r.CollateralAmountSeizable / r.DebtPrice :
                                            r.DebtAmountRepayable / 2;
                    // base on the DebtAmountRepayable, update the collateral to seize
                    r.CollateralAmountSeizable = r.DebtAmountRepayable * r.DebtPrice / r.CollateralPrice;
                    result[i] = r;
                    
                }
            }
            return result;
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

    // call this to liquidate a user
    function liquidateWithFlashLoan(address liquidated, address collateral, address debtToken, uint256 debtAmount, ROUTE route, bytes memory customPath) external {
        IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
        IPool pool = IPool(provider.getPool());
        // allow the pool to get back the flashloan + premium
        IERC20(debtToken).approve(address(pool), type(uint256).max);
        //construct calldata to be execute in "executeOperation
        // swapData is only necessarily when route is "CUSTOM", otherwise it can be left as emptied
        bytes memory params = abi.encode(collateral, liquidated, msg.sender, route, customPath);
        pool.flashLoanSimple(
            address(this),
            debtToken,
            debtAmount,
            params,
            0
        );
    }

    function executeOperation(
    address borrowedAsset,
    uint256 amount,
    uint256 premium,
    address, //initiator, which would be this address if called from liquidateWithFlashLoan
    bytes memory params
  )  external onlyPool returns (bool){
        // 1. repay for the liquidated user using the flashloan amount
        ExecuteOperationInput memory inputs;
        {
            (address collateralAsset, address liquidatedUser, address liquidator, ROUTE route, bytes memory customPath) = 
            abi.decode(params, (address, address, address, ROUTE, bytes));
            inputs.collateralAsset = collateralAsset;
            inputs.liquidatedUser = liquidatedUser;
            inputs.liquidator = liquidator;
            inputs.route = route;
            inputs.customPath = customPath;
        }
        
        IPool pool = IPool(provider.getPool());
        pool.liquidationCall(
            inputs.collateralAsset,
            borrowedAsset,
            inputs.liquidatedUser,
            amount,
            // receiveAToken
            false
            );
        uint256 seizedCollateralAmount = IERC20(inputs.collateralAsset).balanceOf(address(this));
        if (inputs.collateralAsset != borrowedAsset) {
            uint256 seizedCollateralAmount = IERC20(inputs.collateralAsset).balanceOf(address(this));
            // 2. swap the collateral back to the debtToken
            // approve the router for pulling the tokeIn
            IERC20(inputs.collateralAsset).approve(address(smartRouter), type(uint256).max);
            bytes memory path;
            if (inputs.route == ROUTE.V2CUSTOMED || inputs.route == ROUTE.V3CUSTOMED) {
                path = inputs.customPath;
            } else {
                if (inputs.route == ROUTE.V2FALLBACK) {
                    path = IAdaptorFallBack(V2Fallback).getPath(inputs.collateralAsset, borrowedAsset);
                } else {
                    // can only be V3FALLBACK or FALLBACK(which prioritize V3)
                    path = IAdaptorFallBack(V3Fallback).getPath(inputs.collateralAsset, borrowedAsset);
                }
            }
            //V3 swap
            bool tradeExecuted;
            if (inputs.route == ROUTE.V3CUSTOMED || inputs.route == ROUTE.V3FALLBACK || inputs.route == ROUTE.FALLBACK) {
                IV3SwapRouter.ExactInputParams memory params;
                params.path = path;
                params.recipient = address(this);
                params.amountIn = seizedCollateralAmount;
                params.amountOutMinimum = 0;
                // if fallback we try execute V3 first but dont revert if it fails
                if (inputs.route == ROUTE.FALLBACK) {
                    try IV3SwapRouter(smartRouter).exactInput(params) returns (uint256 result){tradeExecuted = true;} catch {}
                } else {
                    IV3SwapRouter(smartRouter).exactInput(params);
                }
            }
            if ((inputs.route == ROUTE.V2CUSTOMED || inputs.route == ROUTE.V2FALLBACK || 
            inputs.route == ROUTE.FALLBACK) && !tradeExecuted) {
                address[] memory finalPath;
                for (uint i; i*20 < path.length; i++) {
                    finalPath[i] = _toAddress(path, i*20);
                }
                IV2SwapRouter(smartRouter).swapExactTokensForTokens(seizedCollateralAmount, 0, finalPath, address(this));
            }
        }
        // 3. set aside the flashloan amount + premium for repay
        // minus 1 wei more for any (potential) floor down
        uint256 profit = IERC20(borrowedAsset).balanceOf(address(this)) - amount - premium - 1;
        // 4. send any profit to msg.sender
        IERC20(borrowedAsset).transfer(inputs.liquidator, profit);
        return true;
    }

    /// OWNABLE
    function updateV2Fallback(address _newV2Fallback) external onlyOwner {
        V2Fallback = _newV2Fallback;
    }

    function updateV3Fallback(address _newV3Fallback) external onlyOwner {
        V3Fallback = _newV3Fallback;
    }


    // INTERNAL
    // copied from BytesLib https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
    function _toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }
}