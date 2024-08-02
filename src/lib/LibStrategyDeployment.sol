// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import {Vm} from "forge-std/Vm.sol";
import {IO} from "rain.orderbook.interface/interface/IOrderBookV3.sol";
import {ActionV1} from "rain.orderbook.interface/interface/unstable/IOrderBookV4.sol";

library LibStrategyDeployment {
    struct StrategyDeploymentV3 {
        bytes makerRoute;
        bytes takerRoute;
        uint256 inputTokenIndex;
        uint256 outputTokenIndex;
        uint256 makerAmount;
        uint256 takerAmount;
        uint256 expectedRatio;
        uint256 expectedAmount;
        string strategyFile;
        string strategyScenario;
        string buildPath;
        string manifestPath;
        IO[] inputVaults;
        IO[] outputVaults;
        ActionV1[] postActions;
    }
}
