// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import "src/abstract/OrderBookStrategyTest.sol";
import {LibStrategyDeployment} from "src/lib/LibStrategyDeployment.sol";
import {LibComposeOrders} from "src/lib/LibComposeOrder.sol";

contract StrategyTests is OrderBookStrategyTest {
    // Function to add OrderBook order and deposit tokens.
    // Input and Output tokens are extracted from `inputVaults` and `outputVaults`,
    // indexed by `inputTokenIndex` and `outputTokenIndex`.
    function addOrderDepositOutputTokens(LibStrategyDeployment.StrategyDeployment memory strategy)
        internal
        returns (OrderV2 memory order)
    {
        address inputToken;
        address outputToken;
        uint256 inputTokenVaultId;
        uint256 outputTokenVaultId;

        {
            inputToken = strategy.inputVaults[strategy.inputTokenIndex].token;
            outputToken = strategy.outputVaults[strategy.outputTokenIndex].token;
            inputTokenVaultId = strategy.inputVaults[strategy.inputTokenIndex].vaultId;
            outputTokenVaultId = strategy.outputVaults[strategy.outputTokenIndex].vaultId;
            deal(address(inputToken), EXTERNAL_EOA, 1e30);
            deal(address(outputToken), EXTERNAL_EOA, 1e30);
            deal(address(inputToken), APPROVED_EOA, 1e30);
            deal(address(outputToken), APPROVED_EOA, 1e30);
            deal(address(inputToken), ORDER_OWNER, 1e30);
            deal(address(outputToken), ORDER_OWNER, 1e30);
        }
        {
            depositTokens(ORDER_OWNER, outputToken, outputTokenVaultId, strategy.takerAmount);
        }
        {
            (bytes memory bytecode, uint256[] memory constants) = PARSER.parse(
                LibComposeOrders.getComposedOrder(
                    vm, strategy.strategyFile, strategy.strategyScenario, strategy.buildPath, strategy.manifestPath
                )
            );
            order = placeOrder(ORDER_OWNER, bytecode, constants, strategy.inputVaults, strategy.outputVaults);
        }
    }

    // Function to assert OrderBook calculations context by calling 'takeOrders' function
    // directly from the OrderBook contract.
    function checkStrategyCalculations(LibStrategyDeployment.StrategyDeployment memory strategy) internal {
        OrderV2 memory order = addOrderDepositOutputTokens(strategy);
        {
            vm.recordLogs();

            // `takeOrders()` called
            takeExternalOrder(order, strategy.inputTokenIndex, strategy.outputTokenIndex);

            Vm.Log[] memory entries = vm.getRecordedLogs();
            (uint256 strategyAmount, uint256 strategyRatio) = getCalculationContext(entries);

            assertEq(strategyRatio, strategy.expectedRatio);
            assertEq(strategyAmount, strategy.expectedAmount);
        }
    }

    // Function to assert OrderBook calculations context by calling 'arb' function
    // from the OrderBookV3ArbOrderTaker contract.
    function checkStrategyCalculationsArbOrder(LibStrategyDeployment.StrategyDeployment memory strategy) internal {
        OrderV2 memory order = addOrderDepositOutputTokens(strategy);

        // Move external pool price in opposite direction that of the order
        {
            moveExternalPrice(
                strategy.inputVaults[strategy.inputTokenIndex].token,
                strategy.outputVaults[strategy.outputTokenIndex].token,
                strategy.makerAmount,
                strategy.makerRoute
            );
        }
        {
            vm.recordLogs();

            // `arb()` called
            takeArbOrder(order, strategy.takerRoute, strategy.inputTokenIndex, strategy.outputTokenIndex);

            Vm.Log[] memory entries = vm.getRecordedLogs();
            (uint256 strategyAmount, uint256 strategyRatio) = getCalculationContext(entries);

            assertEq(strategyRatio, strategy.expectedRatio);
            assertEq(strategyAmount, strategy.expectedAmount);
        }
    }
}
