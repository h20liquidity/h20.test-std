// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {Vm} from "forge-std/Vm.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {InputStream} from "sushiswap/protocols/route-processor/contracts/InputStream.sol";
import "forge-std/console2.sol";

library LibProcessStream {
    using Strings for address;
    using Strings for uint256;

    using InputStream for uint256;

    address constant NATIVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant IMPOSSIBLE_POOL_ADDRESS = 0x0000000000000000000000000000000000000001;

    function processRoute(bytes memory route) internal pure {
        uint256 stream = InputStream.createStream(route);
        while (stream.isNotEmpty()) {
            uint8 commandCode = stream.readUint8();
            if (commandCode == 1) processMyERC20(stream);
            else if (commandCode == 2) processUserERC20(stream);
            else if (commandCode == 3) processNative(stream);
            else if (commandCode == 4) processOnePool(stream);
        }
    }

    function processMyERC20(uint256 stream) internal pure {
        address token = stream.readAddress();
        console2.log("processMyERC20() token : %s", token);
        distributeAndSwap(stream);
    }

    function processUserERC20(uint256 stream) internal pure {
        address token = stream.readAddress();
        console2.log("processUserERC20() token : %s", token);
        distributeAndSwap(stream);
    }

    function processNative(uint256 stream) internal pure {
        console2.log("processNative() token : ", NATIVE_ADDRESS);
        distributeAndSwap(stream);
    }

    function processOnePool(uint256 stream) internal pure {
        address token = stream.readAddress();
        console2.log("processOnePool() token : ", token);
        distributeAndSwap(stream);
    }

    function distributeAndSwap(uint256 stream) internal pure {
        uint8 num = stream.readUint8();
        unchecked {
            for (uint256 i = 0; i < num; ++i) {
                stream.readUint16();
                swap(stream);
            }
        }
    }

    function swap(uint256 stream) internal pure {
        uint8 poolType = stream.readUint8();
        if (poolType == 0) swapUniV2(stream);
        else if (poolType == 1) swapUniV3(stream);
        else if (poolType == 2) wrapNative(stream);
    }

    function swapUniV2(uint256 stream) internal pure {
        address pool = stream.readAddress();
        uint8 direction = stream.readUint8();
        address to = stream.readAddress();

        console2.log("swapUniV2--------------");
        console2.log("pool : ", pool);
        console2.log("direction : ", direction);
        console2.log("to : ", to);
    }

    function swapUniV3(uint256 stream) internal pure {
        address pool = stream.readAddress();
        bool zeroForOne = stream.readUint8() > 0;
        address recipient = stream.readAddress();

        console2.log("swapUniV3--------------");
        console2.log("pool : ", pool);
        console2.log("zeroForOne : ", zeroForOne);
        console2.log("recipient : ", recipient);
    }

    function wrapNative(uint256 stream) internal pure {
        uint8 directionAndFake = stream.readUint8();
        address to = stream.readAddress();

        console2.log("wrapNative--------------");
        console2.log("directionAndFake : ", directionAndFake);
        console2.log("to : ", to);
    }
}
