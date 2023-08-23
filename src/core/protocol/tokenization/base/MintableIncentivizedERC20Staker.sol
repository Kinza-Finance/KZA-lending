// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IStakingController} from '../../../interfaces/IStakingController.sol';
import {IPool} from '../../../interfaces/IPool.sol';
import {IncentivizedERC20} from './IncentivizedERC20.sol';
import {IMasterWombatV3} from '../../../interfaces/IMasterWombatV3.sol';
/**
 * @title MintableIncentivizedERC20
 * @author Aave
 * @notice Implements mint and burn functions for IncentivizedERC20
 */
abstract contract MintableIncentivizedERC20Staker is IncentivizedERC20 {

  IStakingController internal _stakingController;
  /**
   * @dev Constructor.
   * @param pool The reference to the main Pool contract
   * @param name The name of the token
   * @param symbol The symbol of the token
   * @param decimals The number of decimals of the token
   */
  constructor(
    IPool pool,
    string memory name,
    string memory symbol,
    uint8 decimals
  ) IncentivizedERC20(pool, name, symbol, decimals) {
    // Intentionally left blank
  }

  /**
   * @notice Returns the address of the Incentives Controller contract
   * @return The address of the Incentives Controller
   */
  function getStakingController() external view virtual returns (IStakingController) {
    return _stakingController;
  }

  /**
   * @notice Sets a new Incentives Controller
   * @param controller the new Incentives controller
   */
  function setStakingController(IStakingController stakingController) external onlyPoolAdmin {
    require(address(stakingController) == address(0), "address is already set");
    _stakingController = stakingController;
  }

  // should use stakingController so pid can be configured (even immutably on stakingController)
  function _stake(uint128 amount) internal {
    // @TODO deposit(pid, amount);
  }
 
  function _unstake(uint128 amount) internal {
    // @TODO withdraw(amount)
  }

  function emergencyWithdraw() external onlyPoolAdmin {
    //emergencyWithdraw();
  }
  /**
   * @notice Mints tokens to an account and apply incentives if defined
   * @param account The address receiving tokens
   * @param amount The amount of tokens to mint
   */
  function _mint(address account, uint128 amount) internal virtual {
    uint256 oldTotalSupply = _totalSupply;
    _totalSupply = oldTotalSupply + amount;

    uint128 oldAccountBalance = _userState[account].balance;
    _userState[account].balance = oldAccountBalance + amount;

    IAaveIncentivesController incentivesControllerLocal = _incentivesController;
    if (address(incentivesControllerLocal) != address(0)) {
      incentivesControllerLocal.handleAction(account, oldTotalSupply, oldAccountBalance);
    }

    IStakingController stakingControllerLocal = _stakingController;
    if (address(stakingControllerLocal) != address(0)) {
      stakingControllerLocal.stake(amount);
    }
  }

  /**
   * @notice Burns tokens from an account and apply incentives if defined
   * @param account The account whose tokens are burnt
   * @param amount The amount of tokens to burn
   */
  function _burn(address account, uint128 amount) internal virtual {
    uint256 oldTotalSupply = _totalSupply;
    _totalSupply = oldTotalSupply - amount;

    uint128 oldAccountBalance = _userState[account].balance;
    _userState[account].balance = oldAccountBalance - amount;

    IAaveIncentivesController incentivesControllerLocal = _incentivesController;

    if (address(incentivesControllerLocal) != address(0)) {
      incentivesControllerLocal.handleAction(account, oldTotalSupply, oldAccountBalance);
    }

    IStakingController stakingControllerLocal = _stakingController;
    if (address(stakingControllerLocal) != address(0)) {
      stakingControllerLocal.unstake(amount);
    }
  }
}
