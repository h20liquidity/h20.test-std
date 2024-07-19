// SPDX-License-Identifier: CAL
pragma solidity =0.8.25;

import {Vm} from "forge-std/Vm.sol";
import {Test, console2, stdError} from "forge-std/Test.sol";
import "src/lib/LibProcessStream.sol";

contract ProcessRouteTest is Test {

    uint256 constant BASE_FORK_BLOCK_NUMBER = 17300025;
    uint256 constant ETH_FORK_BLOCK_NUMBER = 20341342;

    function testProcessUniv3Route() public {
        
        vm.createSelectFork(vm.envString("RPC_URL_BASE"), BASE_FORK_BLOCK_NUMBER);

        bytes memory uniV3Stream =
            hex"0299b2B1A2aDB02B38222ADcD057783D7e5D1FCC7D01ffff011536EE1506e24e5A36Be99C73136cD82907A902E000389879e0156033202C44BF784ac18fC02edeE4f01833589fCD6eDb6E08f4c7C32D4f71b54bdA0291301ffff01C18F50d6A832f12F6DcAaeEe8D0c87A65B96787E00F97A86C2Cb3e42f89AC5f5AA020E5c3505015a88";

        LibProcessStream.ProcessedRoute memory processedRoute = LibProcessStream.processRoute(uniV3Stream);

        // Assert Processed Routes
        assertEq(processedRoute.processedMyERC20.length, 1);
        assertEq(processedRoute.processedUserERC20.length, 1);
        assertEq(processedRoute.processedNative.length, 0);
        assertEq(processedRoute.processedOnePool.length, 0);

        // Assert Processed Route Data 
        assertEq(processedRoute.processedUserERC20[0].tokenIn, address(0x99b2B1A2aDB02B38222ADcD057783D7e5D1FCC7D));
        assertEq(processedRoute.processedUserERC20[0].tokenOut, address(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913));
        assertEq(processedRoute.processedUserERC20[0].pool, address(0x1536EE1506e24e5A36Be99C73136cD82907A902E));
        assertEq(processedRoute.processedUserERC20[0].to, address(0x0389879e0156033202C44BF784ac18fC02edeE4f));

        // Assert Processed Route Data
        assertEq(processedRoute.processedMyERC20[0].tokenIn, address(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913));
        assertEq(processedRoute.processedMyERC20[0].tokenOut, address(0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb));
        assertEq(processedRoute.processedMyERC20[0].pool, address(0xC18F50d6A832f12F6DcAaeEe8D0c87A65B96787E));
        assertEq(processedRoute.processedMyERC20[0].to, address(0xF97A86C2Cb3e42f89AC5f5AA020E5c3505015a88));
    }

    function testProcessUniv2Route() public {

        vm.createSelectFork(vm.envString("RPC_URL_BASE"), BASE_FORK_BLOCK_NUMBER);

        bytes memory uniV2Stream =
            hex"02222789334D44bB5b2364939477E15A6c981Ca16501ffff00822abC8C238cFe43344C5db8629ed7e626fda08c01F97A86C2Cb3e42f89AC5f5AA020E5c3505015a88000bb8";

        LibProcessStream.ProcessedRoute memory processedRoute = LibProcessStream.processRoute(uniV2Stream);

        // Assert Processed Routes
        assertEq(processedRoute.processedMyERC20.length, 0);
        assertEq(processedRoute.processedUserERC20.length, 1);
        assertEq(processedRoute.processedNative.length, 0);
        assertEq(processedRoute.processedOnePool.length, 0);

        // Assert Processed Route Data
        assertEq(processedRoute.processedUserERC20[0].tokenIn, address(0x222789334D44bB5b2364939477E15A6c981Ca165));
        assertEq(processedRoute.processedUserERC20[0].tokenOut, address(0x6d3AbB80c3CBAe0f60ba274F36137298D8571Fbe));
        assertEq(processedRoute.processedUserERC20[0].pool, address(0x822abC8C238cFe43344C5db8629ed7e626fda08c));
        assertEq(processedRoute.processedUserERC20[0].to, address(0xF97A86C2Cb3e42f89AC5f5AA020E5c3505015a88));
    }

    function testProcessCurveRoute() public {

        vm.createSelectFork(vm.envString("RPC_URL_ETH"), ETH_FORK_BLOCK_NUMBER); 

        bytes memory uniV2Stream =
            hex"026B175474E89094C44Da98b954EedeAC495271d0F02155505bebc44782c7db0a1a60cb6fe97d0b483032ff1c7010001e43ca1Dee3F0fc1e2df73A0745674545F11A59F5A0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48ffff05a5407eae9ba41422680e2e00537571bcc53efbfd010002F97A86C2Cb3e42f89AC5f5AA020E5c3505015a88dAC17F958D2ee523a2206206994597C13D831ec701A0b86991c6218b36c1d19D4a2e9Eb0cE3606eB4801ffff05a5407eae9ba41422680e2e00537571bcc53efbfd010102F97A86C2Cb3e42f89AC5f5AA020E5c3505015a88dAC17F958D2ee523a2206206994597C13D831ec7";

        LibProcessStream.ProcessedRoute memory processedRoute = LibProcessStream.processRoute(uniV2Stream);

        // Assert Processed Routes
        assertEq(processedRoute.processedMyERC20.length, 1);
        assertEq(processedRoute.processedUserERC20.length, 2);
        assertEq(processedRoute.processedNative.length, 0);
        assertEq(processedRoute.processedOnePool.length, 0);

        // Assert Processed Route Data
        assertEq(processedRoute.processedUserERC20[0].tokenIn, address(0x6B175474E89094C44Da98b954EedeAC495271d0F));
        assertEq(processedRoute.processedUserERC20[0].tokenOut, address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48));
        assertEq(processedRoute.processedUserERC20[0].pool, address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7));
        assertEq(processedRoute.processedUserERC20[0].to, address(0xe43ca1Dee3F0fc1e2df73A0745674545F11A59F5));

        // Assert Processed Route Data
        assertEq(processedRoute.processedUserERC20[1].tokenIn, address(0x6B175474E89094C44Da98b954EedeAC495271d0F));
        assertEq(processedRoute.processedUserERC20[1].tokenOut, address(0xdAC17F958D2ee523a2206206994597C13D831ec7));
        assertEq(processedRoute.processedUserERC20[1].pool, address(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD));
        assertEq(processedRoute.processedUserERC20[1].to, address(0xF97A86C2Cb3e42f89AC5f5AA020E5c3505015a88));

        // Assert Processed Route Data
        assertEq(processedRoute.processedMyERC20[0].tokenIn, address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48));
        assertEq(processedRoute.processedMyERC20[0].tokenOut, address(0xdAC17F958D2ee523a2206206994597C13D831ec7));
        assertEq(processedRoute.processedMyERC20[0].pool, address(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD));
        assertEq(processedRoute.processedMyERC20[0].to, address(0xF97A86C2Cb3e42f89AC5f5AA020E5c3505015a88));
    }

}
