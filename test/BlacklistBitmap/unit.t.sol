
import {BitmapUpgradeBaseTest} from "./BitmapUpgradeBaseTest.t.sol";
import {IPoolAddressesProvider} from "../../../src/core/interfaces/IPoolAddressesProvider.sol";


import {TIMELOCK, ADDRESSES_PROVIDER, POOLDATA_PROVIDER, ACL_MANAGER, POOL, POOL_CONFIGURATOR, EMISSION_MANAGER, 
        ATOKENIMPL, SDTOKENIMPL, VDTOKENIMPL, TREASURY, POOL_ADMIN, HAY_AGGREGATOR, USDC, USDT, HAY,
        LIQUIDATION_ADAPTOR, BORROWABLE_DATA_PROVIDER} from "test/utils/AddressesTest.sol";

// @dev disable linked lib in foundry.toml, since forge test would inherit those setting
// https://book.getfoundry.sh/reference/forge/forge-build?highlight=link#linker-options
contract blacklistBitmapUpgradeUnitTest is BitmapUpgradeBaseTest {

    function setUp() public virtual override(BitmapUpgradeBaseTest) {
        BitmapUpgradeBaseTest.setUp();
        
    }

    function test_blockUSDCViewBorrowable() public {
        uint16 reserveIndex = pool.getReserveData(USDC).id;
        setUpBlacklistForReserve(reserveIndex, type(uint128).max);
        uint256 reservesCount = pool.getReservesList().length;
        for (uint256 i; i < reservesCount; i++) {
            assertEq(false, pool.getReserveBorrowable(reserveIndex, uint16(i)));
        }
        
    }
    function test_blockUSDCFromBorrowing() public {
        // every asset gets blocked
        uint16 reserveIndex = pool.getReserveData(USDC).id;
        setUpBlacklistForReserve(reserveIndex, type(uint128).max);
        uint256 amount = 1e18;
        address user = address(1);
        deposit(user, amount, USDC);
        borrowExpectFail(user, amount / 2, USDC, "92");
    }

    function test_blockUSDCFromBorrowingOther() public {
        // every asset gets blocked
        uint16 reserveIndex = pool.getReserveData(USDC).id;
        setUpBlacklistForReserve(reserveIndex, type(uint128).max);
        uint256 amount = 1e18;
        address user = address(1);
        deposit(user, amount, USDC);
        borrowExpectFail(user, amount / 2, USDT, "92");
    }

    function test_blockUSDCFromEverythingExceptBorrowingItself() public {
        // every asset gets blocked
        uint16 reserveIndex = pool.getReserveData(USDC).id;
        // only flip the bit at reserveIndex
        uint256 bitmap = type(uint128).max;
        bitmap ^= 1 << reserveIndex;
        setUpBlacklistForReserve(reserveIndex, uint128(bitmap));
        uint256 amount = 1e18;
        address user = address(1);
        deposit(user, amount, USDC);
        borrow(user, amount / 2, USDC);
    }

    function test_blockUSDCFromEverythingExceptBorrowingHAY() public {
        // every asset gets blocked
        uint16 USDCreserveIndex = pool.getReserveData(USDC).id;
        uint16 HAYreserveIndex = pool.getReserveData(HAY).id;
        // only flip the bit at USDT reserveIndex
        uint256 bitmap = type(uint128).max;
        bitmap ^= 1 << HAYreserveIndex;
        setUpBlacklistForReserve(USDCreserveIndex, uint128(bitmap));
        uint256 amount = 1e18;
        address user = address(1);
        deposit(user, amount, USDC);
        borrow(user, amount / 2, HAY);
    }
}