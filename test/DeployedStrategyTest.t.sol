// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import "src/StrategyTests.sol";

/// @title DeployedStrategyTest
/// @notice The contract inherits StrategyTests.sol.
/// DISP and OrderBook contracts need to be intiliazed as part of the setup for
/// running the tests available in StrategyTests.sol.
/// This is how the inheriting repo that has the test suite as a dependency is expected
/// to initialize the suite for a particular fork.
contract DeployedStrategyTest is StrategyTests {
    // Inheriting contract defines the fork block number.
    uint256 constant FORK_BLOCK_NUMBER = 17300025;

    // https://basescan.org/address/0x222789334d44bb5b2364939477e15a6c981ca165
    address constant RED_TOKEN = address(0x222789334D44bB5b2364939477E15A6c981Ca165);

    // https://basescan.org/address/0x6d3abb80c3cbae0f60ba274f36137298d8571fbe
    address constant BLUE_TOKEN = address(0x6d3AbB80c3CBAe0f60ba274F36137298D8571Fbe);

    // Inheriting contract defines fork selection.
    function selectFork() internal {
        uint256 fork = vm.createFork(vm.envString("RPC_URL_BASE"));
        vm.selectFork(fork);
        vm.rollFork(FORK_BLOCK_NUMBER);
    }

    // Inheriting contract initializes the contracts on the fork.
    function setUp() public {
        selectFork();
        
        iParser = IParserV2(0x56394785a22b3BE25470a0e03eD9E0a939C47b9b);
        iStore = IInterpreterStoreV2(0x6E4b01603edBDa617002A077420E98C86595748E); 
        iInterpreter = IInterpreterV3(0x379b966DC6B117dD47b5Fc5308534256a4Ab1BCC); 
        iExpressionDeployer = IExpressionDeployerV3(0x56394785a22b3BE25470a0e03eD9E0a939C47b9b); 
        iOrderBook = IOrderBookV4(0xA2f56F8F74B7d04d61f281BE6576b6155581dcBA);
        iArbInstance = IOrderBookV4ArbOrderTaker(0xF97A86C2Cb3e42f89AC5f5AA020E5c3505015a88);
        iRouteProcessor = IRouteProcessor(address(0x0389879e0156033202C44BF784ac18fC02edeE4f)); 
        EXTERNAL_EOA = address(0x654FEf5Fb8A1C91ad47Ba192F7AA81dd3C821427);
        APPROVED_EOA = address(0x669845c29D9B1A64FFF66a55aA13EB4adB889a88);
        ORDER_OWNER = address(0x5e01e44aE1969e16B9160d903B6F2aa991a37B21); 

    }

    // Inheriting contract tests OrderBook strategy with test suite.
    function testDeployedStrategy() public {
        // Input vaults
        IO[] memory inputVaults = new IO[](1);
        IO memory inputVault = IO(BLUE_TOKEN, 18, 1);
        inputVaults[0] = inputVault;

        // Output vaults
        IO[] memory outputVaults = new IO[](1);
        IO memory outputVault = IO(RED_TOKEN, 18, 1);
        outputVaults[0] = outputVault;

        // Expected calculations context
        uint256 expectedRatio = 1e10;
        uint256 expectedAmountOutputMax = 1e18;

        // Init params for the strategy
        LibStrategyDeployment.StrategyDeployment memory strategy = LibStrategyDeployment.StrategyDeployment(
            "",
            "",
            0,
            0,
            5e17,
            1e18,
            expectedRatio,
            expectedAmountOutputMax,
            "test/strategies/base-order.rain",
            "base-order-simulations",
            "./lib/rain.orderbook",
            "./lib/rain.orderbook/Cargo.toml",
            inputVaults,
            outputVaults
        );

        // Assert strategy calculations by executing order by directly calling 'takeOrder' function
        // from the OrderBook contract.
        checkStrategyCalculations(strategy);
    }

    // Inheriting contract tests OrderBook strategy with test suite.
    function testDeployedStrategyArbOrder() public {
        // Input vaults
        IO[] memory inputVaults = new IO[](1);
        IO memory inputVault = IO(BLUE_TOKEN, 18, 1);
        inputVaults[0] = inputVault;

        // Output vaults
        IO[] memory outputVaults = new IO[](1);
        IO memory outputVault = IO(RED_TOKEN, 18, 1);
        outputVaults[0] = outputVault;

        // Expected calculations context
        uint256 expectedRatio = 1e10;
        uint256 expectedAmountOutputMax = 1e18;

        // Init params for the strategy
        LibStrategyDeployment.StrategyDeployment memory strategy = LibStrategyDeployment.StrategyDeployment(
            getEncodedBlueToRedRoute(),
            getEncodedRedToBlueRoute(),
            0,
            0,
            5e17,
            1e18,
            expectedRatio,
            expectedAmountOutputMax,
            "test/strategies/base-order.rain",
            "base-order-simulations",
            "./lib/rain.orderbook",
            "./lib/rain.orderbook/Cargo.toml",
            inputVaults,
            outputVaults
        );

        // Assert strategy calculations by executing order by calling 'arb' function
        // on the OrderBookV3ArbOrderTaker contract.
        checkStrategyCalculationsArbOrder(strategy);
    }

    // Inheriting contract defines the route for the strategy.
    function getEncodedRedToBlueRoute() internal pure returns (bytes memory) {
        bytes memory RED_TO_BLUE_ROUTE = hex"02222789334D44bB5b2364939477E15A6c981Ca16501ffff00822abC8C238cFe43344C5db8629ed7e626fda08c01F97A86C2Cb3e42f89AC5f5AA020E5c3505015a88000bb8";

        return abi.encode(RED_TO_BLUE_ROUTE);
    }

    // Inheriting contract defines the route for the strategy.
    function getEncodedBlueToRedRoute() internal pure returns (bytes memory) {
        bytes memory BLUE_TO_RED_ROUTE = hex"026d3AbB80c3CBAe0f60ba274F36137298D8571Fbe01ffff00822abC8C238cFe43344C5db8629ed7e626fda08c00F97A86C2Cb3e42f89AC5f5AA020E5c3505015a88000bb8";

        return abi.encode(BLUE_TO_RED_ROUTE);
    }
}