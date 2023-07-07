// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface SID {
  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);

  function ttl(bytes32 node) external view returns (uint64);

  function recordExists(bytes32 node) external view returns (bool);

  function isApprovedForAll(address owner, address operator)
  external
  view
  returns (bool);
}