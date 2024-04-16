// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {Vm} from "forge-std/Vm.sol";
import {Test, console2, stdError} from "forge-std/Test.sol";
import "src/lib/LibProcessStream.sol";

contract ProcessRouteTest is Test {

    function testProcessUniv3Route() public pure {
        bytes memory uniV3Stream =
            hex"02e20b9e246db5a0d21bf9209e4858bc9a3ff7a03401ffff00bd80923830b1b122dce0c446b704621458329f1d0009bd2a33c47746ff03b86bce4e885d03c74a8e8c0182af49447d8a07e3bd95bd0d56f35241523fbab101ffff01c31e54c7a869b9fcbecc14363cf510d1c41fa44301fc72038796bd1578c1f578487802ac15bd710ed2";

        LibProcessStream.ProcessedRoute memory processedRoute = LibProcessStream.processRoute(uniV3Stream);

        // Assert Processed Routes
        assertEq(processedRoute.processedMyERC20.length, 1);
        assertEq(processedRoute.processedUserERC20.length, 1);
        assertEq(processedRoute.processedNative.length, 0);
        assertEq(processedRoute.processedOnePool.length, 0);

        // Assert Processed Route Data
        assertEq(processedRoute.processedMyERC20[0].tokenIn, address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1)); 
        assertEq(processedRoute.processedMyERC20[0].pool, address(0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443));
        assertEq(processedRoute.processedMyERC20[0].to, address(0xfc72038796Bd1578C1f578487802Ac15bd710Ed2));
        assertEq(processedRoute.processedMyERC20[0].direction, 1);

        // Assert Processed Route Data
        assertEq(processedRoute.processedUserERC20[0].tokenIn, address(0xe20B9e246db5a0d21BF9209E4858Bc9A3ff7A034)); 
        assertEq(processedRoute.processedUserERC20[0].pool, address(0xBD80923830B1B122dcE0C446b704621458329F1D));
        assertEq(processedRoute.processedUserERC20[0].to, address(0x09bD2A33c47746fF03b86BCe4E885D03C74a8E8C));
        assertEq(processedRoute.processedUserERC20[0].direction, 0);
    }

    function testProcessUniv2Route() public pure {
        bytes memory uniV2Stream =
            hex"02e9e7CEA3DedcA5984780Bafc599bD69ADd087D5601ffff004A2Dbaa979A3F4Cfb8004eA5743fAF159DD2665A00669845c29D9B1A64FFF66a55aA13EB4adB889a88";

        LibProcessStream.ProcessedRoute memory processedRoute = LibProcessStream.processRoute(uniV2Stream); 

        // Assert Processed Routes
        assertEq(processedRoute.processedMyERC20.length, 0);
        assertEq(processedRoute.processedUserERC20.length, 1);
        assertEq(processedRoute.processedNative.length, 0);
        assertEq(processedRoute.processedOnePool.length, 0);

        // Assert Processed Route Data
        assertEq(processedRoute.processedUserERC20[0].tokenIn, address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56)); 
        assertEq(processedRoute.processedUserERC20[0].pool, address(0x4A2Dbaa979A3F4Cfb8004eA5743fAF159DD2665A));
        assertEq(processedRoute.processedUserERC20[0].to, address(0x669845c29D9B1A64FFF66a55aA13EB4adB889a88));
        assertEq(processedRoute.processedUserERC20[0].direction, 0);
    }

     

    
}
