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
    uint256 constant public MAX_SLIPPAGE = 10000;
    IPoolAddressesProvider immutable public provider;
    IPool immutable public pool;


    modifier onlyPool() {
        require(msg.sender == address(pool));
        _;
    }

    constructor(address _provider, address _wombatPool) {
        provider = IPoolAddressesProvider(_provider);
        pool = IPool(IPoolAddressesProvider(_provider).getPool());
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
    // this
    function borrowWithFlashLoan(address wombatPool, address lpAddr, uint256 amount, uint256 interestRateMode, uint256 slippage) external {
        // only 1 asset is allowed at a time, 
        // we are just leveraging the borrow feature of the multi-flasloan interface
        require(MAX_SLIPPAGE > slippage, "SLIPPAGE TOO BIG");
        IPoolDataProvider dataProvider = IPoolDataProvider(provider.getPoolDataProvider());
        IPool pool = IPool(provider.getPool());
        address underlying = IAsset(lpAddr).underlyingToken();
        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        uint256[] memory interestRateModes = new uint256[](1);
        assets[0] = underlying;
        amounts[0] = amount;
        interestRateModes[0] = interestRateMode;

        // allow the pool to get back the flashloan + premium
        IERC20(underlying).approve(address(pool), type(uint256).max);
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
        // depositor
        bytes memory params = abi.encode(
           msg.sender, wombatPool, lpAddr, slippage);
        pool.flashLoan(
            address(this),
            assets,
            amounts,
            interestRateModes,
            msg.sender,
            params,
            0
        );
    }

    function executeOperation(
    address[] calldata borrowedAssets,
    uint256[] calldata amounts,
    uint256[] calldata premium,
    address, //initiator, which would be this address if called from borrowWithFlashLoan
    bytes memory params
  )  external onlyPool returns (bool){
        (address depositor, address wombatPool, address lpAddr, uint256 slippage) = abi.decode(params, (address, address, uint256));
        (uint256 underlyingPrice, uint256 lpPrice) = getPrice(underlying, lpAddr);
        // deposit into wombat    
        _checkWombatAllowance(wombatPool, underlying);
        _checkPoolAllowance(lpAddr);
        wombatPool.deposit(
            underlying,
            toBorrow,
            // apply 10 bp slippage for minLiq,
            // with ref to relative lpPrice and underlyingPrice
            toBorrow * lpPrice * (MAX_SLIPPAGE - slippage) / underlyingPrice / MAX_SLIPPAGE,
            address(this), // receiver 
            block.timestamp, // expiry
            false // isStaked
            );
        // deposit the LP into pool for the user
        uint256 amount = IERC20(lpAddr).balanceOf(address(this));
        pool.deposit(lpAddr, amount, depositor, 0);
        return true;
    }

    function depositUnderlyingAndLoop(address borrowableProvider, uint256 targetHF, address lpAddr, uint256 amount, uint8 emodeCategory) external returns (uint256) {
        address underlying = IAsset(lpAddr).underlyingToken();
        (uint256 underlyingPrice, uint256 lpPrice) = getPrice(underlying, lpAddr);
        IERC20(underlying).transferFrom(msg.sender, address(this), amount);
        // initial approval
        _checkWombatAllowance(underlying);
        _checkPoolAllowance(lpAddr);
        wombatPool.deposit(
            underlying,
            amount,
            // apply 10 bp slippage for minLiq,
            // with ref to relative lpPrice and underlyingPrice
            amount * lpPrice * 9990 / underlyingPrice / 10000,
            address(this),
            block.timestamp,
            false
            );
        uint256 lpCollected = IERC20(lpAddr).balanceOf(address(this));
        pool.deposit(lpAddr, lpCollected, msg.sender, 0);
        return _loop(borrowableProvider, targetHF, lpAddr, amount, emodeCategory);
    }

    function depositLpAndLoop(address borrowableProvider, uint256 targetHF, address lpAddr, uint256 amount, uint8 emodeCategory) external returns (uint256) {
        address underlying = IAsset(lpAddr).underlyingToken();
        IERC20(lpAddr).transferFrom(msg.sender, address(this), amount);
        _checkWombatAllowance(underlying);
        _checkPoolAllowance(lpAddr);
        pool.deposit(lpAddr, amount, msg.sender, 0);
        return _loop(borrowableProvider, targetHF, lpAddr, amount, emodeCategory);
    }
    // this function just leverage by borrowing underlying for the user
    // and loop the needed borrowedAmount by re-depositing back the lp
    // the final health factor may vary from the targetHF
    // since the deposited LP might be different depends on wombat
    function _loop(address borrowableProvider, uint256 targetHF, address lpAddr, uint256 amount, uint8 emodeCategory) internal returns(uint256) {
        require(targetHF > 1e18 && amount > 0, "targetHF or deposit amount invalid");
        address underlying = IAsset(lpAddr).underlyingToken();
        (uint256 underlyingPrice, uint256 lpPrice) = getPrice(underlying, lpAddr);
        uint256 borrowTotal = calculateToBorrowWithHF(targetHF, lpAddr, amount,  emodeCategory);
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
            wombatPool.deposit(
            underlying,
            toBorrow,
            // apply 10 bp slippage for minLiq,
            // with ref to relative lpPrice and underlyingPrice
            toBorrow * lpPrice * 9990 / underlyingPrice / 10000,
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

   function _checkWombatAllowance(address wombatPool, address underlying) internal {
        if (IERC20(underlying).allowance(address(wombatPool), address(this)) == 0) {
            IERC20(underlying).approve(address(wombatPool), type(uint256).max);
        }
   }

}