
import {ATokenWombatStakerBaseTest} from "./ATokenWombatStakerBaseTest.t.sol";
import {IERC20} from "../../../src/core/dependencies/openzeppelin/contracts/IERC20.sol";
import {ValidationLogic} from "../../../src/core/protocol/libraries/logic/ValidationLogic.sol";
import {IPoolAddressesProvider} from "../../../src/core/interfaces/IPoolAddressesProvider.sol";
import {Pool} from "../../../src/core/protocol/pool/Pool.sol";

import {TIMELOCK, ADDRESSES_PROVIDER, POOLDATA_PROVIDER, ACL_MANAGER, POOL, POOL_CONFIGURATOR, EMISSION_MANAGER, 
        ATOKENIMPL, SDTOKENIMPL, VDTOKENIMPL, TREASURY, POOL_ADMIN, HAY_AGGREGATOR, HAY, 
        MASTER_WOMBAT, SMART_HAY_LP, LIQUIDATION_ADAPTOR, BORROWABLE_DATA_PROVIDER} from "test/utils/Addresses.sol";

// @dev disable linked lib in foundry.toml, since forge test would inherit those setting
// https://book.getfoundry.sh/reference/forge/forge-build?highlight=link#linker-options
contract poolUpgradeUnitTest is ATokenWombatStakerBaseTest {

    function setUp() public virtual override(ATokenWombatStakerBaseTest) {
        ATokenWombatStakerBaseTest.setUp();
        // deploy new pool impl with new validationLogic
        
        Pool poolV2 = new Pool(IPoolAddressesProvider(ADDRESSES_PROVIDER));
        poolV2.initialize(IPoolAddressesProvider(ADDRESSES_PROVIDER));
        // upgrade
        vm.startPrank(TIMELOCK);
        provider.setPoolImpl(address(poolV2));
        assertEq(Pool(address(pool)).POOL_REVISION(), 0x2);
    }

    function test_enableCollateralWithZeroLTV() public {
        setReserveAsZeroLTV();
        address bob = address(1);
        turnOnEmode(bob);
        deposit(bob, 1e18, underlying);
        turnOnCollateral(bob, underlying);
    }

    function test_liquidateRevertOutsideEmodeAfterProxyUpgrade() public {
        setReserveAsZeroLTV();
        address bob = address(1);
        uint256 collateralAmount = 100 * 1e18;
        deposit(bob, collateralAmount, underlying);
        turnOnCollateral(bob, underlying);
        // now setup a bad debt
        prepUSDC(bob, 1e18);
        address debtAsset = HAY;
        borrow(bob, 6e17, debtAsset);
        // pass 100y
        vm.warp(36500 days);
        // verify health factor < 1;
        (,,,,, uint256 healthFactor) = pool.getUserAccountData(bob);
        assertLt(healthFactor, 1e18);
        // attempt to liquidate half of original debt
        liquidateRevertWith46(bob, debtAsset, underlying, 3e17);

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

    function test_transfer() public {
        address bob = address(1);
        address alice = address(2);
        uint256 amount = 1 ether;
        deposit(bob, amount, underlying);
        transferAToken(bob, alice, amount, address(ATokenProxyStaker));
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
        borrowExpectFail(bob, borrow_amount, underlying, 'ATokenStaker does not allow flashloan or borrow');
    }


    function test_flashloanWhenDisabled() public {
        address bob = address(1);
        uint256 collateralAmount = 100 * 1e18;
        deposit(bob, collateralAmount, underlying);
        flashloanRevert(bob, collateralAmount, underlying, '91');
    }

     function test_flashloanWhenEnabled() public {
        address bob = address(1);
        uint256 collateralAmount = 100 * 1e18;
        turnOnFlashloan();
        deposit(bob, collateralAmount, underlying);
        flashloanRevert(bob, collateralAmount, underlying, 'ATokenStaker does not allow flashloan or borrow');
    }

    function test_enableCollateral() public {
        address bob = address(1);
        uint256 collateralAmount = 100 * 1e18;
        deposit(bob, collateralAmount, underlying);
        turnOnCollateral(bob, underlying);
    }

    function test_disableAsCollateral() public {
        address bob = address(1);
        uint256 collateralAmount = 100 * 1e18;
        deposit(bob, collateralAmount, underlying);
        turnOffCollateral(bob, underlying);
    }

    // liquidate
    function test_liquidateRevertOutsideEmode() public {
        address bob = address(1);
        uint256 collateralAmount = 100 * 1e18;
        deposit(bob, collateralAmount, underlying);
        turnOnCollateral(bob, underlying);
        // now setup a bad debt
        prepUSDC(bob, 1e18);
        address debtAsset = HAY;
        borrow(bob, 6e17, debtAsset);
        // pass 100y
        vm.warp(36500 days);
        // verify health factor < 1;
        (,,,,, uint256 healthFactor) = pool.getUserAccountData(bob);
        assertLt(healthFactor, 1e18);
        // attempt to liquidate half of original debt
        liquidateRevert(bob, debtAsset, underlying, 3e17);

    }
    function test_liquidateInsideEmode() public {
        address bob = address(1);
        uint256 collateralAmount = 100 * 1e18;
        deposit(bob, collateralAmount, underlying);
        turnOnEmode(bob);
        turnOnCollateral(bob, underlying);
        address debtAsset = HAY;
        uint256 debtAmount = collateralAmount / 2;
        borrow(bob, debtAmount, debtAsset);
        // pass 100y
        vm.warp(36500 days);
        // verify health factor < 1;
        (,,,,, uint256 healthFactor) = pool.getUserAccountData(bob);
        assertLt(healthFactor, 1e18);
        // attempt to liquidate half of original debt
        liquidate(bob, debtAsset, underlying, debtAmount / 2);
        // assert some collateral are seize
        assertLt(IERC20(ATokenProxyStaker).balanceOf(bob), collateralAmount);
    }

    function test_transferInsideEmode() public {
        address bob = address(1);
        address alice = address(2);
        uint256 amount = 1 ether;
        deposit(bob, amount, underlying);
        turnOnEmode(bob);
        transferAToken(bob, alice, amount, address(ATokenProxyStaker));
    }

    function test_transferInsideEmodeRevert() public {
        address bob = address(1);
        address alice = address(2);
        uint256 collateralAmount = 1 ether;
        deposit(bob, collateralAmount, underlying);
        turnOnEmode(bob);
        address debtAsset = HAY;
        uint256 debtAmount = collateralAmount / 2;
        borrow(bob, debtAmount, debtAsset);
        transferATokenRevert(bob, alice, collateralAmount, address(ATokenProxyStaker), "");
    }

    // testEmode
    function test_enableEmode() public {
        address bob = address(1);
        uint256 collateralAmount = 100 * 1e18;
        deposit(bob, collateralAmount, underlying);
        turnOnEmode(bob);
    }

    function test_disableEmode() public {
        address bob = address(1);
        uint256 collateralAmount = 100 * 1e18;
        deposit(bob, collateralAmount, underlying);
        turnOnEmode(bob);
        turnOffEmode(bob);
    }

    function test_borrowOther() public {
        address bob = address(1);
        uint256 collateralAmount = 100 * 1e18;
        deposit(bob, collateralAmount, underlying);
        turnOnCollateral(bob, underlying);
        // borrow
        uint256 borrowAmount = 100;
        // borrow(bob, borrowAmount, HAY);
        borrowExpectFail(bob, borrowAmount, HAY, '');
    }
    function test_borrowWithEmode() public {
        address bob = address(1);
        uint256 collateralAmount = 100 * 1e18;
        deposit(bob, collateralAmount, underlying);
        turnOnEmode(bob);
        turnOnCollateral(bob, underlying);
        // borrow
        uint256 borrowAmount = collateralAmount / 2;
        borrow(bob, borrowAmount, HAY);

        // same prices, emode liquidationThreshold = 9750
        uint256 calcHealthFactor = collateralAmount * liquidationThreshold * 1e18 / 10000 / borrowAmount;
        // console2.log('calcHealthFactor', calcHealthFactor);
        (,,,,, uint256 healthFactor) = pool.getUserAccountData(bob);
        assertEq(healthFactor, calcHealthFactor);
    }

    function test_flashLoanRevertWithEmode() public {
        address bob = address(1);
        uint256 collateralAmount = 100 * 1e18;
        deposit(bob, collateralAmount, underlying);
        turnOnEmode(bob);
        turnOnCollateral(bob, underlying);
        flashloanRevert(bob, collateralAmount, underlying, '91');
    }

    function test_toggleEmergencyAround() public {
        address bob = address(1);
        uint256 collateralAmount = 100 * 1e18;
        deposit(bob, collateralAmount, underlying);
        toggleEmergency();
        toggleEmergency();
        withdraw(bob, collateralAmount, underlying);
    }

    function test_toggleEmergencyAround2() public {
        toggleEmergency();
        toggleEmergency();
        address bob = address(1);
        uint256 collateralAmount = 100 * 1e18;
        deposit(bob, collateralAmount, underlying);
        withdraw(bob, collateralAmount, underlying);
    }
    function test_depositRevertWhenEmergency() public {
        toggleEmergency();
        address bob = address(1);
        uint256 collateralAmount = 100 * 1e18;
        vm.startPrank(bob);
        deal(underlying, bob, collateralAmount);
        (address ATokenProxyAddress,,) = dataProvider.getReserveTokensAddresses(underlying);
        uint256 before_aToken = IERC20(ATokenProxyAddress).balanceOf(bob);
        uint256 before_underlying = IERC20(underlying).balanceOf(bob);
        IERC20(underlying).approve(address(pool), collateralAmount);
        vm.expectRevert(abi.encodePacked("deposit is paused due to emergency"));
        pool.deposit(underlying, collateralAmount, bob, 0);
    }

    function test_withdrawWhenEmergency() public {address bob = address(1);
        uint256 collateralAmount = 100 * 1e18;
        deposit(bob, collateralAmount, underlying);
        toggleEmergency();
        withdraw(bob, collateralAmount, underlying);
    }
    

}