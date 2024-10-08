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
    uint256 constant FORK_BLOCK_NUMBER = 18981552;

    // Inheriting contract defines fork selection.
    function selectFork() internal {
        uint256 fork = vm.createFork(vm.envString("RPC_URL_BASE"));
        vm.selectFork(fork);
        vm.rollFork(FORK_BLOCK_NUMBER);
    }

    // Inheriting contract initializes the contracts on the fork.
    function setUp() public {
        selectFork();
        
        iArbInstance = IOrderBookV4ArbOrderTakerV2(0x40D44abeC30288BFcd400200BA65FBD05daA5321);
        iRouteProcessor = IRouteProcessor(address(0x0389879e0156033202C44BF784ac18fC02edeE4f));

        EXTERNAL_EOA = address(0x654FEf5Fb8A1C91ad47Ba192F7AA81dd3C821427);
        APPROVED_EOA = address(0x669845c29D9B1A64FFF66a55aA13EB4adB889a88);
        ORDER_OWNER = address(0x5e01e44aE1969e16B9160d903B6F2aa991a37B21);

        bytes memory orderBook = LibComposeOrders.getOrderOrderBook(
            vm,
            "test/strategies/base-order.rain",
            "test/strategies/settings.yml",
            "buy-order",
            "./lib/rain.orderbook",
            "./lib/rain.orderbook/Cargo.toml"
        );
        iOrderBook = IOrderBookV4(address(uint160(bytes20(orderBook))));
    }
    
    // Inheriting contract tests OrderBook strategy with test suite.
    function testDeployedStrategy() public {
        // Expected calculations context
        uint256 expectedRatio = 0.001e18;
        uint256 expectedAmountOutputMax = 0.0000000000000001e18;

        // Init params for the strategy
        LibStrategyDeployment.StrategyDeploymentV4 memory strategy = LibStrategyDeployment.StrategyDeploymentV4(
            "",
            "",
            0,
            0,
            5e17,
            1e18,
            expectedRatio,
            expectedAmountOutputMax,
            "test/strategies/base-order.rain",
            "test/strategies/settings.yml",
            "",
            "buy-order",
            "./lib/rain.orderbook",
            "./lib/rain.orderbook/Cargo.toml"
        );

        // Assert strategy calculations by executing order by directly calling 'takeOrder' function
        // from the OrderBook contract.
        checkStrategyCalculations(strategy);
    }

    // Inheriting contract tests OrderBook strategy with test suite.
    function testDeployedStrategyArbOrder() public {
        // Expected calculations context
        uint256 expectedRatio = 0.001e18;
        uint256 expectedAmountOutputMax = 0.0000000000000001e18;

        // Init params for the strategy
        LibStrategyDeployment.StrategyDeploymentV4 memory strategy = LibStrategyDeployment.StrategyDeploymentV4(
            getEncodedBlueToRedRoute(),
            getEncodedRedToBlueRoute(),
            0,
            0,
            1e1,
            10e18,
            expectedRatio,
            expectedAmountOutputMax,
            "test/strategies/base-order.rain",
            "test/strategies/settings.yml",
            "",
            "buy-order",
            "./lib/rain.orderbook",
            "./lib/rain.orderbook/Cargo.toml"
        );

        // Assert strategy calculations by executing order by calling 'arb' function
        // on the OrderBookV3ArbOrderTaker contract.
        OrderV3 memory order = addOrderDepositOutputTokens(strategy);

        {
            vm.recordLogs();

            // `arb()` called
            takeArbOrder(order, strategy.takerRoute, strategy.inputTokenIndex, strategy.outputTokenIndex, new SignedContextV1[](0));

            Vm.Log[] memory entries = vm.getRecordedLogs();
            (uint256 strategyAmount, uint256 strategyRatio) = getCalculationContext(entries);

            assertEq(strategyRatio, strategy.expectedRatio);
            assertEq(strategyAmount, strategy.expectedAmount);
        }
    }

    // Inheriting contract defines the route for the strategy.
    function getEncodedRedToBlueRoute() internal pure returns (bytes memory) {
        bytes memory RED_TO_BLUE_ROUTE = hex"02222789334D44bB5b2364939477E15A6c981Ca16501ffff00822abC8C238cFe43344C5db8629ed7e626fda08c0140D44abeC30288BFcd400200BA65FBD05daA5321";

        return abi.encode(RED_TO_BLUE_ROUTE);
    }

    // Inheriting contract defines the route for the strategy.
    function getEncodedBlueToRedRoute() internal pure returns (bytes memory) {
        bytes memory BLUE_TO_RED_ROUTE = hex"026d3AbB80c3CBAe0f60ba274F36137298D8571Fbe01ffff00822abC8C238cFe43344C5db8629ed7e626fda08c0040D44abeC30288BFcd400200BA65FBD05daA5321";

        return abi.encode(BLUE_TO_RED_ROUTE);
    }
}