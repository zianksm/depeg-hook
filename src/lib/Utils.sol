pragma solidity ^0.8.24;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";

// library HookUtility {
//     function sortAssets(PoolKey memory key, Currency redemptionAsset, Currency peggedAsset)internal pure returns (PoolKey memory) {
//         if (key.currency0 == redemptionAsset && key.currency1 == peggedAsset) {
//             return key;
//         } else if (key.currency0 == peggedAsset && key.currency1 == redemptionAsset) {
//             return PoolKey({currency0: peggedAsset, currency1: redemptionAsset});
//         } else {
//             revert("HookUtility: Invalid PoolKey");
//         }
//     }
// }
