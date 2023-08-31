
import {ATokenWombatStakerBaseTest} from "./ATokenWombatStakerBaseTest.t.sol";
import {IERC20} from "../../../src/core/dependencies/openzeppelin/contracts/IERC20.sol";
import {ADDRESSES_PROVIDER, POOLDATA_PROVIDER, ACL_MANAGER, POOL, POOL_CONFIGURATOR, EMISSION_MANAGER, 
        ATOKENIMPL, SDTOKENIMPL, VDTOKENIMPL, TREASURY, POOL_ADMIN,
        MASTER_WOMBAT, SMART_HAY_LP, WOMBAT_HELPER_SMART_HAY_LP} from "test/utils/Addresses.sol";

contract unitTest is ATokenWombatStakerBaseTest {

    function setUp() public virtual override(ATokenWombatStakerBaseTest) {
        ATokenWombatStakerBaseTest.setUp();
    }

    function test_deposit() public {
        address bob = address(1);
        uint256 amount = 1 ether;
        deal(underlying, bob, amount);
        deposit(bob, amount);
    }

    function test_withdraw() public {
        address bob = address(1);
        uint256 amount = 1 ether;
        deal(underlying, bob, amount);
        deposit(bob, amount);
        withdraw(bob, amount);
    }

    function deposit(address user, uint256 amount) public {
        vm.startPrank(user);
        uint256 before_aToken = ATokenProxyStaker.balanceOf(user);
        uint256 before_underlying = IERC20(underlying).balanceOf(user);
        IERC20(underlying).approve(address(pool), amount);
        pool.deposit(underlying, amount, user, 0);
        assertEq(ATokenProxyStaker.balanceOf(user), before_aToken + amount);
        assertEq(IERC20(underlying).balanceOf(user), before_underlying - amount);
    }

    function withdraw(address user, uint256 amount) public {
        vm.startPrank(user);
        uint256 before_aToken = ATokenProxyStaker.balanceOf(user);
        uint256 before_underlying = IERC20(underlying).balanceOf(user);
        pool.withdraw(underlying, amount, user);
        assertEq(ATokenProxyStaker.balanceOf(user), before_aToken - amount);
        assertEq(IERC20(underlying).balanceOf(user), before_underlying + amount);

    }
}