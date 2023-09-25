import '../../core/interfaces/IPoolAddressesProvider.sol';
import '../../core/interfaces/IPool.sol';
import '../../core/interfaces/IPoolDataProvider.sol';
import '../../core/interfaces/IAaveOracle.sol';
import {IERC20} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {Ownable} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/Ownable.sol';


// just need one function rather use it here
interface IBorrowableProvider {
    function getUserMaxBorrowable(address user, address asset) external view returns(uint256);
}

interface IWombatPool {
    function deposit(address underlying, uint256 amount, uint256 minLiquidity, address receiver, uint256 expiry, bool isStaked) external;
    function withdraw(address undelying, uint256 amount, uint256 minOutput, address receiver, uint256 expiry) external;
}

// just need one function for wombat LP Asset
interface IAsset  {
    function underlyingToken() external view returns(address);

}

contract WombatLeverageHelper is Ownable {
    uint256 constant public MAX_SLIPPAGE = 10000;
    IPoolAddressesProvider immutable public provider;
    IPool immutable public pool;
    IPoolDataProvider immutable public dataProvider;
    mapping(address => bool) public whitelistedPool;

    event WhitelistChanged(address pool, bool status);

    modifier onlyPool() {
        require(msg.sender == address(pool));
        _;
    }

    constructor(address _provider, address _dataProvider) {
        provider = IPoolAddressesProvider(_provider);
        pool = IPool(IPoolAddressesProvider(_provider).getPool());
        dataProvider = IPoolDataProvider(_dataProvider);
    }

    function setWhitelist(address wombatPool, bool status) external onlyOwner {
        emit WhitelistChanged(wombatPool, status);
        whitelistedPool[wombatPool] = status;
    }

    function calculateToBorrowWithHF(uint256 targetHF, address lpAddr, uint256 depositAmount, uint8 emodeCategory) public view returns(uint256) {
        address underlying = IAsset(lpAddr).underlyingToken();
        (uint256 underlyingPrice, uint256 lpPrice) = getPrice(underlying, lpAddr);
        // assume a person without any other position
        uint256 emodeLiqT = uint256(pool.getEModeCategoryData(emodeCategory).liquidationThreshold);
        // targetHF = depositTotal * emodeLiqT / borrowedUnderlyingTotal
        // targetHF = (deposit + borrow) * emodeLiqT * lpPrice / borrow * underlyingPrice
        // targetHF = (deposit * LiqT * lpPrice) / borrow * underlyingPrice + LiqT * emodeLiqT / underlyingPrice
        // after refactor: the constant part => depositRatio.
        uint256 depositRatio = targetHF - 1e18 * lpPrice * emodeLiqT / underlyingPrice / 10000;
        return 1e18 * depositAmount * lpPrice * emodeLiqT / (depositRatio * underlyingPrice) / 10000;
    }

    function calculateToBorrowWithLev(uint256 targetLev, address lpAddr, uint256 depositAmount) public view returns(uint256) {
        // taregtLev in unit of 100, 3X = 300
        address underlying = IAsset(lpAddr).underlyingToken();
        (uint256 underlyingPrice, uint256 lpPrice) = getPrice(underlying, lpAddr);
        
        return targetLev * depositAmount * lpPrice / underlyingPrice / 100;
    }

    function transferLPAndBorrowWithFlashLoan(address wombatPool, address lpAddr, uint256 amount, uint256 borrowAmount, uint256 minLp) external returns(uint256) {
        require(whitelistedPool[wombatPool], "pool is not whitelisted for flashloan");
        address underlying = IAsset(lpAddr).underlyingToken();
        _checkWombatAllowance(wombatPool, underlying);
        _checkPoolAllowance(lpAddr);
        IERC20(lpAddr).transferFrom(msg.sender, address(this), amount);
        pool.deposit(lpAddr, amount, msg.sender, 0);
        return _borrowWithFlashLoan(wombatPool, lpAddr, underlying, borrowAmount, minLp);
    }

    function transferUnderlyingAndBorrowWithFlashLoan(address wombatPool, address lpAddr, uint256 amount, uint256 borrowAmount, uint256 minLp, uint256 slippage) external returns(uint256) {
        require(whitelistedPool[wombatPool], "pool is not whitelisted for flashloan");
        address underlying = IAsset(lpAddr).underlyingToken();
        _checkWombatAllowance(wombatPool, underlying);
        _checkPoolAllowance(lpAddr);
        (uint256 underlyingPrice, uint256 lpPrice) = getPrice(underlying, lpAddr);
        IERC20(underlying).transferFrom(msg.sender, address(this), amount);
        IWombatPool(wombatPool).deposit(
            underlying,
            amount,
            // apply 10 bp slippage for minLiq,
            // with ref to relative lpPrice and underlyingPrice
            amount * lpPrice * (MAX_SLIPPAGE - slippage) / underlyingPrice / MAX_SLIPPAGE,
            address(this), // receiver 
            block.timestamp, // expiry
            false // isStaked
            );
        uint256 receivedAmount = IERC20(lpAddr).balanceOf(address(this));
        pool.deposit(lpAddr, receivedAmount, msg.sender, 0);
        return _borrowWithFlashLoan(wombatPool, lpAddr, underlying, borrowAmount, minLp);
    }

    function borrowWithFlashLoan(address wombatPool, address lpAddr, uint256 boorowAmount, uint256 minLp) external returns(uint256) {
        //require(whitelistedPool[wombatPool], "pool is not whitelisted for flashloan");
        address underlying = IAsset(lpAddr).underlyingToken();
        _checkWombatAllowance(wombatPool, underlying);
        _checkPoolAllowance(lpAddr);
        return _borrowWithFlashLoan(wombatPool, lpAddr, underlying, boorowAmount, minLp);
    }
    // this function is the main entry to flashloan the udnerlying which then get deposited into wombat,
    // the LP is then deposited back into the protocol for collateralization
    function _borrowWithFlashLoan(address wombatPool, address lpAddr, address underlying, uint256 amount, uint256 minLp) internal returns(uint256) {
        // only 1 asset is allowed at a time, 
        // we are just leveraging the borrow feature of the multi-flasloan interface
        (address aToken,,) = dataProvider.getReserveTokensAddresses(underlying);
        uint256 depositBefore = IERC20(aToken).balanceOf(msg.sender);
        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        uint256[] memory interestRateModes = new uint256[](1);
        assets[0] = underlying;
        amounts[0] = amount;
        interestRateModes[0] = 2; // 2 variable; 1 is fixed; this helper only works with variable

        // allow the pool to get back the flashloan + premium
        _checkPoolAllowance(underlying);
        //construct calldata to be execute in "executeOperation
        // swapData is only necessarily when route is "CUSTOM", otherwise it can be left as emptied
        // function flashLoan(
        //     address receiverAddress,
        //     address[] calldata assets,
        //     uint256[] calldata amounts,
        //     uint256[] calldata interestRateModes,
        //     address onBehalfOf,
        //     bytes calldata params,
        //     uint16 referralCode
        // )
        bool isDeposit = true;
        // this value is only applicable for withdraw
        uint256 withdrawAmount = 0;
        bytes memory params = abi.encode(
           msg.sender, wombatPool, lpAddr, underlying, isDeposit, withdrawAmount);
        pool.flashLoan(
            address(this), //receiver
            assets, // assset to borrow
            amounts, // amount to borrow
            interestRateModes, // 2 variable, 1 fixed
            msg.sender, // depositor / onBehalfOf
            params,
            0
        );
        // return the amount of lp deposited as a result of the borrow
        // so integration can be done to ensure the output is acceptable
        uint256 deposited = IERC20(aToken).balanceOf(msg.sender) - depositBefore;
        require(minLp <= deposited, "output less than minLP required");
        return deposited;
    }

    // this is the callback from flashloan
    // depends on the params, would proceed to deposit or repay using the borrowed fund
    function executeOperation(
    address[] calldata borrowedAssets,
    uint256[] calldata amounts,
    uint256[] calldata premium,
    address, //initiator, which would be this address if called from borrowWithFlashLoan
    bytes memory params
  )  external onlyPool returns (bool){
        (address depositor, address wombatPool, address lpAddr, address underlying, bool isDeposit, uint256 withdrawAmount) = 
        abi.decode(params, (address, address, address, address, bool, uint256));
        (uint256 underlyingPrice, uint256 lpPrice) = getPrice(underlying, lpAddr);
        // deposit into wombat    
        uint256 borrowed = IERC20(underlying).balanceOf(address(this));
        if (isDeposit) {
            _checkWombatAllowance(wombatPool, underlying);
            _checkPoolAllowance(lpAddr);
            IWombatPool(wombatPool).deposit(
            underlying,
            borrowed,
            0, //minOutput, this is enforced on the flashloan execution context
            address(this), // receiver 
            block.timestamp, // expiry
            false // isStaked
            );
            // deposit the LP into pool for the user
            uint256 amount = IERC20(lpAddr).balanceOf(address(this));
            pool.deposit(lpAddr, amount, depositor, 0);
        }
        // the flashloan fund would be used to repay the debt
        // and then deposit would be withdrawn and converted back to the underlying
        // approve the levHelper to pull aToken of lp in advance
        else {
            _checkWombatAllowance(wombatPool, lpAddr);
            pool.repay(underlying, borrowed, 2, depositor);
            // remove LP
            // pull aToken of LP
            (address aToken,,) = dataProvider.getReserveTokensAddresses(lpAddr);
            IERC20(aToken).transferFrom(depositor, address(this), withdrawAmount);
            pool.withdraw(lpAddr, withdrawAmount, address(this));
            IWombatPool(wombatPool).withdraw(
            underlying,
            withdrawAmount,
            0, //minOutput, if it is not enough to cover the flashloan would revert
            address(this), // receiver 
            block.timestamp // expiry
            );
        }
        return true;
    }

    // return the excess amount that is sent back to user
    // the caller should pass just enough withdrawAmount of LP to cover the repayAmount of underlying
    // even though additional amount would be sent back, MEV may occur during the swap
    function repayWithFlashLoan(address wombatPool, address lpAddr, uint256 withdrawAmount, uint256 targetRepay) external returns(uint256) {
        require(whitelistedPool[wombatPool], "pool is not whitelisted for flashloan");
        address underlying = IAsset(lpAddr).underlyingToken();
        (address aToken,,) = dataProvider.getReserveTokensAddresses(lpAddr);
        uint256 depositBefore = IERC20(aToken).balanceOf(msg.sender);
        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        uint256[] memory interestRateModes = new uint256[](1);
        assets[0] = underlying;
        amounts[0] = targetRepay;
        interestRateModes[0] = 0; // 2 variable; 1 is fixed, 0 is returning within the same block

        // allow the pool to get back the flashloan + premium
        _checkPoolAllowance(underlying);
        //construct calldata to be execute in "executeOperation
        // swapData is only necessarily when route is "CUSTOM", otherwise it can be left as emptied
        // function flashLoan(
        //     address receiverAddress,
        //     address[] calldata assets,
        //     uint256[] calldata amounts,
        //     uint256[] calldata interestRateModes,
        //     address onBehalfOf,
        //     bytes calldata params,
        //     uint16 referralCode
        // )
        bool isDeposit = false;
        bytes memory params = abi.encode(
           msg.sender, wombatPool, lpAddr, underlying, isDeposit, withdrawAmount);
        pool.flashLoan(
            address(this), //receiver
            assets, // assset to borrow
            amounts, // amount to borrow
            interestRateModes, // 2 variable, 1 fixed
            msg.sender, // depositor / onBehalfOf
            params,
            0
        );
        // execution succeeds by now, additional underlying should be transferred back to caller
        uint256 excess = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).transfer(msg.sender, excess);
        return excess;
    }
    function getPrice(address underlying, address lp) public view returns(uint256, uint256) {
        IAaveOracle oracle = IAaveOracle(provider.getPriceOracle());
        address[] memory assets = new address[](2);
        assets[0] = underlying;
        assets[1] = lp;
        uint256[] memory prices = oracle.getAssetsPrices(assets);
        return (prices[0], prices[1]);
  }

   function _checkPoolAllowance(address lpAddr) internal {
        if (IERC20(lpAddr).allowance(address(pool), address(this)) == 0) {
            IERC20(lpAddr).approve(address(pool), type(uint256).max);
        }
   }

   function _checkWombatAllowance(address wombatPool, address underlying) internal {
        if (IERC20(underlying).allowance(address(wombatPool), address(this)) == 0) {
            IERC20(underlying).approve(address(wombatPool), type(uint256).max);
        }
   }
   

}