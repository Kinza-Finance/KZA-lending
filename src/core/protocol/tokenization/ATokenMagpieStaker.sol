// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {IMasterMagpie} from '../../interfaces/IMasterMagpie.sol';
import {IWombatHelper} from '../../interfaces/IWombatHelper.sol';
import {IEmissionAdmin} from '../../interfaces/IEmissionAdmin.sol';
import {IPool} from '../../interfaces/IPool.sol';
import {AToken} from './AToken.sol';

/**
 * @notice Implementation of the AToken with the underlying LP staked 
 *          stake on an external gauge; rewards are claimed to the Atoken proxy
 *          and distributed upon the discretion of an admin
 */
contract ATokenMagpieStaker is AToken {
  using GPv2SafeERC20 for IERC20;
  IMasterMagpie public _masterMagpie;
  IWombatHelper public _wombatHelper;
  // manage emission on internal EmissionManager
  address public _emissionAdmin;

  event StakingRewardClaimed();
  /**
   * @dev Constructor.
   * @param pool The address of the Pool contract
   */
  constructor(
    IPool pool
  ) AToken(pool) {
    // Intentionally left blank
  }

  function updateMasterMagpie(address masterMagpie) external onlyPoolAdmin {
    // this is fine since it's a proxy
    require(address(_masterMagpie) == address(0), "masterMagpie can only be set once");
    _masterMagpie = IMasterMagpie(masterMagpie);
  }
  function updateWombatHelper(address wombatHelper) external onlyPoolAdmin {
    // poolHelper can be updated
    // require(address(_wombatHelper) == address(0), "wombatHelper can only be set once");
    address wombatStaking = IWombatHelper(wombatHelper).wombatStaking();
    // wombatHerlp::depositLP would trigger wombatStaking which pull LP token from this contract
    IERC20(_underlyingAsset).approve(wombatStaking, type(uint256).max);
    _wombatHelper = IWombatHelper(wombatHelper);
  }

  function updateEmissionAdmin(address emissionAdmin) external onlyPoolAdmin {
    _emissionAdmin = emissionAdmin;
  }

  function multiClaim() public onlyPoolAdmin {
    address[] memory stakingTokens = new address[](1);
    stakingTokens[0] = _underlyingAsset;
    /// @dev that is no return data from multiclaim; also masterMagpie is a proxy.
    _masterMagpie.multiClaim(stakingTokens);
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
  ) external virtual override onlyPool returns (bool) {
    // helper takes our LP, call wombat staking,
    // then stake the wombat stakingToken on magpie itself
    _wombatHelper.depositLP(amount);
    return _mintScaled(caller, onBehalfOf, amount, index);
  }

  function burn(
    address from,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external virtual override onlyPool {
    address stakingToken = _underlyingAsset;
    _masterMagpie.withdraw(stakingToken, amount);
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
