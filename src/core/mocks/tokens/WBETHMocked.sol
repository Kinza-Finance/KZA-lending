// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {ERC20} from '../../dependencies/openzeppelin/contracts/ERC20.sol';
contract WBETHMocked is ERC20 {
  // Mint not backed by Ether: only for testing purposes
  address public owner;
  uint256 public exchangeRate;

  constructor() ERC20("Wrapped Binance Beacon ETH", "wBETH"){
    owner = msg.sender;
    exchangeRate = 1.008 * 10 ** 18;
  }

  function updateExchangeRate(uint256 new_rate) external {
    require(msg.sender == owner);
    exchangeRate = new_rate;
    }
}
