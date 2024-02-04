// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {Address} from './libs/Address.sol';
import {IERC20} from '@openzeppelin/token/ERC20/IERC20.sol';
import {AdminControlledEcosystemDistributor} from './AdminControlledEcosystemDistributor.sol';
import {DataTypes} from '../../core/protocol/libraries/types/DataTypes.sol';
import "../../core/interfaces/IPool.sol";
import "../../core/interfaces/IAaveOracle.sol";

// | |/ /_ _| \ | |__  /  / \   
// | ' / | ||  \| | / /  / _ \  
// | . \ | || |\  |/ /_ / ___ \ 
// |_|\_\___|_| \_/____/_/   \_\

/// @notice KZA - Kinza protocol ReserveDistributor
/// @title ReserveDistributor
/// @notice claim reserve from the core lending system as the treasury
contract ReserveDistributor is  AdminControlledEcosystemDistributor {
    using Address for address payable;
    struct Recipient {
        uint256 percentage;
        mapping(address => uint256) lastClaimCheckpoint;
        // if tailor is non zero than it is prioritized over the struct-wide percentage above
        // if it is 10000+1 then the reserve is blacklisted, would just pass
        mapping(address => uint256) tailorReservePercentage;
    }
    /*//////////////////////////////////////////////////////////////
                        CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////////////*/
    uint256 private constant MAX_PERCENTAGE = 10000;
    // as a sign to signal the recipient is blocked from collecting certain reserve(s)
    uint256 private constant BLACKLIST_PERCENTAGE = 10001;

    IPool public pool;
    IAaveOracle public oracle;

    bool public pause;
    address public treasury;
    address[] public allRecipients;

    mapping(address => Recipient) public recipients;
    // be referenced as a base before a distribution is called
    mapping(address => uint256) public currentBalances;
    // be referenced whenever a receipient is added
    mapping(address => uint256) public accumulateBalances;

    event UpdatedRecipient(uint256 percentage, address recipient);
    event NewTailorPercentage(address[] assets, uint256[] percentages, address recipient);
    event Claimed(address recipient, uint256 notional);
    event Pause(bool status);
    

    modifier whenNotPaused() {
        require(!pause);
        _;
    }

    modifier mintAllReservesAndSync() {
        _mintAllReservesAndSync();
        _;
    }


    function initialize(address _pool, address _oracle, address _fundAdmin, address _owner, address _treasury) external initializer {
        pool = IPool(_pool);
        oracle = IAaveOracle(_oracle);
        _setFundsAdmin(_fundAdmin);
        _transferOwnership(_owner);
        treasury = _treasury;
        _addRecipient(MAX_PERCENTAGE, treasury);

     }
    /*//////////////////////////////////////////////////////////////
                                OWNABLE
    //////////////////////////////////////////////////////////////*/
    // owner can transfer out all atoken asset, bypassing the distribution (as an emergency)
    function emergencyTransferAll(
    ) external onlyOwner {
        address[] memory assets = pool.getReservesList();
        for (uint i; i < assets.length;i++) {
            address _asset = assets[i];
            address _aToken = _getReserveData(_asset).aTokenAddress;
            uint256 currentBalance = IERC20(_aToken).balanceOf(address(this));
            IERC20(_aToken).transfer(treasury, currentBalance);
        }
        pause = true;
    }

    // claim for all recipients, and the remaining gets sent to the treasury
    // this is used when there is some smaller tailorPercentage leading to surplus left in this contract
    function sweep() external onlyOwner mintAllReservesAndSync {
        for (uint i; i < allRecipients.length; i++) {
            _claim(allRecipients[i]);
        }
        address[] memory assets = pool.getReservesList();
        for (uint i; i < assets.length;i++) {
            address _asset = assets[i];
            address _aToken = _getReserveData(_asset).aTokenAddress;
            uint256 currentBalance = IERC20(_aToken).balanceOf(address(this));
            IERC20(_aToken).transfer(treasury, currentBalance);
        }
    }

    function updateTreasury(address _newTreasury) external onlyOwner mintAllReservesAndSync {
        _claim(treasury);
        Recipient storage t = recipients[treasury];
        uint256 percentage = t.percentage;
        treasury = _newTreasury;
        // original percentage would be offset automatically
        _addRecipient(percentage, _newTreasury);
        
    }

    function setPause(bool status) external onlyOwner {
        pause = status;
        emit Pause(status);
    }

     // rescue non-reserve assets
    function transfer(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external onlyOwnerOrFundAdmin {
        require(recipient != address(0), 'INVALID_0X_RECIPIENT');

        if (address(token) == ETH_MOCK_ADDRESS) {
        payable(recipient).sendValue(amount);
        } else {
            uint256 currentBalance = currentBalances[address(token)];
            // if this is one of the reserve asset
            if (currentBalance > 0) {
                revert("pls transfer reserve asset using claim");
            }
            token.transfer(recipient, amount);
        }
    }
    function addRecipient(uint256 _percentage, address _recipient) external onlyOwnerOrFundAdmin mintAllReservesAndSync {
        _claim(treasury);
        Recipient storage t = recipients[treasury];
        // since treasury is initialized with 100%, so over-allocation would lead to underflow
        t.percentage -= _percentage;
        _addRecipient(_percentage, _recipient);
        
    }

    function _addRecipient(uint256 _percentage, address _recipient) internal {
        Recipient storage r = recipients[_recipient];
        require(r.percentage == 0, "recipient is aldy added");
        r.percentage = _percentage;
        // when a user get added/re-added, user get checkpointed against latest balance.
        _syncUserCheckpoint(_recipient);
        allRecipients.push(_recipient);
        emit UpdatedRecipient(_percentage, _recipient);
    }

    // this is to update recipient percentage, would claim all claimable for user, and then update percentage
    function updateRecipient(uint256 _percentage, address _recipient) external onlyOwnerOrFundAdmin mintAllReservesAndSync {
        Recipient storage r = recipients[_recipient];
        require(r.percentage > 0, "pls call addRecipient");
        // give out what the recipient deserves;
        _claim(_recipient);
        _claim(treasury);
        uint256 originalPercentage = r.percentage;
        Recipient storage t = recipients[treasury];
        // since treausry is initialized with 100%, so over-allocation would lead to underflow
        t.percentage = t.percentage + originalPercentage - _percentage;
        r.percentage = _percentage;
        // blacklist/tailor percentage config would persist when the user gets updated to 0
        // in the meanTime the user cannot accrue reserves
        // it's possible that tailorPercentage can be bigger than the new percentage after updating
        emit UpdatedRecipient(_percentage, _recipient);
    }

    function setRecipientTailorPercentage(address[] memory _assets, uint256[] memory _percentages, address _recipient) external onlyOwnerOrFundAdmin {
        require(_assets.length == _percentages.length, "input validation fails");
        Recipient storage r = recipients[_recipient];
        for (uint i; i < _assets.length; i++) {
            address asset = _assets[i];
            // if the reserve is not set to be blacklisted
            if (_percentages[i] != BLACKLIST_PERCENTAGE) {
                // as a strict requirement the tailor can only be smaller than the total
                require(_percentages[i] <= r.percentage, "tailor exceeds reicpient allocation");
            }
            r.tailorReservePercentage[asset] = _percentages[i];
        }
        emit NewTailorPercentage(_assets, _percentages, _recipient);
    }

    function claimFor(address _recipient) external onlyOwnerOrFundAdmin mintAllReservesAndSync {
        _claim(_recipient);
    }

    /*//////////////////////////////////////////////////////////////
                                CALLABLE
    //////////////////////////////////////////////////////////////*/

    /// @dev a bundled function that recipient can call
    function claim() external whenNotPaused mintAllReservesAndSync {
        _claim(msg.sender);
    }
    /*//////////////////////////////////////////////////////////////
                                VIEW
    //////////////////////////////////////////////////////////////*/
    function viewClaimable(address _recipient) public view returns(address[] memory, uint256[] memory, uint256) {
        address[] memory assets = pool.getReservesList();
        uint256[] memory prices = oracle.getAssetsPrices(assets);
        uint256[] memory amounts = new uint256[](assets.length);
        uint256 totalNotional;
        Recipient storage r = recipients[_recipient];
        for (uint256 i; i < assets.length; i++) {
            uint256 accuredUnminted = _getReserveData(assets[i]).accruedToTreasury;
            address _aToken = _getReserveData(assets[i]).aTokenAddress;
            uint256 accuredUnAccounted = IERC20(_aToken).balanceOf(address(this)) - currentBalances[_aToken];
            uint256 claimable = accumulateBalances[_aToken] - r.lastClaimCheckpoint[_aToken];
            // if there is a non-zero tailor percentage then use the tailor one
            uint256 percentage = r.tailorReservePercentage[_aToken] == 0 
                                    ? r.percentage 
                                    : r.tailorReservePercentage[_aToken];
            if (percentage != BLACKLIST_PERCENTAGE) {
                amounts[i] = (claimable + accuredUnminted + accuredUnAccounted) * percentage / MAX_PERCENTAGE;
            } else {
                // if the recipient is blocked from receiving this asset then the claimable is 0
                amounts[i] = 0;
            }
            // amount in 10**18, prices in 10**8
            totalNotional += amounts[i] * prices[i] / 10 ** 26;
        }
        return (assets, amounts, totalNotional);
    }
    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    ///
    function _claim(address _recipient) internal {
        Recipient storage r = recipients[_recipient];
        if (r.percentage == 0) {
            return;
        }
        address[] memory assets = pool.getReservesList();
        uint256[] memory prices = oracle.getAssetsPrices(assets);
        uint256 totalNotional;
        for (uint i; i < assets.length;i++) {
            address _asset = assets[i];
            address _aToken = _getReserveData(_asset).aTokenAddress;
            uint256 claimable = accumulateBalances[_aToken] - r.lastClaimCheckpoint[_aToken];
            // if there tailor percentage then use the tailor one
            uint256 percentage = r.tailorReservePercentage[_aToken] == 0 
                                    ? r.percentage 
                                    : r.tailorReservePercentage[_aToken];
            uint256 userPortion = claimable * percentage / MAX_PERCENTAGE;
            // accrual
            r.lastClaimCheckpoint[_aToken] = accumulateBalances[_aToken];
            // if the reserve is not blacklisted and claimable > 0
            if (userPortion > 0 && r.tailorReservePercentage[_aToken] != BLACKLIST_PERCENTAGE) {
                currentBalances[_aToken] -= userPortion;
                IERC20(_aToken).transfer(_recipient, userPortion);
                // only for offchain aggregation/statistic
                totalNotional += userPortion * prices[i] / 10**26;
            }
        }
        emit Claimed(_recipient, totalNotional);
    }

    function _mintAllReservesAndSync() internal {
        address[] memory assets = pool.getReservesList();
        IPool(pool).mintToTreasury(assets);
        _syncNewMint(assets);
    }

    function _syncNewMint(address[] memory assets) internal {
        for (uint i; i < assets.length;i++) {
            address _asset = assets[i];
            address _aToken = _getReserveData(_asset).aTokenAddress;
        // account for the increment 
            uint256 currentBalance = IERC20(_aToken).balanceOf(address(this));
            uint256 lastAccumulative = accumulateBalances[_aToken];
            uint256 lastCurrent = currentBalances[_aToken];
            // expect an increment during mintToTreasury. otherwise revert
            require(currentBalance >= lastCurrent, "balance decreases from last sync");
            accumulateBalances[_aToken] = lastAccumulative + currentBalance - lastCurrent;
            // than sync current balance
            currentBalances[_aToken] = currentBalance;
        }
    }

    function _syncUserCheckpoint(address _recipient) internal {
         Recipient storage r = recipients[_recipient];
         address[] memory assets = pool.getReservesList();
         for (uint i; i < assets.length; i++) {
            address _asset = assets[i];
            address _aToken = _getReserveData(_asset).aTokenAddress;
            r.lastClaimCheckpoint[_aToken] = accumulateBalances[_aToken];
         }
    }
    
    function _getReserveData(address _asset) internal view returns(DataTypes.ReserveData memory) {
        return pool.getReserveData(_asset);
    }
}