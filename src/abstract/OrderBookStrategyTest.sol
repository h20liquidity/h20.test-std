// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import {Vm} from "forge-std/Vm.sol";
import {Test, console2, stdError} from "forge-std/Test.sol";
import {IParserV2} from "rain.interpreter.interface/interface/IParserV2.sol";
import {IExpressionDeployerV3} from "rain.interpreter.interface/interface/deprecated/IExpressionDeployerV3.sol";
import {IInterpreterV3} from "rain.interpreter.interface/interface/IInterpreterV3.sol";
import {IInterpreterStoreV2} from "rain.interpreter.interface/interface/IInterpreterStoreV2.sol";
import {SourceIndexV2} from "rain.interpreter.interface/interface/deprecated/IInterpreterV2.sol";
import {EvaluableConfigV3, SignedContextV1} from "rain.interpreter.interface/interface/deprecated/IInterpreterCallerV2.sol";
import {
    IOrderBookV3,
    IO
} from "rain.orderbook.interface/interface/deprecated/v3/IOrderBookV3.sol";
import {
    IOrderBookV4,
    OrderV3,
    OrderConfigV3,
    TakeOrderConfigV3,
    TakeOrdersConfigV3,
    TaskV1,
    EvaluableV3
}from "rain.orderbook.interface/interface/IOrderBookV4.sol";
import {IOrderBookV4ArbOrderTakerV2} from "rain.orderbook.interface/interface/unstable/IOrderBookV4ArbOrderTakerV2.sol";
import {SafeERC20, IERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {IRouteProcessor} from "src/interface/IRouteProcessor.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

abstract contract OrderBookStrategyTest is Test {
    using SafeERC20 for IERC20;
    using Strings for address;

    uint256 constant CONTEXT_VAULT_IO_ROWS = 5;
    address public EXTERNAL_EOA;
    address public APPROVED_EOA;
    address public ORDER_OWNER;

    IParserV2 public iParser;
    IExpressionDeployerV3 public iExpressionDeployer;
    IInterpreterV3 public iInterpreter;
    IInterpreterStoreV2 public iStore;
    IOrderBookV4 public iOrderBook;
    IOrderBookV4ArbOrderTakerV2 public iArbInstance;
    IRouteProcessor public iRouteProcessor; 

    function depositTokens(address owner, address token, uint256 vaultId, uint256 amount, TaskV1[] memory actionV1) internal {
        vm.startPrank(owner);
        IERC20(token).safeApprove(address(iOrderBook), amount);
        iOrderBook.deposit2(address(token), vaultId, amount, actionV1);
        vm.stopPrank();
    }

    function withdrawTokens(address owner, address token, uint256 vaultId, uint256 amount, TaskV1[] memory actionV1) internal {
        vm.startPrank(owner);
        iOrderBook.withdraw2(address(token), vaultId, amount, actionV1);
        vm.stopPrank();
    }

    function getVaultBalance(address owner, address token, uint256 vaultId) internal view returns (uint256) {
        return iOrderBook.vaultBalance(owner, token, vaultId);
    }

    function placeOrder(
        address orderOwner,
        bytes memory bytecode,
        IO[] memory inputs,
        IO[] memory outputs,
        TaskV1[] memory actionV1
    ) internal returns (OrderV3 memory order) { 

        EvaluableV3 memory evaluableConfig = EvaluableV3(iInterpreter, iStore ,bytecode);
        OrderConfigV3 memory orderV3Config = OrderConfigV3(evaluableConfig, inputs, outputs, "", "", "");

        vm.startPrank(orderOwner);
        vm.recordLogs();
        (bool stateChanged) = iOrderBook.addOrder2(orderV3Config,actionV1);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        (,, order) = abi.decode(entries[0].data, (address, bytes32, OrderV3));
        assertEq(order.owner, orderOwner);
        assertEq(stateChanged, true);
    }

    function takeArbOrder(
        OrderV3 memory order,
        bytes memory route,
        uint256 inputIOIndex,
        uint256 outputIOIndex,
        SignedContextV1[] memory signedContext
    )
        internal
    {
        vm.startPrank(APPROVED_EOA);

        EvaluableV3 memory arbEvaluableV3Config = EvaluableV3(
            IInterpreterV3(0x0000000000000000000000000000000000000000),
            IInterpreterStoreV2(0x0000000000000000000000000000000000000000),
            ""
        );
        TakeOrderConfigV3[] memory innerConfigs = new TakeOrderConfigV3[](1); 
        innerConfigs[0] = TakeOrderConfigV3(order, inputIOIndex, outputIOIndex, signedContext); 

        TakeOrdersConfigV3 memory takeOrdersConfig =
            TakeOrdersConfigV3(0, type(uint256).max, type(uint256).max, innerConfigs, route);
        iArbInstance.arb3(iOrderBook, takeOrdersConfig, TaskV1(arbEvaluableV3Config, new SignedContextV1[](0)));
        vm.stopPrank();
    }

    function takeExternalOrder(
        OrderV3 memory order,
        uint256 inputIOIndex,
        uint256 outputIOIndex,
        SignedContextV1[] memory signedContext
    ) internal {
        vm.startPrank(APPROVED_EOA);

        address inputTokenAddress = order.validInputs[inputIOIndex].token;
        IERC20(inputTokenAddress).safeApprove(address(iOrderBook), type(uint256).max);

        TakeOrderConfigV3[] memory innerConfigs = new TakeOrderConfigV3[](1);

        innerConfigs[0] = TakeOrderConfigV3(order, inputIOIndex, outputIOIndex, signedContext);
        TakeOrdersConfigV3 memory takeOrdersConfig =
            TakeOrdersConfigV3(0, type(uint256).max, type(uint256).max, innerConfigs, "");

        iOrderBook.takeOrders2(takeOrdersConfig);
        vm.stopPrank();
    }

    function signContext(uint256 privateKey, uint256[] memory context) public pure returns (SignedContextV1 memory) {
        SignedContextV1 memory signedContext;

        // Store the signer's address in the struct
        signedContext.signer = vm.addr(privateKey);
        signedContext.context = context; // copy the context data into the struct

        // Create a digest of the context data
        bytes32 contextHash = keccak256(abi.encodePacked(context));
        bytes32 digest = ECDSA.toEthSignedMessageHash(contextHash);

        // Create the signature using the cheatcode 'sign'
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        signedContext.signature = abi.encodePacked(r, s, v);

        return signedContext;
    }

    function moveExternalPrice(address inputToken, address outputToken, uint256 amountIn, bytes memory encodedRoute)
        public
    {
        vm.startPrank(EXTERNAL_EOA);
        IERC20(inputToken).safeApprove(address(iRouteProcessor), amountIn);
        bytes memory decodedRoute = abi.decode(encodedRoute, (bytes));
        iRouteProcessor.processRoute(inputToken, amountIn, outputToken, 0, EXTERNAL_EOA, decodedRoute);
        vm.stopPrank();
    }

    function getContextInputOutput(Vm.Log[] memory entries)
        public
        pure
        returns (uint256 input, uint256 output, uint256 ratio)
    {
        for (uint256 j = 0; j < entries.length; j++) {
            if (entries[j].topics[0] == keccak256("Context(address,uint256[][])")) {
                (, uint256[][] memory context) = abi.decode(entries[j].data, (address, uint256[][]));
                ratio = context[2][1];
                input = context[3][4];
                output = context[4][4];
            }
        }
    }

    function getCalculationContext(Vm.Log[] memory entries) public pure returns (uint256 amount, uint256 ratio) {
        for (uint256 j = 0; j < entries.length; j++) {
            if (entries[j].topics[0] == keccak256("Context(address,uint256[][])")) {
                (, uint256[][] memory context) = abi.decode(entries[j].data, (address, uint256[][]));
                amount = context[2][0];
                ratio = context[2][1];
            }
        }
    }

    function giveTestAccountsTokens(address token, address from, address to, uint256 amount) internal {
        vm.startPrank(from);
        IERC20(token).safeTransfer(to, amount);
        vm.stopPrank();
    }

    function getOrderContext(uint256 orderHash) internal pure returns (uint256[][] memory context) {
        context = new uint256[][](5);
        {
            {
                uint256[] memory baseContext = new uint256[](2);
                context[0] = baseContext;
            }
            {
                uint256[] memory callingContext = new uint256[](3);
                // order hash
                callingContext[0] = orderHash;
                context[1] = callingContext;
            }
            {
                uint256[] memory calculationsContext = new uint256[](2);
                context[2] = calculationsContext;
            }
            {
                uint256[] memory inputsContext = new uint256[](CONTEXT_VAULT_IO_ROWS);
                context[3] = inputsContext;
            }
            {
                uint256[] memory outputsContext = new uint256[](CONTEXT_VAULT_IO_ROWS);
                context[4] = outputsContext;
            }
        }
    }
}
