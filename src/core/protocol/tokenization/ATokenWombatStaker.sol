// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {IMasterWombat} from '../../interfaces/IMasterWombat.sol';
import {IEmissionAdmin} from '../../interfaces/IEmissionAdmin.sol';
import {IPool} from '../../interfaces/IPool.sol';
import {AToken} from './AToken.sol';

/**
 * @notice Implementation of the AToken with the underlying LP staked 
 *          stake on an external gauge; rewards are claimed to the Atoken proxy
 *          and distributed upon the discretion of an admin
 */
contract ATokenWombatStaker is AToken {
  using GPv2SafeERC20 for IERC20;
  uint256 public _pid;
  IMasterWombat public _masterWombat;
  // manage emission on internal EmissionManager
  address public _emissionAdmin;
  mapping(address => bool) public whitelist;
  bool public isOpenForEveryone;
  bool public isInEmergency;
  event StakingRewardClaimed();
  event OpenForEveryoneChanged(bool newValue);
  event WhitelistChanged(address dest, bool newValue);
  event EmergencyStateChanged(bool newValue);
  /**
   * @dev Constructor.
   * @param pool The address of the Pool contract
   */
  constructor(
    IPool pool
  ) AToken(pool) {
    // Intentionally left blank
  }

  modifier isWhitelistedOrOpen(address caller) {
    require (isOpenForEveryone || whitelist[caller], "access controlled");
    _;
  }

  // withdraw all LP from the masterWombat
  function toggleEmergencyWithdraw() external onlyPoolAdmin {
    if (isInEmergency) {
      uint256 amount = IERC20(_underlyingAsset).balanceOf(address(this));
      _masterWombat.deposit(_pid, amount);
      isInEmergency = false;
      emit EmergencyStateChanged(false);
    } else {
      (uint128 amount,,,) = _masterWombat.userInfo(_pid, address(this));
      _masterWombat.withdraw(_pid, uint256(amount));
      isInEmergency = true;
      emit EmergencyStateChanged(true);
    }
    
  }

  function toogleOpenForEveryone(bool newOpenForEveryone) external onlyPoolAdmin {
    isOpenForEveryone = newOpenForEveryone;
    emit OpenForEveryoneChanged(newOpenForEveryone);
  }

  function toggleWhitelist(address dest, bool newValue) external onlyPoolAdmin {
    whitelist[dest] = newValue;
    emit WhitelistChanged(dest, newValue);
  }
  function updateMasterWombat(address masterWombat) external onlyPoolAdmin {
    // this is fine since it's a proxy
    require(address(_masterWombat) == address(0), "master can only be set once");
    IERC20(_underlyingAsset).approve(masterWombat, type(uint256).max);
    _masterWombat = IMasterWombat(masterWombat);
    _pid = _masterWombat.getAssetPid(_underlyingAsset);
  }

  function updateEmissionAdmin(address emissionAdmin) external onlyPoolAdmin {
    _emissionAdmin = emissionAdmin;
  }

  function multiClaim() public onlyPoolAdmin {
    uint256[] memory pids = new uint256[](1);
    pids[0] = _pid;
    /// @dev that is no return data from multiclaim; also masterMagpie is a proxy.
    _masterWombat.multiClaim(pids);
    emit StakingRewardClaimed();
  }

  function sendEmission(address[] memory rewards) external onlyPoolAdmin {
    // claim 
    multiClaim();
    uint256[] memory amounts = new uint256[](rewards.length);
    for (uint i; i < rewards.length;) {
      require(rewards[i] != _underlyingAsset, "underlying token cannot be sent as rewards");
      amounts[i] = IERC20(rewards[i]).balanceOf(address(this));
      // avoid unnecessary allowance
      // reward are sent to the corresponding vault
      IERC20(rewards[i]).transfer(_emissionAdmin, amounts[i]);
      unchecked {
        i++;
      }
    }
    // emissionAdmin define the distribution details regarding the reward token
    IEmissionAdmin(_emissionAdmin).notify(rewards, amounts);
  }

  function mint(
    address caller,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external virtual override onlyPool isWhitelistedOrOpen(caller) returns (bool) {
    // helper takes our LP, call wombat staking,
    // then stake the wombat stakingToken on magpie itself
    require(!isInEmergency, "deposit is paused due to emergency");
    _masterWombat.deposit(_pid, amount);
    return _mintScaled(caller, onBehalfOf, amount, index);
  }

  function burn(
    address from,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external virtual override onlyPool {
    address stakingToken = _underlyingAsset;
    // in normal operation, user need to withdraw from masterWombat
    // if in emergency, LP should already be withdrawn from the masterWombat
    if (!isInEmergency) {
      _masterWombat.withdraw(_pid, amount);
    }
    _burnScaled(from, receiverOfUnderlying, amount, index);
    if (receiverOfUnderlying != address(this)) {
      IERC20(_underlyingAsset).safeTransfer(receiverOfUnderlying, amount);
    }
  }

  /// * @dev Used by the Pool to transfer assets in borrow(() and flashLoan() --- not used in withdraw
  function transferUnderlyingTo(address target, uint256 amount) external virtual override onlyPool {
    revert("ATokenStaker does not allow flashloan or borrow");
  }

}
