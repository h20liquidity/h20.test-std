// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import {Vm} from "forge-std/Vm.sol";
import {IO} from "rain.orderbook.interface/interface/deprecated/v3/IOrderBookV3.sol";
import {SignedContextV1} from "rain.interpreter.interface/interface/deprecated/IInterpreterCallerV2.sol";

library LibStrategyDeployment {
    struct StrategyDeploymentV4 {
        bytes makerRoute;
        bytes takerRoute;
        uint256 inputTokenIndex;
        uint256 outputTokenIndex;
        uint256 makerAmount;
        uint256 takerAmount;
        uint256 expectedRatio;
        uint256 expectedAmount;
        string strategyFile;
        string settingsFile;
        string strategyScenario;
        string deploymentKey;
        string buildPath;
        string manifestPath;
    }
}
