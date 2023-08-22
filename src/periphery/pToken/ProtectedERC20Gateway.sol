// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {Ownable} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/Ownable.sol';
import {IERC20} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '@aave/core-v3/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {IPool} from '@aave/core-v3/contracts/interfaces/IPool.sol';
import {IAToken} from '@aave/core-v3/contracts/interfaces/IAToken.sol';
import {IPERC20} from './interfaces/IPERC20.sol';

import {UtilLib} from '../libraries/UtilLib.sol';

/**
 * @dev This contract helps to deposit to /wthidraw from the lending pool using protected token
 *  user can also first wrap token into the protected token himself/herself without going through this gateway
 */
contract ProtectedERC20Gateway is Ownable {
  using GPv2SafeERC20 for IERC20;

  IPool internal immutable POOL;
  
  constructor(
    IPool pool
  ) {
    UtilLib.checkNonZeroAddress(address(pool));
    POOL = pool;
    
    
  }
    
  function depositProtectedToken(
    IPERC20 pToken,
    address onBehalfOf,
    uint256 amount,
    uint16 referralCode
  ) external {
    IERC20 token = IERC20(pToken.underlying());
    token.transferFrom(msg.sender, address(this), amount);
    if (token.allowance(address(this), address(pToken)) < amount) {
        token.approve(address(pToken), 0);
        token.approve(address(pToken), type(uint256).max);
    }
    pToken.depositFor(address(this), amount);
    if (pToken.allowance(address(this), address(POOL)) < amount) {
        pToken.approve(address(POOL), 0);
        pToken.approve(address(POOL), type(uint256).max);
    }
    // if pToken does not exist as an reserve, this would revert
    POOL.deposit(address(pToken), amount, onBehalfOf, referralCode);
  }

  /**
   * @dev withdraws the protected token of msg.sender into underlying.
   * @param pToken the address of pToken to withdraw
   * @param amount amount of pToken to withdraw
   * @param to address of the user who will receive the underlying token
   */
  function withdrawProtectedToken(
    address pToken,
    uint256 amount,
    address to
  ) external {
    IAToken apToken = IAToken(POOL.getReserveData(pToken).aTokenAddress);
    // get the aToken from user
    apToken.transferFrom(msg.sender, address(this), amount);
    // withdraw the pToken
    uint256 withdrawnAmount = POOL.withdraw(pToken, amount, address(this));
    // unwrap pToken into token and send to "to"
    IPERC20(pToken).withdrawTo(to, withdrawnAmount);
  }

  /**
   * @dev withdraws the protected token into underlying based on a permit signature.
   * @param pToken the address of pToken to withdraw
   * @param amount amount of pToken to withdraw
   * @param to address of the user who will receive the underlying token
   * @param deadline validity deadline of permit and so depositWithPermit signature
   * @param permitV V parameter of ERC712 permit sig
   * @param permitR R parameter of ERC712 permit sig
   * @param permitS S parameter of ERC712 permit sig
   */
  function withdrawProtectedTokenWithPermit(
    address pToken,
    uint256 amount,
    address to,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external {
    IAToken apToken = IAToken(POOL.getReserveData(pToken).aTokenAddress);
    // permit `amount` rather than `amountToWithdraw` to make it easier for front-ends and integrators
    apToken.permit(msg.sender, address(this), amount, deadline, permitV, permitR, permitS);
    apToken.transferFrom(msg.sender, address(this), amount);

    uint256 withdrawnAmount = POOL.withdraw(pToken, amount, address(this));
    IPERC20(pToken).withdrawTo(to, withdrawnAmount);
  }

  /**
   * @dev transfer ERC20 from the utility contract, for ERC20 recovery in case of stuck tokens due
   * direct transfers to the contract address.
   * @param token token to transfer
   * @param to recipient of the transfer
   * @param amount amount to send
   */
  function emergencyTokenTransfer(
    address token,
    address to,
    uint256 amount
  ) external onlyOwner {
    IERC20(token).safeTransfer(to, amount);
  }
}
