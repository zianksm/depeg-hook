pragma solidity ^0.8.24;

import "./../src/DepegHook.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {PoolManager} from "v4-core/PoolManager.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import Helpers

contract HookHelpers is Deployers {
    DepegHook internal hook;

    uint160 internal constant HOOK_ADDRESS = uint160(
        Hooks.BEFORE_ADD_LIQUIDITY_FLAG | Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
            | Hooks.AFTER_ADD_LIQUIDITY_FLAG
    );

    Currency internal token0;
    Currency internal token1;

    function setupWithMockPair() internal {
        
    }
}
