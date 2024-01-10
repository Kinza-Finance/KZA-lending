
import {BaseTest} from "test/BaseTestOpbnb.t.sol";

import "../../../src/core/dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {IPoolAddressesProvider} from "../../../src/core/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "../../../src/core/interfaces/IPool.sol";
import {IACLManager} from '../../../src/core/interfaces/IACLManager.sol';
import {IAaveOracle} from '../../../src/core/interfaces/IAaveOracle.sol';
import {ThenaLiqAdaptorAccessControl} from "../../../src/periphery/misc/ThenaLiqAdaptorAccessControl.sol";
import {ThenaRouterV2Path} from "../../../src/periphery/misc/ThenaRouterV2Path.sol";

import {ADDRESSES_PROVIDER, POOLDATA_PROVIDER, ACL_MANAGER, POOL, POOL_CONFIGURATOR, EMISSION_MANAGER, 
        ATOKENIMPL, SDTOKENIMPL, VDTOKENIMPL, TREASURY, POOL_ADMIN, ORACLE,
        RANDOM,
        USDT, WBNB, TIMELOCK} from "test/utils/AddressesOpbnb.sol";

contract ThenaCrossTokenBaseTest is BaseTest {
    //run https://opbnb-mainnet-rpc.bnbchain.org
    ThenaLiqAdaptorAccessControl internal liqAdaptor;
    // no interaction with lending before
    address internal liquidatedUser = 0xfed271605639F50467631375976f0958D4561dB4;
    address internal liquidator = 0xCCB8F7Cb8C49aB596E6F0EdDCEd3d3A6B1912c92;
    address internal depositedAsset = WBNB;
    address internal borrowedAsset = WBNB;
    uint256 internal depositAmount = 0.0000023 * 1e18;
    uint256 internal borrowAmount = depositAmount * 69 / 100;
    function setUp() public virtual override(BaseTest) {
        BaseTest.setUp();
        // deply pool
        vm.startPrank(POOL_ADMIN);
        liqAdaptor = new ThenaLiqAdaptorAccessControl(ADDRESSES_PROVIDER);
        ThenaRouterV2Path V2FallBack = new ThenaRouterV2Path();
        liqAdaptor.updateV2Fallback(address(V2FallBack));
    }
    function createLiquidatableUser() internal {
        deal(depositedAsset, liquidatedUser, depositAmount);
        vm.startPrank(liquidatedUser);
        IERC20(depositedAsset).approve(address(pool), type(uint256).max);
        pool.deposit(depositedAsset, depositAmount, liquidatedUser, 0);
        //pool.setUserUseReserveAsCollateral(depositedAsset, true);
        pool.borrow(borrowedAsset, borrowAmount, 2, 0, liquidatedUser);
        vm.warp(block.timestamp + 1000 weeks);
        (,,,,,uint256 healthFactor) = pool.getUserAccountData(liquidatedUser);
        assertGt(1e18, healthFactor);

    }
    function test_flashLiqidate() public {
        createLiquidatableUser();
        address flashToken = USDT;
        uint256 flashTokenAmount = depositAmount * 300 / 2;
        uint256 flashFee = 30;
        address debtToken = borrowedAsset;
        //FDUSD/USDT
        address flashPool = 0xdB2A373e6490600dF4AE457A0e10CDcd56E40b21;
        //uint256 debtAmount = ;
        address collateral = depositedAsset;
        uint256 debtAmount = depositAmount / 3;
        vm.startPrank(liquidator);
        uint256 beforeProfit = IERC20(flashToken).balanceOf(liquidator);
        liqAdaptor.liquidateWithFlashLoan(flashToken, flashTokenAmount, flashFee, flashPool, liquidatedUser, collateral, debtToken, debtAmount);
        assertGt(IERC20(flashToken).balanceOf(liquidator), beforeProfit);
    }


}