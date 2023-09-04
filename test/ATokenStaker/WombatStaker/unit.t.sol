
import {ATokenWombatStakerBaseTest} from "./ATokenWombatStakerBaseTest.t.sol";
import {IERC20} from "../../../src/core/dependencies/openzeppelin/contracts/IERC20.sol";
import {ADDRESSES_PROVIDER, POOLDATA_PROVIDER, ACL_MANAGER, POOL, POOL_CONFIGURATOR, EMISSION_MANAGER, 
        ATOKENIMPL, SDTOKENIMPL, VDTOKENIMPL, TREASURY, POOL_ADMIN, HAY_AGGREGATOR, 
        MASTER_WOMBAT, SMART_HAY_LP} from "test/utils/Addresses.sol";

contract unitTest is ATokenWombatStakerBaseTest {

    function setUp() public virtual override(ATokenWombatStakerBaseTest) {
        ATokenWombatStakerBaseTest.setUp();
    }

    function test_deposit() public {
        address bob = address(1);
        uint256 amount = 1 ether;
        deposit(bob, amount, underlying);
    }

    function test_withdraw() public {
        address bob = address(1);
        uint256 amount = 1 ether;
        deposit(bob, amount, underlying);
        withdraw(bob, amount, underlying);
    }

    function test_borrowWhenBorrowDisabled() public {
        address bob = address(1);
        uint256 collateralAmount = 100_000;
        uint256 borrow_amount = 100;
        prepUSDC(bob, collateralAmount);
        //when borrow is disabled
        borrowExpectFail(bob, borrow_amount, underlying, '30');
    }
    function test_borrowWhenBorrowEnabled() public {
        address bob = address(1);
        uint256 collateralAmount = 100_000 * 1e18;
        uint256 borrow_amount = 100 * 1e18;
        // have a deposit first, so there is reserve available
        deposit(bob, borrow_amount, underlying);
        prepUSDC(bob, collateralAmount);
        turnOnBorrow();
        //when borrow is enabled, but price is 0 so borrow is reverted by devision of zero
        borrowExpectFail(bob, borrow_amount, underlying, '');
    }

    function test_borrowWhenBorrowEnabledNonZeroPrice() public {
        address bob = address(1);
        uint256 collateralAmount = 100_000 * 1e18;
        uint256 borrow_amount = 100 * 1e18;
        // have a deposit first, so there is reserve available
        deposit(bob, borrow_amount, underlying);
        prepUSDC(bob, collateralAmount);
        turnOnBorrow();
        setUpOracle(HAY_AGGREGATOR, underlying);
        //when borrow is enabled, price is non-zero borrow is reverted by AToken
        borrowExpectFail(bob, borrow_amount, underlying, 'ATokenStaker does not allow flashloan or borrow');
    }


    function test_flashloanWhenDisabled() public {
        address bob = address(1);
        uint256 collateralAmount = 100 * 1e18;
        deposit(bob, collateralAmount, underlying);
        flashloan(bob, collateralAmount, underlying, '91');
    }

     function test_flashloanWhenEnabled() public {
        address bob = address(1);
        uint256 collateralAmount = 100 * 1e18;
        turnOnFlashloan();
        deposit(bob, collateralAmount, underlying);
        flashloan(bob, collateralAmount, underlying, 'ATokenStaker does not allow flashloan or borrow');
    }
}