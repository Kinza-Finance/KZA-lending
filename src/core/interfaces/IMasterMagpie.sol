interface IMasterMagpie {
    function multiClaim(address[] memory stakingTokens) external;
    function withdraw(address stakingToken, uint256 amount) external;

}