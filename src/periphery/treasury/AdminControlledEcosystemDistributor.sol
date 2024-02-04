// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import {IERC20} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {VersionedInitializable} from './libs/VersionedInitializable.sol';
import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {ReentrancyGuard} from './libs/ReentrancyGuard.sol';
import {Address} from './libs/Address.sol';

/**
 * @title AdminControlledEcosystemDistributor, adapted from Aave Reserve
 * @notice Stores ERC20 tokens, and allows to dispose of them via approval or transfer dynamics
 * Adapted to be an implementation of a transparent proxy
 * @dev Done abstract to add an `initialize()` function on the child, with `initializer` modifier
 **/
abstract contract AdminControlledEcosystemDistributor is
  VersionedInitializable, Ownable
{
  address internal _fundsAdmin;

  uint256 public constant REVISION = 1;

  address public constant ETH_MOCK_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  
  event NewFundsAdmin(address indexed fundsAdmin);

  modifier onlyFundsAdmin() {
    require(msg.sender == _fundsAdmin, 'ONLY_BY_FUNDS_ADMIN');
    _;
  }

  modifier onlyOwnerOrFundAdmin() {
    require(msg.sender == _fundsAdmin || msg.sender == owner(), "not admin nor owner");
    _;
  }

  function getRevision() internal pure override returns (uint256) {
    return REVISION;
  }

  function getFundsAdmin() external view returns (address) {
    return _fundsAdmin;
  }


  function setFundsAdmin(address admin) external onlyOwner {
    _setFundsAdmin(admin);
  }
  function _setFundsAdmin(address admin) internal {
    _fundsAdmin = admin;
    emit NewFundsAdmin(admin);
  }

  receive() external payable {}

}
