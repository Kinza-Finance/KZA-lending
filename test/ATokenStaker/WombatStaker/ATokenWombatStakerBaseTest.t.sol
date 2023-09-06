
import {BaseTest} from "test/BaseTest.t.sol";

import "../../../src/core/dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {IPoolAddressesProvider} from "../../../src/core/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "../../../src/core/interfaces/IPool.sol";
import {IACLManager} from '../../../src/core/interfaces/IACLManager.sol';
import {IAaveOracle} from '../../../src/core/interfaces/IAaveOracle.sol';
import {IAaveIncentivesController} from '../../../src/core/interfaces/IAaveIncentivesController.sol';
import {IMasterWombat} from '../../../src/core/interfaces/IMasterWombat.sol';
import {AToken} from "../../../src/core/protocol/tokenization/AToken.sol";
import {GenericLPFallbackOracle} from "../../../src/core/misc/wombatOracle/GenericLPFallbackOracle.sol";
import {ATokenWombatStaker} from "../../../src/core/protocol/tokenization/ATokenWombatStaker.sol";
import {ZeroReserveInterestRateStrategy} from "../../../src/core/misc/ZeroReserveInterestRateStrategy.sol";
import {PoolConfigurator} from "../../../src/core/protocol/pool/PoolConfigurator.sol";
import {EmissionAdminAndDirectTransferStrategy} from "../../../src/core/protocol/tokenization/EmissionAdminAndDirectTransferStrategy.sol";
import {ConfiguratorInputTypes} from '../../../src/core/protocol/libraries/types/ConfiguratorInputTypes.sol';
import {ReservesSetupHelper} from "../../../src/core/deployments/ReservesSetupHelper.sol";

import {USDC, ADDRESSES_PROVIDER, POOLDATA_PROVIDER, ACL_MANAGER, POOL, POOL_CONFIGURATOR, EMISSION_MANAGER, 
        ATOKENIMPL, SDTOKENIMPL, VDTOKENIMPL, TREASURY, POOL_ADMIN, ORACLE, HAY_AGGREGATOR, HAY,
        MASTER_WOMBAT, SMART_HAY_LP, LIQUIDATION_ADAPTOR, RANDOM} from "test/utils/Addresses.sol";

