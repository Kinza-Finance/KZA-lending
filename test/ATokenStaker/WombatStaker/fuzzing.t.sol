
import {ATokenWombatStakerBaseTest} from "./ATokenWombatStakerBaseTest.t.sol";
import {IERC20} from "../../../src/core/dependencies/openzeppelin/contracts/IERC20.sol";
import {USDC, ADDRESSES_PROVIDER, POOLDATA_PROVIDER, ACL_MANAGER, POOL, POOL_CONFIGURATOR, EMISSION_MANAGER, 
        ATOKENIMPL, SDTOKENIMPL, VDTOKENIMPL, TREASURY, POOL_ADMIN, HAY_AGGREGATOR, 
        MASTER_WOMBAT, SMART_HAY_LP, LIQUIDATION_ADAPTOR} from "test/utils/Addresses.sol";

contract fuzzingTest is ATokenWombatStakerBaseTest {
    function setUp() public virtual override(ATokenWombatStakerBaseTest) {
        ATokenWombatStakerBaseTest.setUp();
    }

    function testFuzz_deposit(
         address user,
         uint256 amount
    ) external {
        if (user == address(0)) {
            user = address(1);
        }
        ( ,uint256 supplyCap) = dataProvider.getReserveCaps(underlying);
        amount = bound(amount, 1, supplyCap * 1e18); 
        deal(address(underlying), user, amount);
        vm.startPrank(user);
        IERC20(underlying).approve(address(pool), amount);
        pool.deposit(underlying, amount, user, 0);
        (address ATokenProxyAddress,,) = dataProvider.getReserveTokensAddresses(underlying);
        assertEq(IERC20(ATokenProxyAddress).balanceOf(user), amount);
    }

    function testFuzz_withdraw(
         address user,
         uint256 amount
    ) external {
        if (user == address(0)) {
            user = address(1);
        }

        // we are fuzzing withdraw here so just max deposit for a user
        ( ,uint256 supplyCap) = dataProvider.getReserveCaps(underlying);
        uint256 maxDposit = supplyCap * 1e18; 
        deal(address(underlying), user, maxDposit);
        vm.startPrank(user);
        IERC20(underlying).approve(address(pool), maxDposit);
        pool.deposit(underlying, maxDposit, user, 0);
        // here is the withdraw 
        amount = bound(amount, 1, maxDposit); 
        uint256 before = IERC20(underlying).balanceOf(user);
        pool.withdraw(underlying, amount, user);
        assertEq(IERC20(underlying).balanceOf(user), before + amount);
    }
}