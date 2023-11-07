// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IERC20} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import '../../core/interfaces/IPoolAddressesProvider.sol';
import '../../core/interfaces/IPool.sol';
import '../../core/interfaces/IPoolDataProvider.sol';
import '../../core/interfaces/IAaveOracle.sol';
import '../../core/protocol/libraries/types/DataTypes.sol';

interface IAaveV2Pool {
    function flashLoan(address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external; 
}

interface IV3Pool {
    function token0() external returns(address);
    function token1() external returns(address);
}

interface IPToken {
    function underlying() external view returns(address);
    function withdrawTo(address account, uint256 amount) external returns (bool);
}
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
    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

}

interface IAdaptorFallBack {
    function getPath(address _tokenIn, address _tokenOut) external returns(bytes memory);
}

contract AaveV2CrossTokenLiqAdatorAccessControl is Ownable {

    address constant public smartRouter = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4;
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
        address debtToken;
        uint256 debtAmount;
        address pool;
        address collateralAsset; 
        address liquidatedUser; 
        address liquidator;
    }

    uint256 internal constant HEALTH_THRESHOLD = 1 * 10 ** 18;

    IPoolAddressesProvider immutable public provider;

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
    function liquidateWithFlashLoan(address flashToken, uint256 flashTokenAmount, IAaveV2Pool pool, address liquidated, address collateral, address debtToken, uint256 debtAmount) external onlyOwner {
        IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
        address[] memory flashTokens = new address[](1);
        uint256[] memory flashAmounts = new uint256[](1);
        uint256[] memory modes = new uint256[](1);
        flashTokens[0] = flashToken;
        flashAmounts[0] = flashTokenAmount;
        // revert if the fund cannot be returned
        modes[0] = 0;
        // allow the pool to get back the flashloan + premium
        IERC20(flashToken).approve(address(pool), type(uint256).max);

        // ensure the flashed amount can be swapped to the required debtAmount otherwise would fail
        //construct calldata to be execute in "executeOperation
        // swapData is only necessarily when route is "CUSTOM", otherwise it can be left as emptied
        bytes memory params = abi.encode(debtToken, debtAmount, address(pool), collateral, liquidated, msg.sender);
        pool.flashLoan(
            address(this),
            flashTokens,
            flashAmounts,
            modes,
            address(this),
            params,
            0
        );
    }

    function executeOperation(
    address[] calldata borrowedAssets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address, //initiator, which would be this address if called from liquidateWithFlashLoan
    bytes calldata params
  )  external returns (bool){
        // 1. repay for the liquidated user using the flashloan amount
        ExecuteOperationInput memory inputs;
        {
            (address debtToken, uint256 debtAmount, address AaveV2Pool, address collateralAsset, address liquidatedUser, address liquidator) = 
            abi.decode(params, (address, uint256, address, address, address, address));
            inputs.debtToken = debtToken;
            inputs.debtAmount = debtAmount;
            inputs.pool = AaveV2Pool;
            inputs.collateralAsset = collateralAsset;
            inputs.liquidatedUser = liquidatedUser;
            inputs.liquidator = liquidator;
        }
        uint256 amount = amounts[0];
        address borrowedAsset = borrowedAssets[0];
        uint256 premium = premiums[0];
        // now swap the borrowedAsset to the debtToken
        if (IERC20(borrowedAsset).allowance(smartRouter, address(this)) != type(uint256).max) {
            IERC20(borrowedAsset).approve(smartRouter, type(uint256).max);
        }
        if (borrowedAsset != inputs.debtToken) {
            _V3SwapExactOutput(borrowedAsset, inputs.debtToken, inputs.debtAmount);
        }
        IPool pool = IPool(provider.getPool());
        IERC20(inputs.debtToken).approve(address(pool), type(uint256).max);
        // assume the contract acquire >= debtAmount aldy
        pool.liquidationCall(
            inputs.collateralAsset,
            inputs.debtToken,
            inputs.liquidatedUser,
            inputs.debtAmount,
            // receiveAToken
            false
            );
        uint256 seizedCollateralAmount = IERC20(inputs.collateralAsset).balanceOf(address(this));
        // handling of pToken
        // assume noramal ERC20 doesnot have this call of underlying
        (bool success, ) = inputs.collateralAsset.staticcall(abi.encodeWithSignature("underlying()"));
        // if there is undelying assume this is a pToken
        if (success) {
            // withdraw pToken into underlying
            IPToken(inputs.collateralAsset).withdrawTo(address(this), seizedCollateralAmount);
            // update collateralAsset to be the underliny, the previous call wont be gas-grieved   
            inputs.collateralAsset = IPToken(inputs.collateralAsset).underlying();
        }
        // if underlying collateral is not the flashToken
        if (inputs.collateralAsset != borrowedAsset) {
            if (IERC20(inputs.collateralAsset).allowance(smartRouter, address(this)) != type(uint256).max) {
                IERC20(inputs.collateralAsset).approve(smartRouter, type(uint256).max);
            } 
            // now swap the collateral token to the flashToken
            _V3SwapExactInput(inputs.collateralAsset, borrowedAsset, seizedCollateralAmount);
        }
        
        // 3. set aside the flashloan amount + premium for repay
        // minus 1 wei more for any (potential) floor down
        //uint256 profit = IERC20(borrowedAsset).balanceOf(address(this)) - amount - premium - 1;
        // 4. send any profit to msg.sender
        //IERC20(borrowedAsset).transfer(inputs.liquidator, profit);
        return true;
    }


    function updateV3Fallback(address _newV3Fallback) external onlyOwner {
        V3Fallback = _newV3Fallback;
    }

    function _V3SwapExactInput(address inToken, address outToken, uint256 inAmount) internal {
        bytes memory path = IAdaptorFallBack(V3Fallback).getPath(inToken, outToken);
            //V3 swap
        IV3SwapRouter.ExactInputParams memory params;
        params.path = path;
        params.recipient = address(this);
        params.amountIn = inAmount;
        params.amountOutMinimum = 0;
        IV3SwapRouter(smartRouter).exactInput(params);
    }

    function _V3SwapExactOutput(address inToken, address outToken, uint256 outAmount) internal {
        // output need to reverse the path in swapping
        bytes memory path = IAdaptorFallBack(V3Fallback).getPath(outToken, inToken);
            //V3 swap
        IV3SwapRouter.ExactOutputParams memory params;
        params.path = path;
        params.recipient = address(this);
        params.amountOut = outAmount;
        params.amountInMaximum = IERC20(inToken).balanceOf(address(this));
        IV3SwapRouter(smartRouter).exactOutput(params);
    }
}