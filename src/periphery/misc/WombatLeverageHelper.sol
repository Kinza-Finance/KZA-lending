import '../../core/interfaces/IPoolAddressesProvider.sol';
import '../../core/interfaces/IPool.sol';
import '../../core/interfaces/IAaveOracle.sol';
import {IERC20} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol';


// just need one function rather use it here
interface IBorrowableProvider {
    function getUserMaxBorrowable(address user, address asset) external view returns(uint256);
}

interface IWombatPool {
    function deposit(address underlying, uint256 amount, uint256 minLiquidity, address receiver, uint256 expiry, bool isStaked) external;
}

// just need one function for wombat LP Asset
interface IAsset  {
    function underlyingToken() external view returns(address);

}

contract WombatLeverageHelper {
    // return from borrowable provider is 10 ** 8;
    uint256 constant public BORROWABLE_MULTIPLIER = 10 ** 10;
    IPoolAddressesProvider immutable public provider;
    IPool immutable public pool;
    constructor(address _provider) {
        provider = IPoolAddressesProvider(_provider);
        pool = IPool(IPoolAddressesProvider(_provider).getPool());
    }

    // LP and underlying is assumed to be 1:1  
    // in reality it depends on the conversion ratio on wombatPool
    function calculateUnderlyingBorrow(uint256 targetHF, address lpAddr, uint256 depositAmount, uint8 emodeCategory) public view returns(uint256) {
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

    function calculateTarsgetedHF(uint256 targetedBorrow, address lpAddr, uint256 depositAmount, uint8 emodeCategory) public view returns(uint256) {
        address underlying = IAsset(lpAddr).underlyingToken();
        (uint256 underlyingPrice, uint256 lpPrice) = getPrice(underlying, lpAddr);
        uint256 emodeLiqT = uint256(pool.getEModeCategoryData(emodeCategory).liquidationThreshold);
        return 1e18 * (targetedBorrow + depositAmount) * emodeLiqT * lpPrice / (targetedBorrow * underlyingPrice);
    }

    function depositUnderlyingAndLoop(address borrowableProvider, address wombatPool, uint256 targetHF, address lpAddr, uint256 amount, uint8 emodeCategory, uint256 slippage) external returns (uint256) {
        address underlying = IAsset(lpAddr).underlyingToken();
        (uint256 underlyingPrice, uint256 lpPrice) = getPrice(underlying, lpAddr);
        IERC20(underlying).transferFrom(msg.sender, address(this), amount);
        // initial approval
        _checkWombatAllowance(underlying, wombatPool);
        _checkPoolAllowance(lpAddr);
        require(slippage <= 10000, "slippage too big");
        IWombatPool(wombatPool).deposit(
            underlying,
            amount,
            // apply 10 bp slippage for minLiq,
            // with ref to relative lpPrice and underlyingPrice
            amount * lpPrice * (10000 - slippage) / underlyingPrice / 10000,
            address(this),
            block.timestamp,
            false
            );
        uint256 lpCollected = IERC20(lpAddr).balanceOf(address(this));
        pool.deposit(lpAddr, lpCollected, msg.sender, 0);
        return _loop(borrowableProvider, wombatPool, targetHF, lpAddr, amount, emodeCategory, slippage);
    }

    function depositLpAndLoop(address borrowableProvider, address wombatPool, uint256 targetHF, address lpAddr, uint256 amount, uint8 emodeCategory, uint256 slippage) external returns (uint256) {
        require(slippage <= 10000, "slippage too big");
        address underlying = IAsset(lpAddr).underlyingToken();
        IERC20(lpAddr).transferFrom(msg.sender, address(this), amount);
        _checkWombatAllowance(underlying, wombatPool);
        _checkPoolAllowance(lpAddr);
        pool.deposit(lpAddr, amount, msg.sender, 0);
        return _loop(borrowableProvider, wombatPool, targetHF, lpAddr, amount, emodeCategory, slippage);
    }

    // assume the user already deposited the LP or have some collateral power
    function Loop(address borrowableProvider, address wombatPool, uint256 targetHF, address lpAddr, uint256 amount, uint8 emodeCategory, uint256 slippage) external returns (uint256) {
        require(slippage <= 10000, "slippage too big");
        address underlying = IAsset(lpAddr).underlyingToken();
        _checkWombatAllowance(underlying, wombatPool);
        _checkPoolAllowance(lpAddr);
        return _loop(borrowableProvider, wombatPool, targetHF, lpAddr, amount, emodeCategory, slippage);
    }
    // this function just leverage by borrowing underlying for the user
    // and loop the needed borrowedAmount by re-depositing back the lp
    // the final health factor may vary from the targetHF
    // since the deposited LP might be different depends on wombat
    function _loop(address borrowableProvider, address wombatPool, uint256 targetHF, address lpAddr, uint256 amount, uint8 emodeCategory, uint256 slippage) internal returns(uint256) {
        
        require(targetHF > 1e18 && amount > 0, "targetHF or deposit amount invalid");
        address underlying = IAsset(lpAddr).underlyingToken();
        (uint256 underlyingPrice, uint256 lpPrice) = getPrice(underlying, lpAddr);
        uint256 borrowTotal = calculateUnderlyingBorrow(targetHF, lpAddr, amount,  emodeCategory);
        uint256 borrowed;
        while(borrowed < borrowTotal) {
            // start borrow
            uint256 diff = borrowTotal - borrowed;
            // the return is 10 * 8 from borrowableProvider
            uint256 toBorrow = BORROWABLE_MULTIPLIER * IBorrowableProvider(borrowableProvider).getUserMaxBorrowable(msg.sender, underlying);
            if (toBorrow == 0) {
                // somehow the user can not borrow anymore
                // can be due to other existing borrow, or debt ceiling/available in the protocol
                break;
            }
            if (toBorrow > diff) {
                toBorrow = diff;
            }
            borrowed += toBorrow;
            // 2 = variable interest rate, 0 = referral code
            pool.borrow(underlying, toBorrow, 2, 0, msg.sender);
            // convert to LP on wombat
            IWombatPool(wombatPool).deposit(
            underlying,
            toBorrow,
            // apply 10 bp slippage for minLiq,
            // with ref to relative lpPrice and underlyingPrice
            toBorrow * lpPrice * (10000 - slippage) / underlyingPrice / 10000,
            address(this),
            block.timestamp,
            false
            );
            // deposit the LP into pool
            uint256 amount = IERC20(lpAddr).balanceOf(address(this));
            pool.deposit(lpAddr, amount, msg.sender, 0);
        }
        return borrowed;
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

   function _checkWombatAllowance(address underlying, address wombatPool) internal {
        if (IERC20(underlying).allowance(wombatPool, address(this)) == 0) {
            IERC20(underlying).approve(wombatPool, type(uint256).max);
        }
   }

}