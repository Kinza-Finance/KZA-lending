// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {Ownable} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/Ownable.sol';
import {IERC20} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '@aave/core-v3/contracts/dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {IPool} from '@aave/core-v3/contracts/interfaces/IPool.sol';
import {IAToken} from '@aave/core-v3/contracts/interfaces/IAToken.sol';
import {IWBNB} from './interfaces/IWBNB.sol';
import {IPERC20} from './interfaces/IPERC20.sol';

import {UtilLib} from '../libraries/UtilLib.sol';

contract ProtectedNativeTokenGateway is Ownable {
  using GPv2SafeERC20 for IERC20;

  IWBNB internal immutable WBNB;
  IPool internal immutable POOL;
  IPERC20 internal immutable pWBNB;

  /**
   * @dev Sets the WBNB address and the PoolAddressesProvider address. Infinite approves pool.
   * @param wbnb Address of the Wrapped BNB contrac
   **/
  constructor(
    address wbnb,
    address pwbnb,
    IPool pool
  ) {
    UtilLib.checkNonZeroAddress(wbnb);
    UtilLib.checkNonZeroAddress(pwbnb);
    UtilLib.checkNonZeroAddress(address(pool));
    WBNB = IWBNB(wbnb);
    pWBNB = IPERC20(pwbnb);
    POOL = pool;
    WBNB.approve(address(pwbnb), type(uint256).max);
    IERC20(pwbnb).approve(address(pool), type(uint256).max);
  }

  /**
   * @dev deposits pWBNB into the reserve, using native token. A corresponding amount of the overlying asset (aTokens)
   * is minted.
   * @param onBehalfOf address of the user who will receive the aTokens representing the deposit
   * @param referralCode integrators are assigned a referral code and can potentially receive rewards.
   **/
  function depositProtectedBNB(
    address onBehalfOf,
    uint16 referralCode
  ) external payable {
    WBNB.deposit{value: msg.value}();
    pWBNB.depositFor(address(this), msg.value);
    POOL.deposit(address(pWBNB), msg.value, onBehalfOf, referralCode);
  }

  /**
   * @dev withdraws the WBNB _reserves of msg.sender.
   * @param amount amount of aWBNB to withdraw and receive native token
   * @param to address of the user who will receive native token
   */
  function withdrawProtectedBNB(
    uint256 amount,
    address to
  ) external {
    IAToken apWBNB = IAToken(POOL.getReserveData(address(pWBNB)).aTokenAddress);
    // transfer aPToken from msg.sender to this contract
    apWBNB.transferFrom(msg.sender, address(this), amount);
    // withdraw aPToken to pToken
    uint256 withdrawnAmount = POOL.withdraw(address(apWBNB), amount, address(this));
    // withdraw the pToken to wToken first
    pWBNB.withdrawTo(address(this), withdrawnAmount);
    // withdraw the wToken to native token
    WBNB.withdraw(withdrawnAmount);
    // transfer BNB back to the caller 
    _safeTransferBNB(to, withdrawnAmount);
  }


  function withdrawBNBWithPermit(
    uint256 amount,
    address to,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external {
    IAToken apWBNB = IAToken(POOL.getReserveData(address(pWBNB)).aTokenAddress);
    // permit `amount` rather than `amountToWithdraw` to make it easier for front-ends and integrators
    apWBNB.permit(msg.sender, address(this), amount, deadline, permitV, permitR, permitS);
    apWBNB.transferFrom(msg.sender, address(this), amount);
    uint256 withdrawnAmount = POOL.withdraw(address(pWBNB), amountToWithdraw, address(this));
    // withdraw the pToken to wToken first
    pWBNB.withdrawTo(address(this), withdrawnAmount);
    // withdraw the wToken to native token
    WBNB.withdraw(withdrawnAmount);
    _safeTransferBNB(to, withdrawnAmount);
  }

  /**
   * @dev transfer native token to an address, revert if it fails.
   * @param to recipient of the transfer
   * @param value the amount to send
   */
  function _safeTransferBNB(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'BNB_TRANSFER_FAILED');
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

  /**
   * @dev transfer native token from the utility contract, for native token recovery in case of stuck token
   * due to selfdestructs or token transfers to the pre-computed contract address before deployment.
   * @param to recipient of the transfer
   * @param amount amount to send
   */
  function emergencyBNBTransfer(address to, uint256 amount) external onlyOwner {
    _safeTransferBNB(to, amount);
  }

  /**
   * @dev Get WBNB address used by WrappedTokenGatewayV3
   */
  function getWBNBAddress() external view returns (address) {
    return address(WBNB);
  }

  /**
   * @dev Only WBNB contract is allowed to transfer BNB here. Prevent other addresses to send BNB to this contract.
   */
  receive() external payable {
    require(msg.sender == address(WBNB), 'Receive not allowed');
  }

}
