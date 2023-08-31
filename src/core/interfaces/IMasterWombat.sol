interface IMasterWombat {
    function multiClaim(uint256[] calldata pids) external;
    function deposit(uint256 pid, uint256 amount) external;
    function withdraw(uint256 pid, uint256 amount) external;
    function getAssetPid(address asset) external returns(uint256);
}