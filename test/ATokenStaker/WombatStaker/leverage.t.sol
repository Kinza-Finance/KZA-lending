
import "forge-std/console2.sol";
import {ATokenWombatStakerBaseTest} from "./ATokenWombatStakerBaseTest.t.sol";
import {IERC20} from "../../../src/core/dependencies/openzeppelin/contracts/IERC20.sol";
import {IPoolDataProvider} from "../../../src/core/interfaces/IPoolDataProvider.sol";
import {ICreditDelegationToken} from "../../../src/core/interfaces/ICreditDelegationToken.sol";


import {BorrowableDataProvider} from "../../../src/periphery/misc/BorrowableDataProvider.sol";
import {WombatLeverageHelper} from "../../../src/periphery/misc/WombatLeverageHelper.sol";
import {ADDRESSES_PROVIDER, POOLDATA_PROVIDER, ACL_MANAGER, POOL, POOL_CONFIGURATOR, EMISSION_MANAGER, 
        ATOKENIMPL, SDTOKENIMPL, VDTOKENIMPL, TREASURY, POOL_ADMIN, HAY_AGGREGATOR, HAY, 
        SMART_HAY_POOL, SMART_HAY_LP, LIQUIDATION_ADAPTOR, BORROWABLE_DATA_PROVIDER} from "test/utils/Addresses.sol";

contract leverageTest is ATokenWombatStakerBaseTest {
    uint256 internal slippage = 10;
    WombatLeverageHelper internal levHelper;
    ICreditDelegationToken internal vDebtUnderlyingToken;
    function setUp() public virtual override(ATokenWombatStakerBaseTest) {
        ATokenWombatStakerBaseTest.setUp();
        levHelper = new WombatLeverageHelper(
            ADDRESSES_PROVIDER
        );
        (,,address vDebtProxy) = dataProvider.getReserveTokensAddresses(HAY);
        vDebtUnderlyingToken = ICreditDelegationToken(vDebtProxy);
    }

    function test_leverageSetUp() public {

    }

    function test_borrowTotal() public {
        uint256 targetHF = 2 * 1e18;
        uint256 depositAmount = 100 * 1e18;
        address bob = address(1);
        (uint256 underlyingPrice, uint256 lpPrice) = getPrice(HAY, underlying);
        vm.startPrank(bob);
        uint256 toBorrow = levHelper.calculateUnderlyingBorrow(
            targetHF,  underlying, depositAmount, eModeCategoryId
        );
        console2.log(toBorrow);
    }
    function test_maxBorrowable() public {
        address bob = address(1);
        turnOnEmode(bob);
        uint256 depositAmount = 100 * 1e18;
        deal(underlying, bob, depositAmount);
        vm.startPrank(bob);
        IERC20(underlying).approve(address(pool), depositAmount);
        deposit(bob, depositAmount, underlying);
        uint256 borrowable = BorrowableDataProvider(BORROWABLE_DATA_PROVIDER).calculateLTVBorrowable(bob, HAY);
        assertGt(borrowable, 0);
    }
    function test_loopWithLP() public {
        uint256 targetHF = 1.2 * 1e18;
        uint256 depositAmount = 100 * 1e18;
        address bob = address(1);
        turnOnEmode(bob);
        deal(underlying, bob, depositAmount);
        vm.startPrank(bob);
        IERC20(underlying).approve(address(levHelper), depositAmount);
        // approve borrowing allowance or levHelper
        vDebtUnderlyingToken.approveDelegation(address(levHelper), type(uint256).max);
        //assertEq(vDebtUnderlyingToken.borrowAllowance(bob, address(levHelper)), type(uint256).max);
        bool isUnderlying = false;
        loop(bob, targetHF, depositAmount, isUnderlying);
        (,,,,, uint256 healthFactor) = pool.getUserAccountData(bob);
        console2.log("HF after loop: ",healthFactor);
    }

    function test_loopWithUnderlying() public {
        uint256 targetHF = 1.2 * 1e18;
        uint256 depositAmount = 100 * 1e18;
        address bob = address(1);
        turnOnEmode(bob);
        deal(HAY, bob, depositAmount);
        vm.startPrank(bob);
        IERC20(HAY).approve(address(levHelper), depositAmount);
        vDebtUnderlyingToken.approveDelegation(address(levHelper), type(uint256).max);
        bool isUnderlying = true;
        loop(bob, targetHF, depositAmount, isUnderlying);
        (,,,,, uint256 healthFactor) = pool.getUserAccountData(bob);
        console2.log("HF after loop: ",healthFactor);

    }

    function loop(address user, uint256 targetHF, uint256 depositAmount, bool isUnderlying) public {
        vm.startPrank(user);
        // check variableDebt of the underlying asset is indeed the borrowed.
        (,,address vDebtProxy) = IPoolDataProvider(POOLDATA_PROVIDER).getReserveTokensAddresses(HAY);
        uint256 debtBefore = IERC20(vDebtProxy).balanceOf(user);
        uint256 borrowed;
        if (isUnderlying) {
            borrowed = levHelper.depositUnderlyingAndLoop(BORROWABLE_DATA_PROVIDER, SMART_HAY_POOL, targetHF, underlying, depositAmount, eModeCategoryId, slippage);
        } else {
            borrowed = levHelper.depositLpAndLoop(BORROWABLE_DATA_PROVIDER, SMART_HAY_POOL, targetHF, underlying, depositAmount, eModeCategoryId, slippage);
        }
        assertEq(debtBefore + borrowed, IERC20(vDebtProxy).balanceOf(user));
    }
}