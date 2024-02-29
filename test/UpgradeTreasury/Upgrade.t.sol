
import {BaseTest} from "test/BaseTest.t.sol";

import "../../../src/core/dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {IPoolAddressesProvider} from "../../../src/core/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "../../../src/core/interfaces/IPool.sol";
import {IACLManager} from '../../../src/core/interfaces/IACLManager.sol';
import {IAaveOracle} from '../../../src/core/interfaces/IAaveOracle.sol';
import {IAaveIncentivesController} from '../../../src/core/interfaces/IAaveIncentivesController.sol';
import {IMasterWombat} from '../../../src/core/interfaces/IMasterWombat.sol';
import {AToken} from "../../../src/core/protocol/tokenization/AToken.sol";
import {PoolConfigurator} from "../../../src/core/protocol/pool/PoolConfigurator.sol";
import {EmissionAdminAndDirectTransferStrategy} from "../../../src/core/protocol/tokenization/EmissionAdminAndDirectTransferStrategy.sol";
import {ConfiguratorInputTypes} from '../../../src/core/protocol/libraries/types/ConfiguratorInputTypes.sol';
import {Pool} from "../../../src/core/protocol/pool/Pool.sol";
import {PoolConfigurator} from "../../../src/core/protocol/pool/PoolConfigurator.sol";


import {ATokenSetupHelperV2} from "../../../src/core/deployments/ATokenSetupHelperV2.sol";
import {ReserveDistributor} from "../../../src/periphery/treasury/ReserveDistributor.sol";

import {USDC, ADDRESSES_PROVIDER, POOLDATA_PROVIDER, ACL_MANAGER, POOL, POOL_CONFIGURATOR, EMISSION_MANAGER, 
        ATOKENIMPL, SDTOKENIMPL, VDTOKENIMPL, TREASURY, POOL_ADMIN, ORACLE, HAY_AGGREGATOR, HAY,
        LIQUIDATION_ADAPTOR, RANDOM,
        USDC_AGGREGATOR, USDT_AGGREGATOR, USDC, USDT, TIMELOCK} from "test/utils/Addresses.sol";

contract ATokenUpgradeBaseTest is BaseTest {
    function setUp() public virtual override(BaseTest) {
        BaseTest.setUp();
        // deploy impl
        ReserveDistributor rdImpl = new ReserveDistributor();
        rdImpl.initialize(address(0), address(0), address(0), address(0), address(0));
        // deploy proxy
        provider.setPoolImpl(address(poolV2));
        // deploy ATokenSetupHelper2
        // check version
        assertEq(Pool(address(pool)).POOL_REVISION(), poolV2.POOL_REVISION());
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
}