// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;
import "src/StrategyTests.sol";

contract DeployedStrategyTest is StrategyTests {

    uint256 constant FORK_BLOCK_NUMBER = 196561436;

    function selectFork() internal {
        uint256 fork = vm.createFork(vm.envString("RPC_URL_ARBITRUM"));
        vm.selectFork(fork);
        vm.rollFork(FORK_BLOCK_NUMBER);
    }

    function setUp() public {
        selectFork();
        PARSER = IParserV1(0x22410e2a46261a1B1e3899a072f303022801C764);
        ORDERBOOK = IOrderBookV3(0x90CAF23eA7E507BB722647B0674e50D8d6468234);
        ARB_INSTANCE = IOrderBookV3ArbOrderTaker(0xf382cbF44901cD26D14B247F4EA7260ee8041157);
        EXPRESSION_DEPLOYER = IExpressionDeployerV3(0x2AeE87D75CD000583DAEC7A28db103B1c0c18b76);
        ROUTE_PROCESSOR = IRouteProcessor(address(0x09bD2A33c47746fF03b86BCe4E885D03C74a8E8C));
        EXTERNAL_EOA = address(0x654FEf5Fb8A1C91ad47Ba192F7AA81dd3C821427);
        APPROVED_EOA = address(0x669845c29D9B1A64FFF66a55aA13EB4adB889a88);
        ORDER_OWNER = address(0x19f95a84aa1C48A2c6a7B2d5de164331c86D030C);
    }

    function testDeployedStrategy() public {
        
        IO[] memory inputVaults = new IO[](1);
        IO memory inputVault = IO(address(0x6d3AbB80c3CBAe0f60ba274F36137298D8571Fbe), 18, 1);
        inputVaults[0] = inputVault;

        IO[] memory outputVaults = new IO[](1);
        IO memory outputVault = IO(address(0x667f41fF7D9c06D2dd18511b32041fC6570Dc468), 18, 1);
        outputVaults[0] = outputVault;

        uint256 expectedRatio = 2e18;
        uint256 expectedAmountOutputMax = 1e18;


        LibStrategyDeployment.StrategyDeployment memory strategy = LibStrategyDeployment.StrategyDeployment(
            "",
            "",
            0,
            0,
            0,
            10000e6,
            expectedRatio,
            expectedAmountOutputMax,
            "test/strategies/arbitrum-order.rain",
            "arbitrum-order-simulations",
            "./lib/rain.orderbook",
            "./lib/rain.orderbook/Cargo.toml",
            inputVaults,
            outputVaults
        );
        checkStrategyCalculations(strategy);
    }

} 