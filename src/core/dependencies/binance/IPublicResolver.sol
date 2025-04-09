// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * A more advanced resolver that allows for multiple records of the same domain.
 */
interface IPublicResolver {
    function addr(bytes32 node) external view returns (address payable);

    function addr(bytes32 node, uint256 coinType) external view returns (bytes memory);

}

