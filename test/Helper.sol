pragma solidity ^0.8.24;

import "./../src/DepegHook.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {PoolManager} from "v4-core/PoolManager.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import "Depeg-swap/test/forge/Helper.sol";
import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "forge-std/console.sol";

contract HookHelpers is Helper, Deployers {
    DepegHook internal hook;

    using CurrencyLibrary for Currency;

    uint160 internal constant HOOK_ADDRESS =
        uint160(Hooks.BEFORE_ADD_LIQUIDITY_FLAG | Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG);

    MockERC20 token0;
    MockERC20 token1;

    // RA
    Currency internal hookCurrency0;
    // PA
    Currency internal hookCurrency1;

    uint256 DEFAULT_EXPIRY = 1 days;

    // ezETH/ETH
    address AGGREGATOR_ADDRESS = 0x636A000262F6aA9e1F094ABF0aD8f645C44f641C;

    function setupWithMockPair() internal {
        deployFreshManagerAndRouters();
        deployModuleCore();

        MockERC20 tmpMock0 = new MockERC20("TOKEN", "TEST", 18);
        MockERC20 tmpMock1 = new MockERC20("TOKEN", "TEST", 18);

        address mock1 = address(tmpMock0) < address(tmpMock1) ? address(tmpMock0) : address(tmpMock1);
        address mock2 = address(tmpMock0) < address(tmpMock1) ? address(tmpMock1) : address(tmpMock0);

        token0 = MockERC20(mock1);
        token1 = MockERC20(mock2);

        hookCurrency0 = Currency.wrap(mock1);
        hookCurrency1 = Currency.wrap(mock2);

        bytes memory params = abi.encode(
            manager, AggregatorV3Interface(AGGREGATOR_ADDRESS), address(moduleCore), hookCurrency0, hookCurrency1
        );

        deployCodeTo("DepegHook.sol", params, 0, address(HOOK_ADDRESS));

        hook = DepegHook(address(HOOK_ADDRESS));

        uint256 dsPrice = DEFAULT_INITIAL_DS_PRICE;

        corkConfig.initializeModuleCore(Currency.unwrap(hookCurrency1), Currency.unwrap(hookCurrency0), 0, dsPrice);
        Id id = moduleCore.getId(Currency.unwrap(hookCurrency1), Currency.unwrap(hookCurrency0));   
        issueNewDs(id, DEFAULT_EXPIRY);

    }
}
