// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import "src/StrategyTests.sol";

/// @title DeployedStrategyTest
/// @notice The contract inherits StrategyTests.sol.
/// DISP and OrderBook contracts need to be intiliazed as part of the setup for
/// running the tests available in StrategyTests.sol.
/// This is how the inheriting repo that has the test suite as a dependency is expected
/// to initialize the suite for a particular fork.
contract DeployedStrategyTest is StrategyTests {
    // Inheriting contract defines the fork block number.
    uint256 constant FORK_BLOCK_NUMBER = 199525152;

    // Inheriting contract defines fork selection.
    function selectFork() internal {
        uint256 fork = vm.createFork(vm.envString("RPC_URL_ARBITRUM"));
        vm.selectFork(fork);
        vm.rollFork(FORK_BLOCK_NUMBER);
    }

    // Inheriting contract initializes the contracts on the fork.
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

    // Inheriting contract tests OrderBook strategy with test suite.
    function testDeployedStrategy() public {
        // Input vaults
        IO[] memory inputVaults = new IO[](1);
        IO memory inputVault = IO(address(0x6d3AbB80c3CBAe0f60ba274F36137298D8571Fbe), 18, 1);
        inputVaults[0] = inputVault;

        // Output vaults
        IO[] memory outputVaults = new IO[](1);
        IO memory outputVault = IO(address(0x667f41fF7D9c06D2dd18511b32041fC6570Dc468), 18, 1);
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
            "test/strategies/arbitrum-order.rain",
            "arbitrum-order-simulations",
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
        // https://arbiscan.io/address/0x6d3AbB80c3CBAe0f60ba274F36137298D8571Fbe#code
        address RED_TOKEN = address(0x6d3AbB80c3CBAe0f60ba274F36137298D8571Fbe);

        // https://arbiscan.io/address/0x667f41fF7D9c06D2dd18511b32041fC6570Dc468#code
        address BLUE_TOKEN = address(0x667f41fF7D9c06D2dd18511b32041fC6570Dc468);

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
            getEncodedBlueToRedRoute(address(ARB_INSTANCE)),
            getEncodedRedToBlueRoute(address(ARB_INSTANCE)),
            0,
            0,
            5e17,
            1e18,
            expectedRatio,
            expectedAmountOutputMax,
            "test/strategies/arbitrum-order.rain",
            "arbitrum-order-simulations",
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
    function getEncodedRedToBlueRoute(address toAddress) internal pure returns (bytes memory) {
        bytes memory RED_TO_BLUE_ROUTE_PRELUDE =
        // process user erc20
            hex"02"
            // start token red
            hex"6d3AbB80c3CBAe0f60ba274F36137298D8571Fbe"
            // loop iterations
            hex"01"
            // share
            hex"ffff"
            // swap uni v2
            hex"00"
            // pool red/blue
            hex"96ef2820731E4bd25c0E1809a2C62B18dAa90794"
            // direction
            hex"00";

        return abi.encode(bytes.concat(RED_TO_BLUE_ROUTE_PRELUDE, abi.encodePacked(address(toAddress))));
    }

    // Inheriting contract defines the route for the strategy.
    function getEncodedBlueToRedRoute(address toAddress) internal pure returns (bytes memory) {
        bytes memory BLUE_TO_RED_ROUTE_PRELUDE =
        // process user erc20
            hex"02"
            // start token red
            hex"667f41fF7D9c06D2dd18511b32041fC6570Dc468"
            // loop iterations
            hex"01"
            // share
            hex"ffff"
            // swap uni v2
            hex"00"
            // pool red/blue
            hex"96ef2820731E4bd25c0E1809a2C62B18dAa90794"
            // direction
            hex"01";

        return abi.encode(bytes.concat(BLUE_TO_RED_ROUTE_PRELUDE, abi.encodePacked(address(toAddress))));
    }
}
