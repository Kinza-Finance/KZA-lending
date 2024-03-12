
import {BaseTest} from "test/BaseTest.t.sol";

import "../../../src/core/dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {IPoolAddressesProvider} from "../../../src/core/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "../../../src/core/interfaces/IPool.sol";
import {IACLManager} from '../../../src/core/interfaces/IACLManager.sol';
import {IAaveOracle} from '../../../src/core/interfaces/IAaveOracle.sol';
import {IAaveIncentivesController} from '../../../src/core/interfaces/IAaveIncentivesController.sol';
import {IMasterWombat} from '../../../src/core/interfaces/IMasterWombat.sol';
import {AToken} from "../../../src/core/protocol/tokenization/AToken.sol";
import {SmartHayPoolOracle} from "../../../src/core/misc/wombatOracle/SmartHayPoolOracle.sol";
import {ATokenWombatStaker} from "../../../src/core/protocol/tokenization/ATokenWombatStaker.sol";
import {ZeroReserveInterestRateStrategy} from "../../../src/core/misc/ZeroReserveInterestRateStrategy.sol";
import {PoolConfigurator} from "../../../src/core/protocol/pool/PoolConfigurator.sol";
import {EmissionAdminAndDirectTransferStrategy} from "../../../src/core/protocol/tokenization/EmissionAdminAndDirectTransferStrategy.sol";
import {ConfiguratorInputTypes} from '../../../src/core/protocol/libraries/types/ConfiguratorInputTypes.sol';
import {ReservesSetupHelper} from "../../../src/core/deployments/ReservesSetupHelper.sol";
import {Pool} from "../../../src/core/protocol/pool/Pool.sol";
import {PoolConfigurator} from "../../../src/core/protocol/pool/PoolConfigurator.sol";

import {USDC, ADDRESSES_PROVIDER, POOLDATA_PROVIDER, ACL_MANAGER, POOL, POOL_CONFIGURATOR, EMISSION_MANAGER, 
        ATOKENIMPL, SDTOKENIMPL, VDTOKENIMPL, TREASURY, POOL_ADMIN, ORACLE, HAY_AGGREGATOR, HAY,
        LIQUIDATION_ADAPTOR, RANDOM,
        USDC_AGGREGATOR, USDT_AGGREGATOR, USDC, USDT, TIMELOCK, POOLCONFIG_IMPL_V2, POOL_IMPL_V2} from "test/utils/Addresses.sol";

