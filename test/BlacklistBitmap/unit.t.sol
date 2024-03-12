
import {BitmapUpgradeBaseTest} from "./BitmapUpgradeBaseTest.t.sol";
import {IPoolAddressesProvider} from "../../../src/core/interfaces/IPoolAddressesProvider.sol";


import {TIMELOCK, ADDRESSES_PROVIDER, POOLDATA_PROVIDER, ACL_MANAGER, POOL, POOL_CONFIGURATOR, EMISSION_MANAGER, 
        ATOKENIMPL, SDTOKENIMPL, VDTOKENIMPL, TREASURY, POOL_ADMIN, HAY_AGGREGATOR, USDC, HAY, ETH,
        LIQUIDATION_ADAPTOR, BORROWABLE_DATA_PROVIDER} from "test/utils/Addresses.sol";

// @dev disable linked lib in foundry.toml, since forge test would inherit those setting
// https://book.getfoundry.sh/reference/forge/forge-build?highlight=link#linker-options
contract blacklistBitmapUpgradeUnitTest is BitmapUpgradeBaseTest {

    function setUp() public virtual override(BitmapUpgradeBaseTest) {
        BitmapUpgradeBaseTest.setUp();
        
    }

    function test_defaultUnblocked() public {
        uint256 amount = 1e18;
        address user = address(1);
        deposit(user, amount, USDC);
        borrow(user, amount / 4, HAY);
        borrow(user, amount / 4, USDC);
    }

    function test_blockUSDCViewBorrowable() public {
        uint16 reserveIndex = pool.getReserveData(USDC).id;
        setUpBlacklistForReserve(reserveIndex, type(uint128).max);
        uint256 reservesCount = pool.getReservesList().length;
        for (uint256 i; i < reservesCount; i++) {
            address reserveToCheck = pool.getReserveAddressById(uint16(i));
            assertEq(false, pool.getReserveBorrowable(USDC, reserveToCheck));
        }
        
    }

    function test_blockUSDCCollateralizaiton() public {
        uint16 reserveIndex = pool.getReserveData(USDC).id;
        setUpBlacklistForReserve(reserveIndex, type(uint128).max);
        uint256 amount = 1e18;
        address user = address(1);
        deposit(user, amount, USDC);
        (,,,,,,,,bool isEnabled) = dataProvider.getUserReserveData(USDC, user);
        // since the user does not have any borrow
        assertEq(true, isEnabled);
    }

    function test_blockUSDCCollateralizaitonAndUseAsCollateral() public {
        uint16 reserveIndex = pool.getReserveData(USDC).id;
        setUpBlacklistForReserve(reserveIndex, type(uint128).max);
        uint256 amount = 1e18;
        address user = address(1);
        deposit(user, amount, USDC);
        // since the user does not have any borrow
        (,,,,,,,,bool isEnabled) = dataProvider.getUserReserveData(USDC, user);
        assertEq(true, isEnabled);
        turnOffCollateral(user, USDC);
        (,,,,,,,,isEnabled) = dataProvider.getUserReserveData(USDC, user);
        assertEq(false, isEnabled);
    }

    function test_borrowUSDCDefaultDisableCollateral() public {
        uint16 reserveIndex = pool.getReserveData(USDC).id;
        setUpBlacklistForReserve(reserveIndex, type(uint128).max);
        uint256 amount = 1e18;
        address user = address(1);
        deposit(user, amount, ETH);
        borrow(user, amount, USDC);
        deposit(user, amount, USDC);
        // since the user have borrowed USDC, so default is disabled as collateral
        (,,,,,,,,bool isEnabled) = dataProvider.getUserReserveData(USDC, user);
        assertEq(false, isEnabled);
    }

    function test_borrowUSDCDefaultDisableCollateralDuringTransfer() public {
        uint16 reserveIndex = pool.getReserveData(USDC).id;
        setUpBlacklistForReserve(reserveIndex, type(uint128).max);
        uint256 amount = 1e18;
        address user = address(1);
        deposit(user, amount, ETH);
        borrow(user, amount, USDC);
        transferAToken(user, amount, USDC);
        // since the user have borrowed USDC, so default is disabled as collateral
        (,,,,,,,,bool isEnabled) = dataProvider.getUserReserveData(USDC, user);
        assertEq(false, isEnabled);
    }

    function test_borrowUSDCFromTransfer() public {
        uint256 amount = 1e18;
        address user = address(1);
        transferAToken(user, amount, ETH);
        borrow(user, amount, USDC);
        // since the user have borrowed USDC, so default is disabled as collateral
        (,,,,,,,,bool isEnabled) = dataProvider.getUserReserveData(ETH, user);
        assertEq(true, isEnabled);
    }


    function test_blockUSDCFromBorrowing() public {
        uint256 amount = 1e18;
        address user = address(1);
        deposit(user, amount, USDC);
        // every asset gets blocked
        uint16 reserveIndex = pool.getReserveData(USDC).id;
        setUpBlacklistForReserve(reserveIndex, type(uint128).max);
        borrowExpectFail(user, amount / 2, USDC, "92");
    }

    function test_blockUSDCFromBorrowingWithExistingBorrow() public {
        uint256 amount = 1e18;
        address user = address(1);
        deposit(user, amount, USDC);
        borrow(user, amount / 4, USDC);
        // every asset gets blocked
        uint16 reserveIndex = pool.getReserveData(USDC).id;
        setUpBlacklistForReserve(reserveIndex, type(uint128).max);
        borrowExpectFail(user, amount / 4, USDC, "92");
    }

    function test_UseAsCollateralWithExistingBlacklist() public {
        uint256 amount = 1e18;
        address user = address(1);
        deposit(user, amount, ETH);
        borrow(user, amount / 4, HAY);
        uint16 USDCreserveIndex = pool.getReserveData(USDC).id;
        uint16 HAYreserveIndex = pool.getReserveData(HAY).id;
        // only flip the bit at HAY reserveIndex
        uint256 bitmap = 0;
        bitmap ^= 1 << HAYreserveIndex;
        setUpBlacklistForReserve(USDCreserveIndex, uint128(bitmap));
        deposit(user, amount, USDC);
        turnOnCollateralExpectFail(user, USDC, '62');
    }

    function test_blockUSDCFromBorrowingOther() public {
        uint256 amount = 1e18;
        address user = address(1);
        deposit(user, amount, USDC);
        // every asset gets blocked
        uint16 reserveIndex = pool.getReserveData(USDC).id;
        setUpBlacklistForReserve(reserveIndex, type(uint128).max);
        borrowExpectFail(user, amount / 2, HAY, "92");
    }

    function test_turnOffCollateralAfterBlacklist() public {
        uint256 amount = 1e18;
        address user = address(1);
        deposit(user, amount, USDC);
        deposit(user, amount, ETH);
        borrow(user, amount / 4, HAY);
        // every asset gets blocked
        uint16 USDCreserveIndex = pool.getReserveData(USDC).id;
        uint16 HAYreserveIndex = pool.getReserveData(HAY).id;
        // only flip the bit at HAY reserveIndex
        uint256 bitmap = 0;
        bitmap ^= 1 << HAYreserveIndex;
        setUpBlacklistForReserve(USDCreserveIndex, uint128(bitmap));
        turnOffCollateral(user, USDC);
    }

     function test_repayAfterBlacklist() public {
        uint256 amount = 1e18;
        address user = address(1);
        deposit(user, amount, USDC);
        borrow(user, amount / 4, HAY);
        // every asset gets blocked
        uint16 USDCreserveIndex = pool.getReserveData(USDC).id;
        uint16 HAYreserveIndex = pool.getReserveData(HAY).id;
        // only flip the bit at HAY reserveIndex
        uint256 bitmap = 0;
        bitmap ^= 1 << HAYreserveIndex;
        setUpBlacklistForReserve(USDCreserveIndex, uint128(bitmap));
        repay(user, amount / 4, HAY);
        
    }

    function test_blockUSDCFromBorrowingOtherWithExistingBorrow() public {
        uint256 amount = 1e18;
        address user = address(1);
        deposit(user, amount, USDC);
        borrow(user, amount / 4, HAY);
        // every asset gets blocked
        uint16 reserveIndex = pool.getReserveData(USDC).id;
        setUpBlacklistForReserve(reserveIndex, type(uint128).max);
        
        borrowExpectFail(user, amount / 4, HAY, "92");
    }

    function test_blockUSDCFromEverythingExceptBorrowingItself() public {
        uint256 amount = 1e18;
        address user = address(1);
        deposit(user, amount, USDC);
        // every asset gets blocked
        uint16 reserveIndex = pool.getReserveData(USDC).id;
        // only flip the bit at reserveIndex
        uint256 bitmap = type(uint128).max;
        bitmap ^= 1 << reserveIndex;
        setUpBlacklistForReserve(reserveIndex, uint128(bitmap));
        borrow(user, amount / 2, USDC);
    }

    function test_blockUSDCFromEverythingExceptBorrowingHAY() public {
        // every asset gets blocked
        uint16 USDCreserveIndex = pool.getReserveData(USDC).id;
        uint16 HAYreserveIndex = pool.getReserveData(HAY).id;
        uint256 amount = 1e18;
        address user = address(1);
        deposit(user, amount, USDC);
        uint256 bitmap = type(uint128).max;
        bitmap ^= 1 << HAYreserveIndex;
        setUpBlacklistForReserve(USDCreserveIndex, uint128(bitmap));
        borrow(user, amount / 2, HAY);
    }


    function test_multipleCollateralBlockOne() public {
        uint256 amount = 1e18;
        address user = address(1);
        deposit(user, amount, USDC);
        deposit(user, amount, HAY);
        // block USDC
         uint16 reserveIndex = pool.getReserveData(USDC).id;
        uint256 bitmap = type(uint128).max;
        setUpBlacklistForReserve(reserveIndex, uint128(bitmap));
        borrowExpectFail(user, amount / 2 , HAY, "92");
    }

        function test_multipleCollateralblockOneFromEverythingExceptBorrowingHAY() public {
        uint256 amount = 1e18;
        address user = address(1);
        deposit(user, amount, USDC);
        deposit(user, amount, HAY);
        // every asset gets blocked
        uint16 USDCreserveIndex = pool.getReserveData(USDC).id;
        uint16 HAYreserveIndex = pool.getReserveData(HAY).id;
        // only flip the bit at HAY reserveIndex
        uint256 bitmap = type(uint128).max;
        bitmap ^= 1 << HAYreserveIndex;
        setUpBlacklistForReserve(USDCreserveIndex, uint128(bitmap));
        setUpBlacklistForReserve(HAYreserveIndex, uint128(bitmap));
        borrow(user, amount / 2, HAY);
    }
}