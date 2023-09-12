import '../../core/interfaces/IPoolAddressesProvider.sol';
import '../../core/interfaces/IPool.sol';
import '../../core/interfaces/IAaveOracle.sol';
import '../../core/interfaces/IMasterWombat.sol';
import {IERC20} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol';


// just need one function rather use it here
interface IBorrowableProvider {
    function getUserMaxBorrowable(address user, address asset) external view returns(uint256);
}

// just need one function for wombat LP Asset
interface IAsset  {
    function underlyingToken() external view returns(address);

}

contract WombatLeverageHelper {
    IPoolAddressesProvider immutable public provider;
    IMasterWombat public masterWombat;
    IPool public pool;
    constructor(address _provider, address _masterWombat) {
        provider = IPoolAddressesProvider(_provider);
        pool = IPool(IPoolAddressesProvider(_provider).getPool());
        masterWombat = IMasterWombat(_masterWombat);
    }

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
    // this function just leverage by borrowing underlying for the user
    // and loop the needed borrowedAmount by re-depositing back the lp
    // the final health factor may vary from the targetHF
    // since the deposited LP might be different depends on wombat
    function loop(address borrowableProvider, uint256 targetHF, address lpAddr, uint256 amount, uint8 emodeCategory, bool isFirstDeposit) external returns(uint256) {
        require(targetHF > 1e18 && amount > 0, "targetHF or deposit amount invalid");
        address underlying = IAsset(lpAddr).underlyingToken();
        uint256 pid = masterWombat.getAssetPid(lpAddr);
        (uint256 underlyingPrice, uint256 lpPrice) = getPrice(underlying, lpAddr);
        uint256 borrowTotal = calculateUnderlyingBorrow(targetHF, lpAddr, amount,  emodeCategory);
        // all borrow would be deposited to mastwombat first
        if (IERC20(underlying).allowance(address(masterWombat), address(this)) < borrowTotal) {
            IERC20(underlying).approve(address(masterWombat), type(uint256).max);
        }
        // all borrow would be deposited to pool at the end
        if (IERC20(lpAddr).allowance(address(pool), address(this)) < borrowTotal) {
            IERC20(lpAddr).approve(address(pool), type(uint256).max);
        }
        if (isFirstDeposit) {
            IERC20(underlying).transferFrom(msg.sender, address(this), amount);
            pool.deposit(underlying, amount, msg.sender, 0);
        }
        uint256 borrowed;
        while(borrowed < borrowTotal) {
            // start borrow
            uint256 diff = borrowTotal - borrowed;
            uint256 toBorrow = IBorrowableProvider(borrowableProvider).getUserMaxBorrowable(msg.sender, address(underlying));
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
            masterWombat.deposit(pid, toBorrow);
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


}