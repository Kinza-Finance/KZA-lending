// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

interface ITWAPAggregator {
    function getTWAP() external view returns (uint256);
}
