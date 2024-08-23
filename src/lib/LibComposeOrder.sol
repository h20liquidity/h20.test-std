// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import {Vm} from "forge-std/Vm.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

library LibComposeOrders {
    using Strings for address;
    using Strings for uint256;

    function getComposedOrder(
        Vm vm,
        string memory filePath,
        string memory settingsPath,
        string memory scenario,
        string memory buildPath,
        string memory manifestPath
    ) internal returns (bytes memory composedOrder) {
        string[] memory ffi = new string[](18);
        ffi[0] = "nix";
        ffi[1] = "develop";
        ffi[2] = buildPath;
        ffi[3] = "--command";
        ffi[4] = "cargo";
        ffi[5] = "run";
        ffi[6] = "--manifest-path";
        ffi[7] = manifestPath;
        ffi[8] = "--package";
        ffi[9] = "rain_orderbook_cli";
        ffi[10] = "order";
        ffi[11] = "compose";
        ffi[12] = "-f";
        ffi[13] = filePath;
        ffi[14] = "-c";
        ffi[15] = settingsPath;
        ffi[16] = "-s";
        ffi[17] = scenario;

        composedOrder = vm.ffi(ffi);
    }

    function getComposedPostAddOrder(
        Vm vm,
        string memory filePath,
        string memory settingsPath,
        string memory scenario,
        string memory buildPath,
        string memory manifestPath
    ) internal returns (bytes memory composedSource) {
        string[] memory ffi = new string[](19);
        ffi[0] = "nix";
        ffi[1] = "develop";
        ffi[2] = buildPath;
        ffi[3] = "--command";
        ffi[4] = "cargo";
        ffi[5] = "run";
        ffi[6] = "--manifest-path";
        ffi[7] = manifestPath;
        ffi[8] = "--package";
        ffi[9] = "rain_orderbook_cli";
        ffi[10] = "order";
        ffi[11] = "compose";
        ffi[12] = "-f";
        ffi[13] = filePath;
        ffi[14] = "-c";
        ffi[15] = settingsPath;
        ffi[16] = "-s";
        ffi[17] = scenario;
        ffi[18] = "-p";

        composedSource = vm.ffi(ffi);
    }

    function getOrderCalldata(
        Vm vm,
        string memory filePath,
        string memory settingsPath,
        string memory deploymentKey,
        string memory buildPath,
        string memory manifestPath
    ) internal returns (bytes memory composedOrder) {
        string[] memory ffi = new string[](20);
        ffi[0] = "nix";
        ffi[1] = "develop";
        ffi[2] = buildPath;
        ffi[3] = "--command";
        ffi[4] = "cargo";
        ffi[5] = "run";
        ffi[6] = "--manifest-path";
        ffi[7] = manifestPath;
        ffi[8] = "--package";
        ffi[9] = "rain_orderbook_cli";
        ffi[10] = "order";
        ffi[11] = "calldata";
        ffi[12] = "-f";
        ffi[13] = filePath;
        ffi[14] = "-c";
        ffi[15] = settingsPath;
        ffi[16] = "-e";
        ffi[17] = deploymentKey;
        ffi[18] = "-o";
        ffi[19] = "hex";

        composedOrder = vm.ffi(ffi);
    }

    function getOrderOrderBook(
        Vm vm,
        string memory filePath,
        string memory settingsPath,
        string memory deploymentKey,
        string memory buildPath,
        string memory manifestPath
    ) internal returns (bytes memory composedSource) {
        string[] memory ffi = new string[](20);
        ffi[0] = "nix";
        ffi[1] = "develop";
        ffi[2] = buildPath;
        ffi[3] = "--command";
        ffi[4] = "cargo";
        ffi[5] = "run";
        ffi[6] = "--manifest-path";
        ffi[7] = manifestPath;
        ffi[8] = "--package";
        ffi[9] = "rain_orderbook_cli";
        ffi[10] = "order";
        ffi[11] = "ob-addr";
        ffi[12] = "-f";
        ffi[13] = filePath;
        ffi[14] = "-c";
        ffi[15] = settingsPath;
        ffi[16] = "-e";
        ffi[17] = deploymentKey;
        ffi[18] = "-o";
        ffi[19] = "hex";

        composedSource = vm.ffi(ffi);
    }
}