contract BitmapUpgradeBaseTest is BaseTest {
    function setUp() public virtual override(BaseTest) {
        BaseTest.setUp();
        // upgrade pool
        // Pool poolV2 = new Pool(IPoolAddressesProvider(ADDRESSES_PROVIDER));
        // poolV2.initialize(IPoolAddressesProvider(ADDRESSES_PROVIDER));
        // upgrade
        vm.startPrank(TIMELOCK);
        provider.setPoolImpl(address(POOL_IMPL_V2));
        assertEq(Pool(address(pool)).POOL_REVISION(), Pool(POOL_IMPL_V2).POOL_REVISION());
        // upgrade poolConfigurator
        // PoolConfigurator configuratorV2 = new PoolConfigurator();
        // configuratorV2.initialize(IPoolAddressesProvider(ADDRESSES_PROVIDER));
        provider.setPoolConfiguratorImpl(address(POOLCONFIG_IMPL_V2));
        assertEq(PoolConfigurator(address(configurator)).CONFIGURATOR_REVISION(), PoolConfigurator(POOLCONFIG_IMPL_V2).CONFIGURATOR_REVISION());
    }

    function setUpBlacklistForReserve(uint256 reserveIndex, uint128 bitmap) internal {
        address reserve = pool.getReserveAddressById(uint16(reserveIndex));
        vm.startPrank(POOL_ADMIN);
        configurator.setReserveBlacklistBitmap(reserve, bitmap);
    }

    function setUpBlacklistForReserveExceptOneAllowed(uint256 reserveIndex, address allowedReserve) internal {
        uint16 allowedReserveIndex = pool.getReserveData(allowedReserve).id;
        uint256 bitmap = type(uint128).max;
        bitmap ^= 1 << allowedReserveIndex;
        setUpBlacklistForReserve(reserveIndex, uint128(bitmap));
    }

    function setUpBlacklistForReserveExceptOneBlocked(uint256 reserveIndex, address blockedReserve) internal {
        uint16 blockedReserveIndex = pool.getReserveData(blockedReserve).id;
        uint256 bitmap = 0;
        bitmap ^= 1 << blockedReserveIndex;
        setUpBlacklistForReserve(reserveIndex, uint128(bitmap));
    }

    function turnOnCollateral(address user, address collateral) internal {
        vm.startPrank(user);
        pool.setUserUseReserveAsCollateral(collateral, true);
    }

    function turnOnCollateralExpectFail(address user, address collateral, string memory errorMsg) internal {
        vm.startPrank(user);
        vm.expectRevert(abi.encodePacked(errorMsg));
        pool.setUserUseReserveAsCollateral(collateral, true);
    }

    function turnOffCollateral(address user, address collateral) internal {
        vm.startPrank(user);
        pool.setUserUseReserveAsCollateral(collateral, false);
    }

    function deposit(address user, uint256 amount, address underlying) internal {
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

    function withdraw(address user, uint256 amount, address underlying) internal {
        vm.startPrank(user);
        (address ATokenProxyAddress,,) = dataProvider.getReserveTokensAddresses(underlying);
        uint256 before_aToken = IERC20(ATokenProxyAddress).balanceOf(user);
        uint256 before_underlying = IERC20(underlying).balanceOf(user);
        pool.withdraw(underlying, amount, user);
        assertEq(IERC20(ATokenProxyAddress).balanceOf(user), before_aToken - amount);
        assertEq(IERC20(underlying).balanceOf(user), before_underlying + amount);
    }

    function repay(address user, uint256 amount, address underlying) internal {
        // try not to pass uint256 max which break the assertion
        vm.startPrank(user);
        deal(underlying, user, amount);
        (,,address vdTokenProxyAddress) = dataProvider.getReserveTokensAddresses(underlying);
        uint256 before_dToken = IERC20(vdTokenProxyAddress).balanceOf(user);
        uint256 before_underlying = IERC20(underlying).balanceOf(user);
        IERC20(underlying).approve(address(pool), amount);
        // 2 is variable interest rate
        pool.repay(underlying, amount, 2, user);
        // 1e18 is 100%, only may have dust debt due to division round down
        assertApproxEqRel(IERC20(vdTokenProxyAddress).balanceOf(user), before_dToken - amount, 1e3);
        assertEq(IERC20(underlying).balanceOf(user), before_underlying - amount);
    }

    function borrow(address user, uint256 amount, address underlying) internal {
         vm.startPrank(user);
         // 2 = variable mode, 0 = no referral
         pool.borrow(underlying, amount, 2, 0, user);
    }
    function borrowExpectFail(address user, uint256 amount, address underlying, string memory errorMsg) internal {
         vm.startPrank(user);
         vm.expectRevert(abi.encodePacked(errorMsg));
         // 2 = variable mode, 0 = no referral
         pool.borrow(underlying, amount, 2, 0, user);
    }

    function transferAToken(address user, uint256 amount, address underlying) internal {
        address sender = address(16);
        deposit(sender, amount, underlying);
        vm.startPrank(sender);
        (address aToken,,) = dataProvider.getReserveTokensAddresses(underlying);
        IERC20(aToken).transfer(user, amount);
    }

    function liquidate(address user, uint256 debtToCover, address collateral, address borrowed) internal {
        address liquidator = address(16);
        deal(borrowed, liquidator, debtToCover);
        vm.startPrank(liquidator);
        IERC20(borrowed).approve(address(pool), debtToCover);
        pool.liquidationCall(collateral, borrowed, user, debtToCover, false);
        assertGt(IERC20(collateral).balanceOf(liquidator), 0);
    }
}