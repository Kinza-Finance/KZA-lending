
import {BaseTest} from "test/BaseTest.t.sol";

import "../../../src/core/dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {IPoolAddressesProvider} from "../../../src/core/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "../../../src/core/interfaces/IPool.sol";
import {IACLManager} from '../../../src/core/interfaces/IACLManager.sol';
import {IAaveOracle} from '../../../src/core/interfaces/IAaveOracle.sol';
import {AaveV2CrossTokenLiqAdatorAccessControl, IAaveV2Pool} from "../../../src/periphery/misc/AaveV2CrossTokenLiqAdatorAccessControl.sol";

import {USDC, ADDRESSES_PROVIDER, POOLDATA_PROVIDER, ACL_MANAGER, POOL, POOL_CONFIGURATOR, EMISSION_MANAGER, 
        ATOKENIMPL, SDTOKENIMPL, VDTOKENIMPL, TREASURY, POOL_ADMIN, ORACLE, HAY_AGGREGATOR, HAY,
        LIQUIDATION_ADAPTOR, RANDOM, V3FALLBACK,
        USDC_AGGREGATOR, USDT_AGGREGATOR, USDC, USDT, TIMELOCK} from "test/utils/Addresses.sol";

contract BitmapUpgradeBaseTest is BaseTest {
    AaveV2CrossTokenLiqAdatorAccessControl internal liqAdaptor;
    function setUp() public virtual override(BaseTest) {
        BaseTest.setUp();
        // deply pool
        vm.startPrank(POOL_ADMIN);
        liqAdaptor = new AaveV2CrossTokenLiqAdatorAccessControl(ADDRESSES_PROVIDER);
        liqAdaptor.updateV3Fallback(V3FALLBACK);
    }
    function test_callLiq() public {
        // address flashToken = 
        // uint256 flashTokenAmount = 
        // IAaveV2Pool pool = 
        // address user = 
        // address debtToken = 
        // uint256 debtAmount = 
        // address collateral = 
        // vm.startPrank(POOL_ADMIN);
        // liqAdaptor.liquidateWithFlashLoan(flashToken, flashTokenAmount, pool, user, collateral, debtToken, debtAmount);
    }


}