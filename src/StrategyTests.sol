// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import "src/abstract/OrderBookStrategyTest.sol";
import {LibEncodedDispatch} from "rain.interpreter.interface/lib/deprecated/caller/LibEncodedDispatch.sol";
import {TaskV1} from "rain.orderbook.interface/interface/IOrderBookV4.sol";
import {StateNamespace, LibNamespace, FullyQualifiedNamespace} from "rain.interpreter.interface/lib/ns/LibNamespace.sol"; 
import {LibStrategyDeployment} from "src/lib/LibStrategyDeployment.sol";
import {LibComposeOrders} from "src/lib/LibComposeOrder.sol";

contract StrategyTests is OrderBookStrategyTest {
    // Function to add OrderBook order and deposit tokens.
    // Input and Output tokens are extracted from `inputVaults` and `outputVaults`,
    // indexed by `inputTokenIndex` and `outputTokenIndex`.
    function addOrderDepositOutputTokens(LibStrategyDeployment.StrategyDeploymentV4 memory strategy)
        internal
        returns (OrderV3 memory order)
    {
        bytes memory addOrderCallData;
        {
            addOrderCallData = LibComposeOrders.getOrderCalldata(
                vm, strategy.strategyFile, strategy.settingsFile, strategy.deploymentKey, strategy.buildPath, strategy.manifestPath
            );
        }

        vm.startPrank(ORDER_OWNER);
        vm.recordLogs();
        (, bytes memory result) = address(iOrderBook).call(addOrderCallData);
        (bool stateChanged) = abi.decode(result, (bool));
        assertEq(stateChanged, true);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        (,, order) = abi.decode(entries[0].data, (address, bytes32, OrderV3));
        assertEq(order.owner, ORDER_OWNER);
           
        address inputToken;
        address outputToken;
        uint256 inputTokenVaultId;
        uint256 outputTokenVaultId;

        {
            inputToken = order.validInputs[strategy.inputTokenIndex].token;
            outputToken = order.validOutputs[strategy.outputTokenIndex].token;
            inputTokenVaultId = order.validInputs[strategy.inputTokenIndex].vaultId;
            outputTokenVaultId = order.validOutputs[strategy.outputTokenIndex].vaultId;
            deal(address(inputToken), EXTERNAL_EOA, 1e30);
            deal(address(outputToken), EXTERNAL_EOA, 1e30);
            deal(address(inputToken), APPROVED_EOA, 1e30);
            deal(address(outputToken), APPROVED_EOA, 1e30);
            deal(address(inputToken), ORDER_OWNER, 1e30);
            deal(address(outputToken), ORDER_OWNER, 1e30);
        }
        {
            depositTokens(ORDER_OWNER, outputToken, outputTokenVaultId, strategy.takerAmount, new TaskV1[](0));
        }
    }

    // Function to assert OrderBook calculations context by calling 'takeOrders' function
    // directly from the OrderBook contract.
    function checkStrategyCalculations(LibStrategyDeployment.StrategyDeploymentV4 memory strategy) internal {
        OrderV3 memory order = addOrderDepositOutputTokens(strategy);
        {
            vm.recordLogs();

            // `takeOrders()` called
            takeExternalOrder(order, strategy.inputTokenIndex, strategy.outputTokenIndex, new SignedContextV1[](0));

            Vm.Log[] memory entries = vm.getRecordedLogs();
            (uint256 strategyAmount, uint256 strategyRatio) = getCalculationContext(entries);

            assertEq(strategyRatio, strategy.expectedRatio);
            assertEq(strategyAmount, strategy.expectedAmount);
        }
    }

    // Function to assert OrderBook calculations context by calling 'arb' function
    // from the OrderBookV3ArbOrderTaker contract.
    function checkStrategyCalculationsArbOrder(LibStrategyDeployment.StrategyDeploymentV4 memory strategy) internal {
        OrderV3 memory order = addOrderDepositOutputTokens(strategy);

        // Move external pool price in opposite direction that of the order
        {
            moveExternalPrice(
                order.validInputs[strategy.inputTokenIndex].token,
                order.validOutputs[strategy.outputTokenIndex].token,
                strategy.makerAmount,
                strategy.makerRoute
            );
        }
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

    function evalExpression(
        LibStrategyDeployment.StrategyDeploymentV4 memory strategy,
        FullyQualifiedNamespace namespace,
        uint256[][] memory context,
        uint256[] memory inputs,
        uint256 sourceIndex

    ) internal {
        bytes memory bytecode = iParser.parse2(
            LibComposeOrders.getComposedOrder(
                vm, strategy.strategyFile, strategy.settingsFile, strategy.strategyScenario, strategy.buildPath, strategy.manifestPath
            )
        );

        (uint256[] memory stack,) = iInterpreter.eval3(
            iStore,
            namespace,
            bytecode,
            SourceIndexV2.wrap(sourceIndex),
            context,
            inputs
        );

        for(uint256  i = 0 ; i < stack.length; i++){
            console2.log("stack[%s] : %s",i, stack[i]);
        }
    }

    function toAddress(bytes memory b) internal pure returns (address) {
        require(b.length >= 20, "Insufficient length");
        address addr;
        assembly {
            addr := mload(add(b, 0x14)) // Load 20 bytes starting from the 20th byte
        }
        return addr;
    }

    function getBounty(Vm.Log[] memory entries)
        public
        view
        returns (uint256 inputTokenBounty, uint256 outputTokenBounty)
    {   
        // Array of length 2 to store the input and ouput token bounties.
        uint256[] memory bounties = new uint256[](2);

        // Count the number of bounties found.
        uint256 bountyCount = 0;
        for (uint256 j = 0; j < entries.length; j++) { 
            if (
                entries[j].topics[0] == keccak256("Transfer(address,address,uint256)") && 
                address(iArbInstance) == abi.decode(abi.encodePacked(entries[j].topics[1]), (address)) &&
                address(APPROVED_EOA) == abi.decode(abi.encodePacked(entries[j].topics[2]), (address))
            ) {
                bounties[bountyCount] = abi.decode(entries[j].data, (uint256));
                bountyCount++;
            }   
        }
        return (bounties[0], bounties[1]);
    }
}
