// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;
import {Vm} from "forge-std/Vm.sol";
import {Test, console2, stdError} from "forge-std/Test.sol";
import "src/InputStream.sol"; 

contract TestStream is Test{

    address constant NATIVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant IMPOSSIBLE_POOL_ADDRESS = 0x0000000000000000000000000000000000000001;

    using InputStream for uint256; 

    function testStream() public {

        bytes memory bscEncodedStream = hex"0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004202e9e7cea3dedca5984780bafc599bd69add087d5601ffff004a2dbaa979a3f4cfb8004ea5743faf159dd2665a00669845c29d9b1a64fff66a55aa13eb4adb889a88000000000000000000000000000000000000000000000000000000000000";

        uint256 stream = InputStream.createStream(bscEncodedStream);
        while (stream.isNotEmpty()) {
            uint8 commandCode = stream.readUint8(); 
            console2.log(commandCode);
            if (commandCode == 1) processMyERC20(stream);
            else if (commandCode == 2) processUserERC20(stream);
            else if (commandCode == 3) processNative(stream);
            else if (commandCode == 4) processOnePool(stream);
            else revert('RouteProcessor: Unknown command code');
        }

    }

    function processMyERC20(uint256 stream) internal {
        address token = stream.readAddress();
        console2.log("my token : %s", token);
    }

    function processUserERC20(uint256 stream) private {
        address token = stream.readAddress();
        console2.log("user token : %s", token);
    }
    function processNative(uint256 stream) private {
        console2.log("Native Token : ", NATIVE_ADDRESS);
    }
    function processOnePool(uint256 stream) private {
        address token = stream.readAddress();
        console2.log("one pool : ", token);
    }
}