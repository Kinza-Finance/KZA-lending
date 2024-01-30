// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from '@openzeppelin/token/ERC20/IERC20.sol';
import "@openzeppelin/access/Ownable.sol";

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
contract ReserveDistributor is Ownable {

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

    IPool public immutable pool;
    IAaveOracle public immutable oracle;

    bool public pause;
    
    // cannot be greater than 100%/10000
    uint256 currentRecipientTotalPercentage = 0;

    mapping(address => Recipient) public recipients;
    // be referenced as a base before a distribution is called
    mapping(address => uint256) public currentBalances;
    // be referenced whenever a receipient is added
    mapping(address => uint256) public accumulateBalances;

    event updateRecipient(uint256 percentage, address recipient);
    event NewTailorPercentage(address[] assets, uint256[] percentages, address recipient);
    event Claimed(address recipient, uint256 notional);
    event Pause(bool status);
    

    modifier whenNotPaused() {
        require(!pause);
        _;
    }

    constructor(address _pool, address _oracle) {
        pool = IPool(_pool);
        oracle = IAaveOracle(_oracle);
    }

    /*//////////////////////////////////////////////////////////////
                                OWNABLE
    //////////////////////////////////////////////////////////////*/
    // owner can decide to transfer out asset, bypassing the distribution (as an emergency)
    function emergencyTransfer(
        IERC20 _token,
        address _recipient,
        uint256 _amount
    ) external onlyOwner {
        _token.transfer(_recipient, _amount);
    }

    function setPause(bool status) external onlyOwner {
        pause = status;
        emit Pause(status);
    }

    function addRecipient(uint256 _percentage, address _recipient) external onlyOwner {
        require(_percentage + currentRecipientTotalPercentage <= MAX_PERCENTAGE, "over-allocate");
        _mintAllReservesAndSync();
        Recipient storage r = recipients[_recipient];
        r.percentage = _percentage;
        // when a user get added/re-added, user get checkpointed against latest balance.
        _syncUserCheckpoint(_recipient);
        emit updateRecipient(_percentage, _recipient);
    }

    // this is to update recipient percentage, would claim all claimable for user, and then update percentage
    function updateRecipient(uint256 _percentage, address _recipient) external onlyOwner {
        Recipient storage r = recipients[_recipient];
        require(r.percentage > 0, "pls call addRecipient");
        // give out what the recipient deserves;
        _mintAllReservesAndSync();
        _claim(_recipient);
        currentRecipientTotalPercentage -= r.percentage;
        if (_percentage > 0) {
            currentRecipientTotalPercentage += _percentage;
        }
        require(currentRecipientTotalPercentage <= MAX_PERCENTAGE);
        // blacklist/tailor percentage config would persist when the user gets updated to 0
        // in the meanTime the user cannot accrue reserves
        // it's possible that tailorPercentage can be bigger than the new percentage after updating
        emit updateRecipient(_percentage, _recipient);
    }

    function setRecipientTailorPercentage(address[] memory _assets, uint256[] memory _percentages, address _recipient) external onlyOwner {
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

    /*//////////////////////////////////////////////////////////////
                                CALLABLE
    //////////////////////////////////////////////////////////////*/

    /// @dev a bundled function that recipient can call
    function claim() external whenNotPaused {
        _mintAllReservesAndSync();
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
            uint256 accuredUnAccounted = IERC20(_aToken).balanceOf(address(this)) - currentBalances[assets[i]];
            uint256 claimable = accumulateBalances[assets[i]] - r.lastClaimCheckpoint[assets[i]];
            // if there is a non-zero tailor percentage then use the tailor one
            uint256 percentage = r.tailorReservePercentage[assets[i]] == 0 
                                    ? r.percentage 
                                    : r.tailorReservePercentage[assets[i]];
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
        address[] memory assets = pool.getReservesList();
        Recipient storage r = recipients[_recipient];
        require(r.percentage > 0, "user not eligible");
        uint256[] memory prices = oracle.getAssetsPrices(assets);
        uint256 totalNotional;
        for (uint i; i < assets.length;i++) {
            address _asset = assets[i];
            address _aToken = _getReserveData(_asset).aTokenAddress;
            uint256 claimable = accumulateBalances[_asset] - r.lastClaimCheckpoint[_asset];
            // if there tailor percentage then use the tailor one
            uint256 percentage = r.tailorReservePercentage[_asset] == 0 
                                    ? r.percentage 
                                    : r.tailorReservePercentage[_asset];
            uint256 userPortion = claimable * percentage / MAX_PERCENTAGE;
            // accrual
            r.lastClaimCheckpoint[_asset] = accumulateBalances[_asset];
            // if the reserve is not blacklisted and claimable > 0
            if (userPortion > 0 && r.tailorReservePercentage[_asset] != BLACKLIST_PERCENTAGE) {
                currentBalances[_asset] -= userPortion;
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
            uint256 lastAccumulative = accumulateBalances[_asset];
            uint256 lastCurrent = currentBalances[_asset];
            // expect an increment during mintToTreasury.
            accumulateBalances[_asset] = lastAccumulative + currentBalance - lastCurrent;
            // than sync current balance
            currentBalances[_asset] = currentBalance;
        }
    }

    function _syncUserCheckpoint(address _recipient) internal {
         Recipient storage r = recipients[_recipient];
         address[] memory assets = pool.getReservesList();
         for (uint i; i < assets.length; i++) {
            address _asset = assets[i];
            r.lastClaimCheckpoint[_asset] = accumulateBalances[_asset];
         }
    }
    
    function _getReserveData(address _asset) internal view returns(DataTypes.ReserveData memory) {
        return pool.getReserveData(_asset);
    }

}