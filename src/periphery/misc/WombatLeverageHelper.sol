import '../../core/interfaces/IPoolAddressesProvider.sol';
import '../../core/interfaces/IPool.sol';
import '../../core/interfaces/IMasterWombat.sol';
import {IERC20} from '@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol';


// just need one function rather use it here
interface IBorrowableProvider {
    function getUserMaxBorrowable(address user, address asset) external view returns(uint256);
}

contract WombatLeverageHelper {
    IPoolAddressesProvider immutable public provider;
    IERC20 public underlying;
    IERC20 public lp;
    IMasterWombat public masterWombat;
    IPool public pool;
    uint8 emodeCategory;
    uint256 pid;
    constructor(address _provider, address _masterWombat, address _underlying, uint8 _emodeCategory) {
        emodeCategory = _emodeCategory;
        provider = IPoolAddressesProvider(_proivder);
        underlying = IERC20(_underlying);
        pool = IPool(IPoolAddressesProvider(_provider).getPool());
        masterWombat = IMasterWombat(_masterWombat);
        underlying.approve(_masterWombat, type(uint256).max);
        //approve LP for pool
        uint256 _pid = masterWombat.getAssetPid(underlying);
        (address lpAddr,,,,,,) = masterWombat.poolInfo(_pid);
        pid = _pid;
        lp = IERC20(lpAddr);
        lp.approve(address(pool), type(uint256).max);
    }


    function calculateUnderlyingBorrow(uint256 targeHF, uint256 deposit, uint8 emode) view returns(uint256) {
        (uint256 underlyingPrice, uint256 lpPrice) = getLpAndUnderlyingPrice();
        // assume a person without any other position
        uint256 emodeLiqT = uint256(pool.getEModeCategoryData(emode).liquidationThreshold);
        // targetHF = depositTotal * emodeLiqT / borrowedUnderlyingTotal
        // targetHF = (deposit + borrow) * emodeLiqT * lpPrice / borrow * underlyingPrice
        // targetHF = (deposit * LiqT * lpPrice) / borrow * underlyingPrice + LiqT * emodeLiqT / underlyingPrice
        // after refactor: the constant part => depositRatio.
        uint256 depositRatio = targetHF - 1e18 * lPrice * emodeLiqT / underlyingPrice / 10000;
        return 1e18 * deposit * lpPrice * emodeLiqT / (depositRatio * underlyingPrice) / 10000;

    }
    // this function just leverage the calculation function, 
    // and loop the needed borrowedAmount
    function loop(address borrowableProvider, uint256 targetHF, uint256 amount) external returns(uint256) {
        require(targeHF > 1e18 && amount > 0, "targetHF or deposit amount invalid");
        (uint256 underlyingPrice, uint256 lpPrice) = getLpAndUnderlyingPrice();
        uint256 borrowTotal = calculateUnderlyingBorrow(targetHF, amount, emodeCategory);
        uint256 borrowed;
        while(borrowed < borrowTotal) {
            // start borrow
            uint256 diff = borrowTotal - borrowed;
            uint256 toBorrow = IBorrowableProvider(borrowableProvider).getUserMaxBorrowable(msg.sender, underlying);
            if (toBorrow == 0) {
                // somehow the user can not borrow anymore
                break;
            }
            if (toBorrow > diff) {
                toBorrow = diff;
            }
            pool.borrow(underlying, toBorrow, 0, msg.sender);
            borrowed += toBorrow;
            // convert to LP on wombat
            masterWombat.deposit(pid, toBorrow);
            // deposit the LP into pool
            uint256 amount = lp.balanceOf(address(this));
            pool.deposit(lp, amount, msg.sender, 0);
        }
        return borrowed;
    }

    function getLpAndUnderlyingPrice() public view returns(uint256, uint256) {
        IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
        IAaveOracle oracle = IAaveOracle(provider.getPriceOracle());
        address[] memory assets = new address[](2);
        assets[0] = underlying;
        assets[1] = lp;
        uint256[] memory prices = oracle.getAssetsPrices(assets);
        return (prices[0], prices[1]);
  }


}