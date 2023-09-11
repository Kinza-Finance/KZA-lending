
import {ATokenWombatStakerBaseTest} from "./ATokenWombatStakerBaseTest.t.sol";
import {IERC20} from "../../../src/core/dependencies/openzeppelin/contracts/IERC20.sol";
import {IPoolDataProvider} from "../../../src/core/interfaces/IPoolDataProvider.sol";
import {WombatLeverageHelper} from "../../../src/periphery/misc/WombatLeverageHelper.sol";
import {ADDRESSES_PROVIDER, POOLDATA_PROVIDER, ACL_MANAGER, POOL, POOL_CONFIGURATOR, EMISSION_MANAGER, 
        ATOKENIMPL, SDTOKENIMPL, VDTOKENIMPL, TREASURY, POOL_ADMIN, HAY_AGGREGATOR, HAY, 
        MASTER_WOMBAT, SMART_HAY_LP, LIQUIDATION_ADAPTOR, BORROWABLE_DATA_PROVIDER} from "test/utils/Addresses.sol";

contract leverageTest is ATokenWombatStakerBaseTest {
    WombatLeverageHelper internal levHelper;
    function setUp() public virtual override(ATokenWombatStakerBaseTest) {
        ATokenWombatStakerBaseTest.setUp();
        levHelper = new WombatLeverageHelper(
            ADDRESSES_PROVIDER, MASTER_WOMBAT
        );
    }

    function test_leverageSetUp() public {

    }

    function test_loop() public {
        uint256 targetHF = 1.2 * 1e18;
        uint256 depositAmount = 100 * 1e18;
        address bob = address(1);
        deposit(bob, depositAmount, underlying);
        turnOnEmode(bob);
        loop(bob, targetHF, depositAmount);
    }

    function loop(address user, uint256 targetHF, uint256 depositAmount) public {
        vm.startPrank(user);
        // check variableDebt of the underlying asset is indeed the borrowed.
        (,,address vDebtProxy) = IPoolDataProvider(POOLDATA_PROVIDER).getReserveTokensAddresses(HAY);
        uint256 debtBefore = IERC20(vDebtProxy).balanceOf(user);
        uint256 borrowed = levHelper.loop(BORROWABLE_DATA_PROVIDER, targetHF, underlying, depositAmount, eModeCategoryId);
        assertEq(debtBefore + borrowed, IERC20(vDebtProxy).balanceOf(user));
    }
}