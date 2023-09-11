// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IMasterWombat {
    function multiClaim(uint256[] calldata pids) external;
    function deposit(uint256 pid, uint256 amount) external;
    function withdraw(uint256 pid, uint256 amount) external;
    function getAssetPid(address asset) external view returns (uint256);
    function poolInfo(uint256 pid) external view returns (address, address, uint40, uint128, uint128, uint104, uint104, uint40);
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