contract ATokenWombatStakerBaseTest is BaseTest {
    address internal underlying = SMART_HAY_LP;
    ATokenWombatStaker internal ATokenProxyStaker;
    EmissionAdminAndDirectTransferStrategy internal emissionAdmin;
    uint8 internal eModeCategoryId = 2;
    function setUp() public virtual override(BaseTest) {
        BaseTest.setUp();
        //setup oracle 
        setUpOracleThroughFallback();
        // deploy reserve, get ATokenProxy
        address aTokenProxy = deployReserveForATokenStaker();
        ATokenProxyStaker = ATokenWombatStaker(aTokenProxy);
        // configure riskParameter
        configuraRiskParameterForReserve(underlying);
        vm.startPrank(POOL_ADMIN);
        // thewombat stakerAToken require setting up 
        // 1.) wombat master
        // 2.) emissionAdmin for sending over reward
        ATokenProxyStaker.updateMasterWombat(MASTER_WOMBAT);
        emissionAdmin = new EmissionAdminAndDirectTransferStrategy(pool, emissionManager);
        ATokenProxyStaker.updateEmissionAdmin(address(emissionAdmin));
        // add emode, setup oracle specific to the emode
        setUpEmodeAndEmodeOracle();
        addAssetIntoEmode();
    }

    // return aTokenProxy
    function deployReserveForATokenStaker() public returns (address) {
        vm.startPrank(POOL_ADMIN);
        bytes32 incentivesControllerId = 0x703c2c8634bed68d98c029c18f310e7f7ec0e5d6342c590190b3cb8b3ba54532;
        address incentivesController = provider.getAddress(incentivesControllerId);
        address interestStrategyAddress = deployZeroRateStrategy();
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
            ATokenWombatStaker aTokenImpl = new ATokenWombatStaker(pool);
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
    function deployZeroRateStrategy() internal returns (address) {
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
                100, // baseLTV
                100, // liquidationThreshold
                10100, // liquidationBonus
                1500, // reserveFactor
                1, //borrowCap
                2000000, //supplyCap
                false, //stableBorrowingEnabled
                false, //borrowingEnabled
                false //flashLoanEnabled
                );
        helper.configureReserves(PoolConfigurator(address(configurator)), inputs);
        //remove helper from pool admin
        aclManager.removePoolAdmin(address(helper));
    }

    function setUpOracleThroughFallback() internal {
        GenericLPFallbackOracle LPFallbackOracle = new GenericLPFallbackOracle();
        vm.startPrank(POOL_ADMIN);
        IAaveOracle(oracle).setFallbackOracle(address(LPFallbackOracle));
    }

    function setUpEmodeAndEmodeOracle() internal {
        // use categoryId as a magicNumber for emodeOralce asset
        // @TODO read from eModeCategoryId and convert to address
        address eModePriceAsset = address(2);
        uint16 ltv = 9700;
        uint16 liquidationThreshold = 9750;
        uint16 liquidationBonus = 10100;
        // each eMode category may or may not have a custom oracle to override the individual assets price oracles
        // use HAY oracle for now
        address EmodeOracle = HAY_AGGREGATOR;
        string memory label = "wombat LP Emode";

        vm.startPrank(POOL_ADMIN);
        configurator.setEModeCategory(eModeCategoryId, ltv, liquidationThreshold, liquidationBonus, eModePriceAsset, label);
        // then set oracle
        address[] memory assets = new address[](1);
        address[] memory sources = new address[](1);
        
        assets[0] = eModePriceAsset;
        sources[0] = EmodeOracle;
        IAaveOracle(oracle).setAssetSources(assets, sources);
    }

    function addAssetIntoEmode() internal {
        vm.startPrank(POOL_ADMIN);
        configurator.setAssetEModeCategory(underlying, eModeCategoryId);
        configurator.setAssetEModeCategory(HAY, eModeCategoryId);
    }

    function setUpOracle(address source, address asset) internal {
        address[] memory assets = new address[](1);
        address[] memory sources = new address[](1);
        assets[0] = asset;
        sources[0] = source;
        vm.startPrank(POOL_ADMIN);
        IAaveOracle(oracle).setAssetSources(assets, sources);
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

    function flashloan(address user, address dest, uint256 amount, address underlying) internal {
        vm.startPrank(user);
         // 2 = variable mode, 0 = no referral
         // no param, 0 = no referral
         // receiver needs to be a contract
        pool.flashLoanSimple(dest, underlying, amount, "", 0);
    }
    function flashloanRevert(address user, uint256 amount, address underlying, string memory errorMsg) internal {
        vm.startPrank(user);
         vm.expectRevert(abi.encodePacked(errorMsg));
         // 2 = variable mode, 0 = no referral
         // no param, 0 = no referral
         // receiver needs to be a contract
         pool.flashLoanSimple(LIQUIDATION_ADAPTOR, underlying, amount, "", 0);
    }

    function prepUSDC(address user, uint256 collateral_amount) internal {
        // deposit USDC to have some collateral power
        deposit(user, collateral_amount, USDC);
    }

    function setUpPositiveLTV() internal {
        vm.startPrank(POOL_ADMIN);
        configurator.configureReserveAsCollateral(underlying, 70, 80, 10100);
    }
    function turnOnBorrow() internal {
        vm.startPrank(POOL_ADMIN);
        configurator.setReserveBorrowing(underlying, true);
    }

    function turnOnFlashloan() internal {
        vm.startPrank(POOL_ADMIN);
        configurator.setReserveFlashLoaning(underlying, true);
    }


    function turnOnCollateral(address user, address collateral) internal {
        vm.startPrank(user);
        pool.setUserUseReserveAsCollateral(collateral, true);
    }

    function turnOnCollateralExpectRevert(address user, address collateral, string memory errorMsg) internal {
        vm.startPrank(user);
        vm.expectRevert(abi.encodePacked(errorMsg));
        pool.setUserUseReserveAsCollateral(collateral, true);
    }

    function turnOffCollateral(address user, address collateral) internal {
        vm.startPrank(user);
        pool.setUserUseReserveAsCollateral(collateral, false);
    }

    function turnOnEmode(address user) internal {
        vm.startPrank(user);
        pool.setUserEMode(eModeCategoryId);
    }

    function turnOffEmode(address user) internal {
        vm.startPrank(user);
        pool.setUserEMode(0);
    }
    
    function liquidate(address user, address debtAsset, address collateralAsset, uint256 debtToCover) internal {
        address liuqidator = RANDOM;
        deal(debtAsset, liuqidator, debtToCover);
        IERC20(debtAsset).approve(address(pool), debtToCover);
        bool receiveAToken = false;
        pool.liquidationCall(collateralAsset, debtAsset, user, debtToCover, receiveAToken);
    }

    function liquidateRevert(address user, address debtAsset, address collateralAsset, uint256 debtToCover) internal {
        address liuqidator = RANDOM;
        deal(debtAsset, liuqidator, debtToCover);
        IERC20(debtAsset).approve(address(pool), debtToCover);
        bool receiveAToken = false;
        vm.expectRevert();
        pool.liquidationCall(collateralAsset, debtAsset, user, debtToCover, receiveAToken);
    }


    function transferAToken(address from, address to, uint256 amount, address ATokenProxy) internal {
        uint256 before = IERC20(ATokenProxy).balanceOf(to);
        vm.startPrank(from);
        IERC20(ATokenProxy).transfer(to, amount);
        assertEq(before + amount, IERC20(ATokenProxy).balanceOf(to));
    }

    function transferATokenRevert(address from, address to, uint256 amount, address ATokenProxy, string memory errorMsg) internal {
        uint256 before = IERC20(ATokenProxy).balanceOf(to);
        vm.startPrank(from);
        vm.expectRevert();
        IERC20(ATokenProxy).transfer(to, amount);
    }
}