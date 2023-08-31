
import {ATokenMagpieStakerBaseTest} from "./ATokenMagpieStakerBaseTest.t.sol";
import {IERC20} from "../../src/core/dependencies/openzeppelin/contracts/IERC20.sol";
import {ADDRESSES_PROVIDER, POOLDATA_PROVIDER, ACL_MANAGER, POOL, POOL_CONFIGURATOR, EMISSION_MANAGER, 
        ATOKENIMPL, SDTOKENIMPL, VDTOKENIMPL, TREASURY, POOL_ADMIN,
        MASTER_MAGPIE, SMART_HAY_LP, WOMBAT_HELPER_SMART_HAY_LP} from "test/utils/Addresses.sol";

contract unitTest is ATokenMagpieStakerBaseTest {

    function setUp() public virtual override(ATokenMagpieStakerBaseTest) {
        ATokenMagpieStakerBaseTest.setUp();
    }

    function test_deposit() public {
        address bob = address(1);
        deal(underlying, bob, 1 ether);
        vm.startPrank(bob);
        IERC20(underlying).approve(address(pool), 1 ether);
        pool.deposit(underlying, 1 ether, bob, 0);
        assertEq(ATokenProxyStaker.balanceOf(bob), 1 ether);
    }
}