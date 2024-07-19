// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import {Vm} from "forge-std/Vm.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {InputStream} from "lib/sushiswap/protocols/route-processor/contracts/InputStream.sol";
import {IUniswapV2Pair} from "lib/sushiswap/protocols/route-processor/interfaces/IUniswapV2Pair.sol";

import "forge-std/console2.sol";

/// Library to decompile sushi routes
library LibProcessStream {
    using Strings for address;
    using Strings for uint256;

    using InputStream for uint256;

    address constant NATIVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// Struct representing relevant data for a route.
    struct RouteProcessorData{
        address tokenIn;
        address tokenOut;
        address pool;
        address to;
    }

    /// Struct representing processed route data.
    struct ProcessedRoute{
        RouteProcessorData[] processedMyERC20;
        RouteProcessorData[] processedUserERC20;
        RouteProcessorData[] processedNative;
        RouteProcessorData[] processedOnePool;
    }

    /// Process a route stream.
    function processRoute(bytes memory route) internal view returns(ProcessedRoute memory processedRoute){
        uint256 stream = InputStream.createStream(route);        
        while (stream.isNotEmpty()) {
            uint8 commandCode = stream.readUint8();
            if (commandCode == 1){
                processedRoute.processedMyERC20 = processMyERC20(stream);
                logRoute(processedRoute.processedMyERC20);
            }else if (commandCode == 2){
                processedRoute.processedUserERC20 = processUserERC20(stream);
                logRoute(processedRoute.processedUserERC20); 
            }else if (commandCode == 3){
                processedRoute.processedNative = processNative(stream);
                logRoute(processedRoute.processedNative); 
            }else if (commandCode == 4){
                processedRoute.processedOnePool = processOnePool(stream);
                logRoute(processedRoute.processedOnePool); 
            }
            else revert('RouteProcessor: Decompiler unknown command code');
        }
    }

    /// Log the processed route data.
    function logRoute(RouteProcessorData[] memory routeData) internal pure {
        if(routeData.length > 0){
            for(uint256 i = 0 ; i < routeData.length; i++){
                console2.log("----------------------Processed Route----------------------");
                console2.log("TOKEN IN  : ",routeData[i].tokenIn);
                console2.log("TOKEN OUT : ",routeData[i].tokenOut);
                console2.log("POOL      : ",routeData[i].pool);
                console2.log("TO        : ",routeData[i].to);
            }
        }
    }  
    
    function processMyERC20(uint256 stream) internal view returns(RouteProcessorData[] memory){
        address token = stream.readAddress();
        return distributeAndSwap(stream,token);
    }

    function processUserERC20(uint256 stream) internal view returns(RouteProcessorData[] memory){
        address token = stream.readAddress();
        return distributeAndSwap(stream, token);
    }

    function processNative(uint256 stream) internal view returns(RouteProcessorData[] memory){
        return distributeAndSwap(stream, NATIVE_ADDRESS);
    }

    function processOnePool(uint256 stream) internal view returns(RouteProcessorData[] memory processedRoutes){
        address token = stream.readAddress();
        processedRoutes = new RouteProcessorData[](1);
        processedRoutes[0] = swap(stream, token);
    }

    function distributeAndSwap(uint256 stream, address tokenIn) internal view returns(RouteProcessorData[] memory processedRoutes){
        uint8 num = stream.readUint8(); 
        processedRoutes = new RouteProcessorData[](num);
        unchecked {
            for (uint256 i = 0; i < num; ++i) {
                stream.readUint16();
                processedRoutes[i] = swap(stream, tokenIn);
            }
        }
    }

    function swap(uint256 stream, address tokenIn) internal view returns(RouteProcessorData memory routeData){
        uint8 poolType = stream.readUint8();
        if (poolType == 0) routeData = swapUniV2(stream,tokenIn);
        else if (poolType == 1) routeData = swapUniV3(stream,tokenIn);
        else if (poolType == 2) routeData = wrapNative(stream,tokenIn);
        else if (poolType == 5) routeData = swapCurve(stream,tokenIn);
        else revert('RouteProcessor: Unknown pool type');
    }

    function swapUniV2(uint256 stream, address tokenIn) internal view returns(RouteProcessorData memory routeData){
        address pool = stream.readAddress();
        uint8 direction = stream.readUint8() ;
        address to = stream.readAddress();
        uint24 fee = stream.readUint24();
        (fee);
        address tokenOut = direction == 1 ? IUniswapV2Pair(pool).token1() : IUniswapV2Pair(pool).token0(); 
        routeData = RouteProcessorData(tokenIn,tokenOut,pool,to);
    }

    function swapUniV3(uint256 stream, address tokenIn) internal view returns(RouteProcessorData memory routeData){
        address pool = stream.readAddress();
        uint8 direction = stream.readUint8() ;
        address recipient = stream.readAddress();
        address tokenOut = direction == 1 ? IUniswapV2Pair(pool).token1() : IUniswapV2Pair(pool).token0(); 
        routeData = RouteProcessorData(tokenIn,tokenOut,pool,recipient);
    }

    function wrapNative(uint256 stream, address tokenIn) internal pure returns(RouteProcessorData memory routeData){
        uint8 directionAndFake = stream.readUint8();
        (directionAndFake);
        address to = stream.readAddress();
        routeData = RouteProcessorData(tokenIn,tokenIn,NATIVE_ADDRESS,to);
    } 

    function swapCurve(uint256 stream, address tokenIn) internal pure returns(RouteProcessorData memory routeData){
        address pool = stream.readAddress();
        uint8 poolType = stream.readUint8();
        int128 fromIndex = int8(stream.readUint8());
        int128 toIndex = int8(stream.readUint8());
        address to = stream.readAddress();
        address tokenOut = stream.readAddress(); 
        (poolType,fromIndex,toIndex);
        routeData = RouteProcessorData(tokenIn,tokenOut,pool,to);
    } 


}
