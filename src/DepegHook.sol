// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Pair, PairLibrary, Id} from "Depeg-swap/contracts/libraries/Pair.sol";
import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";
import {IPoolManager} from "v4-periphery/lib/v4-core/src/interfaces/IPoolManager.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {CurrencySettler} from "@uniswap/v4-core/test/utils/CurrencySettler.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IPSMcore} from "Depeg-swap/contracts/interfaces/IPSMcore.sol";
import {ICommon} from "Depeg-swap/contracts/interfaces/ICommon.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import "v4-periphery/lib/v4-core/src/types/BeforeSwapDelta.sol";
import {HookMath} from "./lib/Math.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// TODO : Adjust ticks liquidity range
contract DepegHook is BaseHook, ERC20 {
    using PairLibrary for Pair;
    using CurrencySettler for Currency;

    error HookAddLiquidityDisabled();

    enum Action {
        ADD_LIQUIDITY,
        REMOVE_LIQUIDITY
    }

    struct CallbackData {
        uint256 amountEach; // Amount of each token to add as liquidity
        Currency currency0;
        Currency currency1;
        address sender;
        Action action;
    }

    struct DepegSwapsTokenInfo {
        address ct;
        address ds;
    }

    // if true then depeg protection is enabled(all swap will be halted)
    bool public DEPEG_FLAG;

    // dsId -> DepegSwapsTokenInfo
    mapping(uint256 => DepegSwapsTokenInfo) public depegSwapsTokenInfo;

    AggregatorV3Interface public priceFeed;
    address cork;

    Id public immutable CURRENCY_ID;

    uint256 public constant TEMP_PROTECTION_RATIO = 1 ether;

    function psm() internal view returns (IPSMcore) {
        return IPSMcore(cork);
    }

    function moduleCore() internal view returns (ICommon) {
        return ICommon(cork);
    }

    // 1%

    constructor(
        IPoolManager manager,
        AggregatorV3Interface _priceFeed,
        address _cork,
        Currency redemptionAsset,
        Currency peggedAsset
    ) BaseHook(manager) ERC20("Depeg protection", "DPG") {
        priceFeed = _priceFeed;
        cork = _cork;
        CURRENCY_ID = PairLibrary.initalize(Currency.unwrap(peggedAsset), Currency.unwrap(redemptionAsset)).toId();
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true, // Don't allow adding liquidity normally
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true, // check for depegging event after every swap
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function beforeSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, bytes calldata)
        external
        virtual
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        revert HookNotImplemented();
    }

    function beforeAddLiquidity(address, PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        revert HookAddLiquidityDisabled();
    }

    // insecure, won't handle actual ratio
    function addLiquidity(PoolKey calldata key, uint256 amountEach) external {
        poolManager.unlock(
            abi.encode(CallbackData(amountEach, key.currency0, key.currency1, msg.sender, Action.ADD_LIQUIDITY))
        );
    }

    function _doAddLiquidity(CallbackData memory callbackData) internal {
        // this amount will be deposited to PSM
        uint256 cut = HookMath.calculatePrecentage(callbackData.amountEach, TEMP_PROTECTION_RATIO);

        // we first settle both currency
        callbackData.currency0.settle(poolManager, callbackData.sender, callbackData.amountEach, false);
        callbackData.currency1.settle(poolManager, callbackData.sender, callbackData.amountEach, false);

        // we then take amountEach - cut as a ERC6909 token
        callbackData.currency0.take(poolManager, address(this), callbackData.amountEach - cut, true);
        callbackData.currency1.take(poolManager, address(this), callbackData.amountEach - cut, true);

        // take the cut amount as the underlying token
        callbackData.currency0.take(poolManager, address(this), cut, false);
        callbackData.currency1.take(poolManager, address(this), cut, false);

        // deposit the cut amount to PSM
        psm().depositPsm(CURRENCY_ID, cut);

        // store infos
        uint256 currentDsId = moduleCore().lastDsId(CURRENCY_ID);
        (address ct, address ds) = moduleCore().swapAsset(CURRENCY_ID, currentDsId);
        depegSwapsTokenInfo[currentDsId] = DepegSwapsTokenInfo(ct, ds);

        // mint user liquidity tokens to the user
        // for simplicity sake, we only mint the amount user deposit after subtracting it with the cut
        // because if we mint equal to the amount this will complicate stuff in case user wants to remove liquidity
        // not ideal, just for proof of concept
        _mint(callbackData.sender, callbackData.amountEach - cut);
    }

    function _unlockCallback(bytes calldata data) internal override returns (bytes memory) {
        CallbackData memory callbackData = abi.decode(data, (CallbackData));
        assert(msg.sender == address(poolManager));

        if (callbackData.action == Action.ADD_LIQUIDITY) {
            _doAddLiquidity(callbackData);
        }

        return "";
    }
}
