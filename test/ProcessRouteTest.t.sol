// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;
import {Vm} from "forge-std/Vm.sol";
import {Test, console2, stdError} from "forge-std/Test.sol";
import "src/lib/LibProcessStream.sol";

contract ProcessRouteTest is Test{

    function testProcessUniv3Route() public {

        bytes memory uniV3Stream = hex"02e20b9e246db5a0d21bf9209e4858bc9a3ff7a03401ffff00bd80923830b1b122dce0c446b704621458329f1d0009bd2a33c47746ff03b86bce4e885d03c74a8e8c0182af49447d8a07e3bd95bd0d56f35241523fbab101ffff01c31e54c7a869b9fcbecc14363cf510d1c41fa44301fc72038796bd1578c1f578487802ac15bd710ed2";
    
        LibProcessStream.processRoute(uniV3Stream);
    
    }

    function testProcessUniv2Route() public {
        bytes memory uniV2Stream = hex"02e9e7CEA3DedcA5984780Bafc599bD69ADd087D5601ffff004A2Dbaa979A3F4Cfb8004eA5743fAF159DD2665A00669845c29D9B1A64FFF66a55aA13EB4adB889a88";

        LibProcessStream.processRoute(uniV2Stream);
    } 

   
}