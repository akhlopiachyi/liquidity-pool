// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import "../src/RewardLiquidityPool.sol";
import "../src/ERC20.sol";

contract RewardLiquidityPoolTest is Test {
    RewardLiquidityPool pool;
    IERC20 public discoToken;
    IERC20 public usdcToken;

    function beforeEach() public {
        discoToken = new ERC20Token("DISCO", "DISCO", 18); // Create a mock DISCO token
        discoToken.mint(address(this), 10000); // Mint 10000 DISCO tokens to the test contract

        usdcToken = new ERC20Token("USDC", "USDC", 18); // Create a mock USDC token
        usdcToken.mint(address(this), 100000); // Mint 10000 DISCO tokens to the test contract

        pool = new RewardLiquidityPool(
            address(discoToken),
            address(usdcToken),
            100,
            30
        ); // Mock tokens, fixed price 100, claim period 30 days

        discoToken.transfer(address(pool), 10000); // Transfer all minted DISCO tokens to the pool contract

        console.log(discoToken.balanceOf(address(pool)));
    }

   function testBuyTokens() public {
        // add test context
    }

    function testClaimRewards() public {
        // add test context
    }

    function testDecommissionPool() public {
        // add test context
    }

    function testWithdrawTokens() public {
        // add test context
    }

    function testWithdrawUnclaimedRewards() public {
        // add test context
    }
}
