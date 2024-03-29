// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import '../../core/interfaces/IPoolAddressesProvider.sol';
import '../../core/interfaces/IPoolDataProvider.sol';
import '../../core/interfaces/IPool.sol';
import {IERC20WithPermit} from '../../core/interfaces/IERC20WithPermit.sol';
import {IERC20} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {Ownable} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/Ownable.sol';


contract RecoverAssetHelper is Ownable {
    IPoolAddressesProvider immutable public provider;

    constructor(address _provider) {
        provider = IPoolAddressesProvider(_provider);
    }

    // this helps the sender to recover asset(AToken) from another address (victim) after repaying his/her debt
    // 1. user needs to have signature from the victim, 
    // 2. user need to approve a given amount of debtToken to be used to repay victim's debt
    // make sure the victim's position is still healthy after (HF >= 1), otherwise revert
    function recover(address assetToken, address debtToken, uint256 aTokenAmount, uint256 debtAmount, address victim, uint8 v, bytes32 r, bytes32 s, uint256 deadline) external {
        // only 1 asset is allowed at a time, 
        IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
        IPool pool = IPool(provider.getPool());
        (,,address vdToken) = dataProvider.getReserveTokensAddresses(debtToken);
        if (debtAmount == type(uint256).max) {
            debtAmount = IERC20(vdToken).balanceOf(victim);
        }

        IERC20(debtToken).transferFrom(msg.sender, address(this), debtAmount);
        IERC20(debtToken).approve(address(pool), debtAmount);
        pool.repay(debtToken, debtAmount, 2, victim);
        // now transfer out the aToken to the sender (who repay the debt)
        (address aToken,,) = dataProvider.getReserveTokensAddresses(assetToken);
        IERC20WithPermit(aToken).permit(
        victim,
        address(this),
        aTokenAmount,
        deadline,
        v,
        r,
        s);
        if (aTokenAmount == type(uint256).max) {
            aTokenAmount = IERC20(aToken).balanceOf(victim);
        }
        IERC20(aToken).transferFrom(victim, msg.sender, aTokenAmount);
        // if any asset is left, send it back to user
        uint256 balanceLeft = IERC20(debtToken).balanceOf(address(this));
        if (balanceLeft > 0) {
            IERC20(debtToken).transfer(msg.sender, balanceLeft);
        }
        
    }

    function rescueTokens(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    function maxDebtToRepay(address victim, address debtToken) public view returns(uint256) {
        IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
        (,,address vdToken) = dataProvider.getReserveTokensAddresses(debtToken);
        return IERC20(vdToken).balanceOf(victim);
    }

    function maxATokenToRecover(address victim, address assetToken) public view returns(uint256) {
        IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
        (address aToken,,) = dataProvider.getReserveTokensAddresses(assetToken);
        return IERC20(aToken).balanceOf(victim);
    }
}