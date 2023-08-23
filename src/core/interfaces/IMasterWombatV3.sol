interface IMasterWombatV3 {
    function deposit(uint256 pid, uint256 amonut) external;
    function withdraw(uint256 pid, uint256 amonut) external;
    function emergecnyWithdraw(uint256 pid) external;

}