pragma solidity ^0.8.24;

import "./../src/DepegHook.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {PoolManager} from "v4-core/PoolManager.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import "forge-std/mocks/MockERC20.sol";
import "Depeg-swap/test/forge/Helper.sol";
import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";

contract HookHelpers is Deployers, Helper {
    DepegHook internal hook;
    using CurrencyLibrary for Currency;

    uint160 internal constant HOOK_ADDRESS = uint160(
        Hooks.BEFORE_ADD_LIQUIDITY_FLAG | Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
            | Hooks.AFTER_ADD_LIQUIDITY_FLAG
    );

    Currency internal token0;
    Currency internal token1;

    function setupWithMockPair() internal {
        address mock1 = address(deployMockERC20("MOCK1", "MCK", 18));
        address mock2 = address(deployMockERC20("MOCK2", "MCK", 18));

        token0 = mock0 < mock1 ? Currency.wrap(mock0) : Currency.wrap(mock1);
        
    }
}
