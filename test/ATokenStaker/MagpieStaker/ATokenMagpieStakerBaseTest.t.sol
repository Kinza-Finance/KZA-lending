
import {BaseTest} from "test/BaseTest.t.sol";

import "../../../src/core/dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {IPoolAddressesProvider} from "../../../src/core/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "../../../src/core/interfaces/IPool.sol";
import {IACLManager} from '../../../src/core/interfaces/IACLManager.sol';
import {IAaveIncentivesController} from '../../../src/core/interfaces/IAaveIncentivesController.sol';
import {AToken} from "../../../src/core/protocol/tokenization/AToken.sol";
import {ATokenMagpieStaker} from "../../../src/core/protocol/tokenization/ATokenMagpieStaker.sol";
import {ZeroReserveInterestRateStrategy} from "../../../src/core/misc/ZeroReserveInterestRateStrategy.sol";
import {PoolConfigurator} from "../../../src/core/protocol/pool/PoolConfigurator.sol";
import {EmissionAdminAndDirectTransferStrategy} from "../../../src/core/protocol/tokenization/EmissionAdminAndDirectTransferStrategy.sol";
import {ConfiguratorInputTypes} from '../../../src/core/protocol/libraries/types/ConfiguratorInputTypes.sol';
import {ReservesSetupHelper} from "../../../src/core/deployments/ReservesSetupHelper.sol";

import {ADDRESSES_PROVIDER, POOLDATA_PROVIDER, ACL_MANAGER, POOL, POOL_CONFIGURATOR, EMISSION_MANAGER, 
        ATOKENIMPL, SDTOKENIMPL, VDTOKENIMPL, TREASURY, POOL_ADMIN,
        MASTER_MAGPIE, SMART_HAY_LP, WOMBAT_HELPER_SMART_HAY_LP} from "test/utils/Addresses.sol";

contract ATokenMagpieStakerBaseTest is BaseTest {
    address internal underlying = SMART_HAY_LP;
    ATokenMagpieStaker internal ATokenProxyStaker;
    EmissionAdminAndDirectTransferStrategy internal emissionAdmin;
    function setUp() public virtual override(BaseTest) {
        BaseTest.setUp();
        emissionAdmin = new EmissionAdminAndDirectTransferStrategy(pool, emissionManager);
        // deploy reserve, get ATokenProxy
        address aTokenProxy = deployReserveForATokenStaker();
        ATokenProxyStaker = ATokenMagpieStaker(aTokenProxy);
        // configure riskParameter
        configuraRiskParameterForReserve(underlying);
        vm.startPrank(POOL_ADMIN);
        // the magpie stakerAToken require setting up 1.) wombat helper for deposit
        // 2.) master magpir for withdrawal
        // 3.) emissionAdmin for sending over reward
        ATokenProxyStaker.updateWombatHelper(WOMBAT_HELPER_SMART_HAY_LP);
        ATokenProxyStaker.updateMasterMagpie(MASTER_MAGPIE);
        // ATokenProxyStaker.updateEmissionAdmin();
        
    }

    // return aTokenProxy
    function deployReserveForATokenStaker() public returns (address) {
        vm.startPrank(POOL_ADMIN);
        bytes32 incentivesControllerId = 0x703c2c8634bed68d98c029c18f310e7f7ec0e5d6342c590190b3cb8b3ba54532;
        address incentivesController = provider.getAddress(incentivesControllerId);
        address interestStrategyAddress = deployStrategy();
        address atokenImpl = deployATokenStakerImpl();
        ConfiguratorInputTypes.InitReserveInput[] memory inputs = new ConfiguratorInputTypes.InitReserveInput[](1);
        inputs[0] = ConfiguratorInputTypes.InitReserveInput(
            atokenImpl,
            SDTOKENIMPL,
            VDTOKENIMPL,
            IERC20Detailed(underlying).decimals(),
            interestStrategyAddress,
            underlying,
            TREASURY,
            incentivesController,
            string(abi.encodePacked("Kinza", "LP-HAY")),
            string(abi.encodePacked("k", "LP-HAY")),
            string(abi.encodePacked("Kinza Variable Debt ", "LP-HAY")),
            string(abi.encodePacked("vDebt", "LP-HAY")),
            string(abi.encodePacked("Kinza Stable Debt ", "LP-HAY")),
            string(abi.encodePacked("sDebt", "LP-HAY")),
            abi.encodePacked("0x10")
            );
        configurator.initReserves(inputs);
        
        (address ATokenProxyAddress,,) = dataProvider.getReserveTokensAddresses(underlying);
        require(ATokenProxyAddress != address(0), "AToken not set");
        return ATokenProxyAddress;
    }

    function deployATokenStakerImpl() internal returns(address) {
            ATokenMagpieStaker aTokenImpl = new ATokenMagpieStaker(pool);
            aTokenImpl.initialize(
            pool,
            address(0), // treasury
            address(0), // underlyingAsset
            IAaveIncentivesController(address(0)), // incentivesController
            0, // aTokenDecimals
            "ATOKEN_IMPL", // aTokenName
            "ATOKEN_IMPL", // aTokenSymbol
            "0x00" // param
        );
        return address(aTokenImpl);
    }
    function deployStrategy() internal returns (address) {
            ZeroReserveInterestRateStrategy interestRateStrategy = new ZeroReserveInterestRateStrategy(
                IPoolAddressesProvider(ADDRESSES_PROVIDER)
            );
            return address(interestRateStrategy);
    }

    function configuraRiskParameterForReserve(address underlying) internal {
        aclManager.addPoolAdmin(address(helper));
        ReservesSetupHelper.ConfigureReserveInput[] memory inputs = new ReservesSetupHelper.ConfigureReserveInput[](1);
        inputs[0] = ReservesSetupHelper.ConfigureReserveInput(
                underlying,
                8000, // baseLTV
                9000, // liquidationThreshold
                10800, // liquidationBonus
                1500, // reserveFactor
                1000000, //borrowCap
                2000000, //supplyCap
                false, //stableBorrowingEnabled
                false, //borrowingEnabled
                false //flashLoanEnabled
                );
        helper.configureReserves(PoolConfigurator(address(configurator)), inputs);
        //remove helper from pool admin
        aclManager.removePoolAdmin(address(helper));
    }
       
}