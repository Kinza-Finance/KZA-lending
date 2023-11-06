// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

interface IwbETH {
  function exchangeRate() external view returns (uint256);
}