
import {ATokenWombatStakerBaseTest} from "./ATokenWombatStakerBaseTest.t.sol";
import {IERC20} from "../../../src/core/dependencies/openzeppelin/contracts/IERC20.sol";
import {IPoolDataProvider} from "../../../src/core/interfaces/IPoolDataProvider.sol";
import {ICreditDelegationToken} from "../../../src/core/interfaces/ICreditDelegationToken.sol";
import {WombatLeverageHelper} from "../../../src/periphery/misc/WombatLeverageHelper.sol";
import {ADDRESSES_PROVIDER, POOLDATA_PROVIDER, ACL_MANAGER, POOL, POOL_CONFIGURATOR, EMISSION_MANAGER, 
        ATOKENIMPL, SDTOKENIMPL, VDTOKENIMPL, TREASURY, POOL_ADMIN, HAY_AGGREGATOR, HAY, 
        SMART_HAY_POOL, SMART_HAY_LP, LIQUIDATION_ADAPTOR, BORROWABLE_DATA_PROVIDER} from "test/utils/Addresses.sol";

contract leverageTest is ATokenWombatStakerBaseTest {
    WombatLeverageHelper internal levHelper;
    function setUp() public virtual override(ATokenWombatStakerBaseTest) {
        ATokenWombatStakerBaseTest.setUp();
        levHelper = new WombatLeverageHelper(
            ADDRESSES_PROVIDER, POOLDATA_PROVIDER
        );
        // give levHelper FlashloanBorrower role
        vm.startPrank(POOL_ADMIN);
        aclManager.addFlashBorrower(address(levHelper));
    }

    function test_leverageSetUp() public {

    }

    function test_borrowWithFlashLoan() public {
        uint256 depositAmount = 1 * 1e18;
        uint256 borrowAmount = depositAmount * 2;
        address bob = address(1);
        uint256 interestRateMode = 2;
        uint256 minLp = 0;
        turnOnEmode(bob);
        deposit(bob, depositAmount, underlying);
        turnOnCollateral(bob, underlying);
        // approve levHelper
        vm.startPrank(bob);
        (,,address vdToken) = dataProvider.getReserveTokensAddresses(HAY);
        ICreditDelegationToken(vdToken).approveDelegation(address(levHelper), borrowAmount);
        levHelper.borrowWithFlashLoan(SMART_HAY_POOL, underlying, borrowAmount, minLp);
    }

    function test_transferLpBorrowWithFlashLoan() public {
        uint256 depositAmount = 1 * 1e18;
        uint256 borrowAmount = depositAmount * 2;
        address bob = address(1);
        uint256 interestRateMode = 2;
        uint256 minLp = 0;
        deal(underlying, bob, depositAmount);
        turnOnEmode(bob);
        vm.startPrank(bob);
        // approve levHelper to pull LP
        IERC20(underlying).approve(address(levHelper), depositAmount);
        (,,address vdToken) = dataProvider.getReserveTokensAddresses(HAY);
        // approve levHelper to borrow underlying on behalf of user
        ICreditDelegationToken(vdToken).approveDelegation(address(levHelper), borrowAmount);
        levHelper.transferLPAndBorrowWithFlashLoan(SMART_HAY_POOL, underlying, depositAmount, borrowAmount, minLp);
    }

    function test_transferUnderlyingBorrowWithFlashLoan() public {
        uint256 depositAmount = 1 * 1e18;
        uint256 borrowAmount = depositAmount * 2;
        address bob = address(1);
        uint256 interestRateMode = 2;
        uint256 minLp = 0;
        uint256 slippage = 100;
        deal(HAY, bob, depositAmount);
        turnOnEmode(bob);
        vm.startPrank(bob);
        // approve levHelper to pull underlying
        IERC20(HAY).approve(address(levHelper), depositAmount);
        (,,address vdToken) = dataProvider.getReserveTokensAddresses(HAY);
        // approve levHelper to borrow underlying on behalf of user
        ICreditDelegationToken(vdToken).approveDelegation(address(levHelper), borrowAmount);
        levHelper.transferUnderlyingAndBorrowWithFlashLoan(SMART_HAY_POOL, underlying, depositAmount, borrowAmount, minLp, slippage);
    }

    
}