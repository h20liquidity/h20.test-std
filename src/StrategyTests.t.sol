// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;
import "src/abstract/OrderBookStrategyTest.sol";
import {LibStrategyDeployment} from "src/lib/LibStrategyDeployment.sol";
import {LibComposeOrders} from "src/lib/LibComposeOrder.sol";

contract StrategyTests is OrderBookStrategyTest { 
    
    function checkStrategyCalculations(LibStrategyDeployment.StrategyDeployment memory strategy) internal {
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
            depositTokens(ORDER_OWNER, outputToken, outputTokenVaultId, 1e30);
        }
        OrderV2 memory order;
        {
            (bytes memory bytecode, uint256[] memory constants) = PARSER.parse(
                LibComposeOrders.getComposedOrder(vm, strategy.strategyFile, strategy.strategyScenario)
            );
            order = placeOrder(ORDER_OWNER, bytecode, constants, strategy.inputVaults, strategy.outputVaults);
        }
        {
            vm.recordLogs();
            takeExternalOrder(order,strategy.inputTokenIndex,strategy.outputTokenIndex);

            Vm.Log[] memory entries = vm.getRecordedLogs();
            (uint256 strategyAmount,uint256 strategyRatio) = getCalculationContext(entries);

            assertEq(strategyRatio, strategy.expectedRatio);
            assertEq(strategyAmount, strategy.expectedAmount);
        } 
    }   
}