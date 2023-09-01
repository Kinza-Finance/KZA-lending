
import {ATokenWombatStakerBaseTest} from "./ATokenWombatStakerBaseTest.t.sol";
import {IERC20} from "../../../src/core/dependencies/openzeppelin/contracts/IERC20.sol";
import {USDC, ADDRESSES_PROVIDER, POOLDATA_PROVIDER, ACL_MANAGER, POOL, POOL_CONFIGURATOR, EMISSION_MANAGER, 
        ATOKENIMPL, SDTOKENIMPL, VDTOKENIMPL, TREASURY, POOL_ADMIN, HAY_AGGREGATOR, 
        MASTER_WOMBAT, SMART_HAY_LP, LIQUIDATION_ADAPTOR} from "test/utils/Addresses.sol";

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
        borrow(bob, borrow_amount, underlying, '30');
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
        borrow(bob, borrow_amount, underlying, '');
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
        borrow(bob, borrow_amount, underlying, 'ATokenStaker does not allow flashloan or borrow');
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

    function deposit(address user, uint256 amount, address underlying) public {
        vm.startPrank(user);
        deal(underlying, user, amount);
        (address ATokenProxyAddress,,) = dataProvider.getReserveTokensAddresses(underlying);
        uint256 before_aToken = IERC20(ATokenProxyAddress).balanceOf(user);
        uint256 before_underlying = IERC20(underlying).balanceOf(user);
        IERC20(underlying).approve(address(pool), amount);
        pool.deposit(underlying, amount, user, 0);
        assertEq(IERC20(ATokenProxyAddress).balanceOf(user), before_aToken + amount);
        assertEq(IERC20(underlying).balanceOf(user), before_underlying - amount);
    }

    function withdraw(address user, uint256 amount, address underlying) public {
        vm.startPrank(user);
        (address ATokenProxyAddress,,) = dataProvider.getReserveTokensAddresses(underlying);
        uint256 before_aToken = IERC20(ATokenProxyAddress).balanceOf(user);
        uint256 before_underlying = IERC20(underlying).balanceOf(user);
        pool.withdraw(underlying, amount, user);
        assertEq(IERC20(ATokenProxyAddress).balanceOf(user), before_aToken - amount);
        assertEq(IERC20(underlying).balanceOf(user), before_underlying + amount);
    }


    function borrow(address user, uint256 amount, address underlying, string memory errorMsg) public {
         vm.startPrank(user);
         vm.expectRevert(abi.encodePacked(errorMsg));
         // 2 = variable mode, 0 = no referral
         pool.borrow(underlying, amount, 2, 0, user);
    }

    function flashloan(address user, uint256 amount, address underlying, string memory errorMsg) public {
        vm.startPrank(user);
         vm.expectRevert(abi.encodePacked(errorMsg));
         // 2 = variable mode, 0 = no referral
         // no param, 0 = no referral
         // receiver needs to be a contract
         pool.flashLoanSimple(LIQUIDATION_ADAPTOR, underlying, amount, "", 0);
    }

    function prepUSDC(address user, uint256 collateral_amount) public {
        // deposit USDC to have some collateral power
        deposit(user, collateral_amount, USDC);
    }

    function turnOnBorrow() public {
        vm.startPrank(POOL_ADMIN);
        configurator.setReserveBorrowing(underlying, true);
    }

    function turnOnFlashloan() public {
        vm.startPrank(POOL_ADMIN);
        configurator.setReserveFlashLoaning(underlying, true);
    }
}