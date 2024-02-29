// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ThenaRouterV2Path is Ownable {
    struct route {
        address from;
        address to;
        bool stable;
    }
    address constant public ETH = 0xE7798f023fC62146e8Aa1b36Da45fb70855a77Ea;
    address constant public WBNB = 0x4200000000000000000000000000000000000006;
    address constant public BTC = 0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2;
    address constant public USDT = 0x9e5AAC1Ba1a2e6aEd6b32689DFcF62A509Ca96f3;
    address constant public FDUSD = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;

    mapping(bytes32 => route[]) public callDataMap;

    event NewPath(address _tokenIn, address _tokenOut, route[] path);

    constructor() {
        
        // ETH => BTC
        callDataMap[keccak256(abi.encode(ETH, BTC))].push(route(ETH, BTC, false));
        // // ETH => BNB
         callDataMap[keccak256(abi.encode(ETH, WBNB))].push(route(ETH, WBNB, false));
        // // ETH => USDT
        // callDataMap[keccak256(abi.encode(ETH, USDT))] = 
        callDataMap[keccak256(abi.encode(ETH, USDT))].push(route(ETH, WBNB, false));
        callDataMap[keccak256(abi.encode(ETH, USDT))].push(route(WBNB, USDT, false));
        // // ETH => FDUSD
        // callDataMap[keccak256(abi.encode(ETH, FDUSD))] = 
        callDataMap[keccak256(abi.encode(ETH, FDUSD))].push(route(ETH, WBNB, false));
        callDataMap[keccak256(abi.encode(ETH, FDUSD))].push(route(WBNB, USDT, false));
        callDataMap[keccak256(abi.encode(ETH, FDUSD))].push(route(USDT, FDUSD, true));

        // // BTC => ETH
        callDataMap[keccak256(abi.encode(BTC, ETH))].push(route(BTC, ETH, false));
        // // BTC => BNB

        callDataMap[keccak256(abi.encode(BTC, WBNB))].push(route(BTC, ETH, false));
        callDataMap[keccak256(abi.encode(BTC, WBNB))].push(route(ETH, WBNB, false));
        // // BTC => USDT
        // callDataMap[keccak256(abi.encode(BTC, USDT))] = 
        callDataMap[keccak256(abi.encode(BTC, USDT))].push(route(BTC, ETH, false));
        callDataMap[keccak256(abi.encode(BTC, USDT))].push(route(ETH, USDT, false));
        // // BTC => BUSD
        // callDataMap[keccak256(abi.encode(BTC, FDUSD))] = 
        callDataMap[keccak256(abi.encode(BTC, FDUSD))].push(route(BTC, ETH, false));
        callDataMap[keccak256(abi.encode(BTC, FDUSD))].push(route(ETH, USDT, false));
        callDataMap[keccak256(abi.encode(BTC, FDUSD))].push(route(USDT, FDUSD, true));

        // // BNB => ETH
        // callDataMap[keccak256(abi.encode(WBNB, ETH))] = 
        callDataMap[keccak256(abi.encode(WBNB, ETH))].push(route(WBNB, ETH, false));
        // // BNB => BTC
        // callDataMap[keccak256(abi.encode(WBNB, BTC))] = 
        callDataMap[keccak256(abi.encode(WBNB, BTC))].push(route(WBNB, ETH, false));
        callDataMap[keccak256(abi.encode(WBNB, BTC))].push(route(ETH, BTC, false));
        // abi.encodePacked(WBNB, ETH, BTC);
        // // BNB => USDT
        callDataMap[keccak256(abi.encode(WBNB, USDT))].push(route(WBNB, USDT, false));
        // abi.encodePacked(WBNB, USDT);
        // // BNB => BUSD
        callDataMap[keccak256(abi.encode(WBNB, FDUSD))].push(route(WBNB, USDT, false));
        callDataMap[keccak256(abi.encode(WBNB, FDUSD))].push(route(USDT, FDUSD, true));
        // // BNB => TUSD

        // // USDT => ETH
        // callDataMap[keccak256(abi.encode(USDT, ETH))] = 
        callDataMap[keccak256(abi.encode(USDT, ETH))].push(route(USDT, WBNB, false));
        callDataMap[keccak256(abi.encode(USDT, ETH))].push(route(WBNB, ETH, false));
        // // USDT => WBETH
        // // USDT => BNB
        // callDataMap[keccak256(abi.encode(USDT, WBNB))] = 
        callDataMap[keccak256(abi.encode(USDT, WBNB))].push(route(USDT, WBNB, false));
        // // USDT => BTC
        // callDataMap[keccak256(abi.encode(USDT, BTC))] = 
        callDataMap[keccak256(abi.encode(USDT, BTC))].push(route(USDT, ETH, false));
        callDataMap[keccak256(abi.encode(USDT, BTC))].push(route(ETH, BTC, false));
        // // USDT => BUSD
        // callDataMap[keccak256(abi.encode(USDT, FDUSD))] = 
        callDataMap[keccak256(abi.encode(USDT, FDUSD))].push(route(USDT, FDUSD, true));
        // // USDT => TUSD

        // // FDUSD => ETH
        callDataMap[keccak256(abi.encode(FDUSD, ETH))].push(route(FDUSD, USDT, true));
        callDataMap[keccak256(abi.encode(FDUSD, ETH))].push(route(USDT, WBNB, false));
        callDataMap[keccak256(abi.encode(FDUSD, ETH))].push(route(WBNB, ETH, false));
        // // FDUSD => BNB
        callDataMap[keccak256(abi.encode(FDUSD, WBNB))].push(route(USDT, WBNB, false));
        // // FDUSD => USDT
        callDataMap[keccak256(abi.encode(FDUSD, USDT))].push(route(FDUSD, USDT, true));
        // abi.encodePacked(FDUSD, USDT);
        // // FDUSD => BTC
        // callDataMap[keccak256(abi.encode(FDUSD, BTC))] = 
        callDataMap[keccak256(abi.encode(FDUSD, BTC))].push(route(FDUSD, USDT, true));
        callDataMap[keccak256(abi.encode(FDUSD, BTC))].push(route(USDT, WBNB, false));
        callDataMap[keccak256(abi.encode(FDUSD, BTC))].push(route(WBNB, BTC, false));

    }
    // path that is generalized off-chain, it's a deterministic path to go pass
    function getPath(address _tokenIn, address _tokenOut) public view returns(route[] memory) {
        require(_tokenIn != _tokenOut);
        bytes32 hash = keccak256(abi.encode(_tokenIn, _tokenOut));
        return callDataMap[hash];
    }

    function updatePath(address _tokenIn, address _tokenOut, route[] memory newPath) external onlyOwner {
        require(_tokenIn != _tokenOut);
        bytes32 hash = keccak256(abi.encode(_tokenIn, _tokenOut));
        delete callDataMap[hash];
        for (uint i; i < newPath.length; i++) {
            callDataMap[hash].push(newPath[i]);
        }
        emit NewPath(_tokenIn, _tokenOut , newPath);
        
    }
}
