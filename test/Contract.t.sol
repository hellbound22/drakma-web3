// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract ContractTest is Test {
    function setUp() public {}

    function testExample() public {
        uint fator = 100;
        uint c = 1000 * fator;
        uint t_juros = 10; // 0.1 * 100

        uint m = c*((1+t_juros)**2);

        console.log(m / fator / fator);
    }
}
