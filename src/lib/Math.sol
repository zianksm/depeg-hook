pragma solidity ^0.8.24;

library HookMath {
    function calculatePrecentage(uint256 x, uint256 percent) internal pure returns (uint256 result) {
        result = (((x * 1e18) * percent) / (100 * 1e18)) / 1e18;
    }
}
