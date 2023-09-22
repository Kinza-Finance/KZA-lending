
import {BitmapUpgradeBaseTest} from "./BitmapUpgradeBaseTest.t.sol";
import {IPoolAddressesProvider} from "../../../src/core/interfaces/IPoolAddressesProvider.sol";


import {TIMELOCK, ADDRESSES_PROVIDER, POOLDATA_PROVIDER, ACL_MANAGER, POOL, POOL_CONFIGURATOR, EMISSION_MANAGER, 
        ATOKENIMPL, SDTOKENIMPL, VDTOKENIMPL, TREASURY, POOL_ADMIN, HAY_AGGREGATOR, USDC, USDT, HAY,
        LIQUIDATION_ADAPTOR, BORROWABLE_DATA_PROVIDER} from "test/utils/AddressesTest.sol";

// @dev disable linked lib in foundry.toml, since forge test would inherit those setting
// https://book.getfoundry.sh/reference/forge/forge-build?highlight=link#linker-options
contract blacklistBitmapUpgradeFuzzTest is BitmapUpgradeBaseTest {

    function setUp() public virtual override(BitmapUpgradeBaseTest) {
        BitmapUpgradeBaseTest.setUp();
    }

    function testFuzz_block1AssetRevert(uint16 reserveIndexToBlock) public {
        address bob = address(1);
        deposit(bob, 1e18, USDC);
        uint256 reservesCount = pool.getReservesList().length;
        vm.assume(reserveIndexToBlock < reservesCount);
        address reserveToBlock = pool.getReserveAddressById(reserveIndexToBlock);
        // hardcoding collateral as USDC since some collateral may reach certain constraint (isolated etc)
        uint16 reserveIndexCollateral = pool.getReserveData(USDC).id;
        setUpBlacklistForReserveExceptOneBlocked(reserveIndexCollateral, reserveToBlock);
        // borrowing a small amount, would not breach LTV requirement 
        // 92 is the expected error message for the bitmap blacklist
        borrowExpectFail(bob, 1e9, reserveToBlock, "92");
    }

     function testFuzz_block1AssetPass(uint16 reserveIndexToBlock) public {
        address bob = address(1);
        deposit(bob, 1e18, USDC);
        uint256 reservesCount = pool.getReservesList().length;
        vm.assume(reserveIndexToBlock < reservesCount);
        address reserveToBlock = pool.getReserveAddressById(reserveIndexToBlock);
        // hardcoding collateral as USDC since some collateral may reach certain constraint (isolated etc)
        uint16 reserveIndexCollateral = pool.getReserveData(USDC).id;
        setUpBlacklistForReserveExceptOneBlocked(reserveIndexCollateral, reserveToBlock);
        // borrowing a small amount, would not breach LTV requirement 
        // 92 is the expected error message for the bitmap blacklist
        for (uint16 i; i < reservesCount; i++) {
            if (i == reserveIndexToBlock) {
                continue;
            }
            address reserveToBorrow = pool.getReserveAddressById(i);
            (,,,,,,,,bool isActive, bool isFrozen) = dataProvider.getReserveConfigurationData(reserveToBorrow);
            if (!isActive && !isFrozen) {
                borrow(bob, 1e9, reserveToBorrow);
            }
        }
    }

    function testFuzz_allow1AssetRevert(uint16 reserveIndexToAllow) public {
        address bob = address(1);
        deposit(bob, 1e18, USDC);
        uint256 reservesCount = pool.getReservesList().length;
        vm.assume(reserveIndexToAllow < reservesCount);
        address reserveToAllow = pool.getReserveAddressById(reserveIndexToAllow);
        // hardcoding collateral as USDC since some collateral may reach certain constraint (isolated etc)
        uint16 reserveIndexCollateral = pool.getReserveData(USDC).id;
        setUpBlacklistForReserveExceptOneAllowed(reserveIndexCollateral, reserveToAllow);
        // borrowing a small amount, would not breach LTV requirement 
        // 92 is the expected error message for the bitmap blacklist
        for (uint16 i; i < reservesCount; i++) {
            if (i == reserveIndexToAllow) {
                continue;
            }
            address reserveToBorrow = pool.getReserveAddressById(i);
            borrowExpectFail(bob, 1e9, reserveToBorrow, "92");
        }
    }

    function testFuzz_allow1AssetPass(uint16 reserveIndexToAllow) public {
        address bob = address(1);
        deposit(bob, 1e18, USDC);
        uint256 reservesCount = pool.getReservesList().length;
        vm.assume(reserveIndexToAllow < reservesCount);
        address reserveToAllow = pool.getReserveAddressById(reserveIndexToAllow);
        // hardcoding collateral as USDC since some collateral may reach certain constraint (isolated etc)
        uint16 reserveIndexCollateral = pool.getReserveData(USDC).id;
        setUpBlacklistForReserveExceptOneAllowed(reserveIndexCollateral, reserveToAllow);
        (,,,,,,,,bool isActive, bool isFrozen) = dataProvider.getReserveConfigurationData(reserveToAllow);
        if (!isActive && !isFrozen) {
            borrow(bob, 1e9, reserveToAllow);
        }   
    }
}