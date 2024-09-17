pragma solidity ^0.8.24;

import "./Helper.sol";
import {IHooks} from "v4-periphery/lib/v4-core/src/interfaces/IHooks.sol";
import "../src/lib/Math.sol";

contract LiquidityTest is HookHelpers {
    function setUp() external {
        setupWithMockPair();

        initPool(
            hookCurrency0,
            hookCurrency1,
            IHooks(hook),
            hook.DEFAULT_FEE(),
            hook.DEFAULT_TICK_SPACING(),
            SQRT_PRICE_1_1,
            ZERO_BYTES
        );
    }

    function test_calcPercentage() external {
        uint256 percentage = HookMath.calculatePrecentage(1 ether, 10 ether);
        vm.assertEq(percentage, 0.1 ether);
    }

    function test_addLiquidity() external {
        vm.startPrank(DEFAULT_ADDRESS);

        uint256 amountEach = 10 ether;
        uint256 cut = HookMath.calculatePrecentage(amountEach, hook.TEMP_PROTECTION_RATIO());

        token0.mint(DEFAULT_ADDRESS, amountEach);
        token1.mint(DEFAULT_ADDRESS, amountEach);

        token0.approve(address(hook), amountEach);
        token1.approve(address(hook), amountEach);

        hook.addLiquidity(amountEach);

        uint256 lpBalance = hook.balanceOf(DEFAULT_ADDRESS);

        vm.assertEq(lpBalance, amountEach - cut);
    }
}
