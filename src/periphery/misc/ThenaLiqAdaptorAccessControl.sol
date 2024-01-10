// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IERC20} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import '../../core/interfaces/IPoolAddressesProvider.sol';
import '../../core/interfaces/IPool.sol';
import '../../core/interfaces/IPoolDataProvider.sol';
import '../../core/interfaces/IAaveOracle.sol';
import '../../core/protocol/libraries/types/DataTypes.sol';

interface InterfaceForRoute {
    struct route {
        address from;
        address to;
        bool stable;
    }
}

interface IV2Fallback is InterfaceForRoute {
        function getPath(address, address) external returns(route[] memory);
}
interface IV2Pool {
    
    function token0() external returns(address);
    function token1() external returns(address);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
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

 interface IV2SwapRouter is InterfaceForRoute {
    // V2 interface
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        route[] calldata routes,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);
 }


contract ThenaLiqAdaptorAccessControl is Ownable {
                            // opbnb: 0x4E02acCD83C09EaF2ff4b8346ED6a33A7a369b47
                            // bnb: 0xd4ae6eca985340dd434d38f470accce4dc78d109
    address constant public V2Router = 0x4E02acCD83C09EaF2ff4b8346ED6a33A7a369b47;
    address public V2Fallback;
    // this struct for getting away with "stack too deep"
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
    struct HookInput {
        address debtToken;
        uint256 debtAmount;
        address collateralAsset; 
        address liquidatedUser; 
        address flashToken;
        address flashPool;
        uint256 flashAmount;
        uint256 flashFee;
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

    function liquidateWithCapital(address liquidated, address collateral, address debtToken, uint256 debtAmount) external onlyOwner {
        IERC20(debtToken).transferFrom(msg.sender, address(this), debtAmount);
        IPool pool = IPool(provider.getPool());
        if (IERC20(debtToken).allowance(address(pool), address(this)) < debtAmount) {
            IERC20(debtToken).approve(address(pool), type(uint256).max);
        }
        // assume the contract acquire >= debtAmount aldy
        pool.liquidationCall(
            collateral,
            debtToken,
            liquidated,
            debtAmount,
            // receiveAToken
            false
            );
        uint256 seizedCollateralAmount = IERC20(collateral).balanceOf(address(this));
        // handling of pToken
        // assume noramal ERC20 doesnot have this call of underlying
        // underlying sload should cost <1000
        (bool success, ) = collateral.staticcall{gas: 2000}(abi.encodeWithSignature("underlying()"));
        // if there is undelying assume this is a pToken
        if (success) {
            // withdraw pToken into underlying
            IPToken(collateral).withdrawTo(address(this), seizedCollateralAmount);
            // update collateralAsset to be the underliny, the previous call wont be gas-grieved   
            collateral = IPToken(collateral).underlying();
        }
        // send to caller
        IERC20(collateral).transfer(msg.sender, seizedCollateralAmount);
    }
    // call this to liquidate a user
    // call swap in a pool to get the flashloan, 
    // liquidateWithFlashLoan -> swap -> hook(callback/executeOperation) -> swap (check)
    function liquidateWithFlashLoan(address flashToken, uint256 flashAmount,  uint256 flashFee, address flashPool, address liquidated, address collateral, address debtToken, uint256 debtAmount) external onlyOwner {
        bytes memory params = abi.encode(debtToken, debtAmount, collateral, liquidated, flashPool, flashToken, flashAmount, flashFee, msg.sender);
        //swap/flashloan the flashToken from thena pool
        bool isFlashTokenToken0 = IV2Pool(flashPool).token0() == flashToken;
        if (isFlashTokenToken0) {
            IV2Pool(flashPool).swap(
                flashAmount,
                0,
                address(this),
                params
            );
        } else {
            IV2Pool(flashPool).swap(
                0,
                flashAmount,
                address(this),
                params
            );
        }
    }

    // like executeOperation, swap, repay, and transfer fund back to the pool
    function hook(
    address, //sender which is this contract
    uint256 amount0Out,
    uint256 amount1Out,
    bytes calldata params
  )  external {
        // 1. repay for the liquidated user using the flashloan amount
        HookInput memory inputs;
        {
            (address debtToken, uint256 debtAmount, address collateralAsset, address liquidatedUser, address flashPool, address flashToken, uint256 flashAmount, uint256 flashFee, address liquidator) = 
            abi.decode(params, (address, uint256, address, address, address, address, uint256, uint256, address));
            inputs.debtToken = debtToken;
            inputs.debtAmount = debtAmount;
            inputs.collateralAsset = collateralAsset;
            inputs.liquidatedUser = liquidatedUser;
            inputs.flashToken = flashToken;
            inputs.flashPool = flashPool;
            inputs.flashAmount = flashAmount;
            inputs.flashFee = flashFee;
            inputs.liquidator = liquidator;
        }
        // now swap the borrowedAsset to the debtToken
        if (IERC20(inputs.flashToken).allowance(V2Router, address(this)) != type(uint256).max) {
            IERC20(inputs.flashToken).approve(V2Router, type(uint256).max);
        }
        if (inputs.flashToken != inputs.debtToken) {
            _V2ExactIn(inputs.flashToken, inputs.debtToken, IERC20(inputs.flashToken).balanceOf(address(this)), 0);
        }
        // now repay 
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
        // underlying sload should cost <1000
        (bool success, ) = inputs.collateralAsset.staticcall{gas: 2000}(abi.encodeWithSignature("underlying()"));
        // if there is undelying assume this is a pToken
        if (success) {
            // withdraw pToken into underlying
            IPToken(inputs.collateralAsset).withdrawTo(address(this), seizedCollateralAmount);
            // update collateralAsset to be the underliny, the previous call wont be gas-grieved   
            inputs.collateralAsset = IPToken(inputs.collateralAsset).underlying();
        }
        // if underlying collateral is not the flashToken
        if (inputs.collateralAsset != inputs.flashToken) {
            if (IERC20(inputs.collateralAsset).allowance(V2Router, address(this)) != type(uint256).max) {
                IERC20(inputs.collateralAsset).approve(V2Router, type(uint256).max);
            } 
            // now swap the collateral token to the flashToken
            _V2ExactIn(inputs.collateralAsset, inputs.flashToken, seizedCollateralAmount, 0);
        }
        uint256 balance = IERC20(inputs.flashToken).balanceOf(address(this));
        // transfer the flashAmount * 1 + fee to the pool, the rest to caller
        uint256 flashWithPremium = inputs.flashAmount * (10000 + inputs.flashFee) / 10000;
        IERC20(inputs.flashToken).transfer(inputs.flashPool, flashWithPremium);
        // 4. send any profit to msg.sender
        // underflow if unprofitable
        IERC20(inputs.flashToken).transfer(inputs.liquidator, balance - flashWithPremium);
    }


    /// OWNABLE
    function updateV2Fallback(address _newV2Fallback) external onlyOwner {
        V2Fallback = _newV2Fallback;
    }

    function rescueToken(address token) external onlyOwner {
        uint256 balance =  IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner(), balance);
    }

    // INTERNAL
    function _V2ExactIn(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin) internal {
        InterfaceForRoute.route[] memory path = IV2Fallback(V2Fallback).getPath(tokenIn, tokenOut);
        IV2SwapRouter(V2Router).swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), block.timestamp);
    }

}