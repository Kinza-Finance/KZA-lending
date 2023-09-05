// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IMasterWombat {
    function multiClaim(uint256[] calldata pids) external;
    function deposit(uint256 pid, uint256 amount) external;
    function withdraw(uint256 pid, uint256 amount) external;
    function getAssetPid(address asset) external returns(uint256);
    function pendingTokens(
        uint256 _pid,
        address _user
    )
        external
        view
        returns (
            uint256 pendingRewards,
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusRewards
        );
}