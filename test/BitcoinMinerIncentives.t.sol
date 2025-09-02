// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {BitcoinMinerIncentives} from "../src/BitcoinMinerIncentives.sol";
import "bitcoin-spv/solidity/contracts/ValidateSPV.sol";
import "bitcoin-spv/solidity/contracts/CheckBitcoinSigs.sol";


contract BitcoinMinerIncentivesTest is Test {
    BitcoinMinerIncentives bmi;

    function setUp() public {
        vm.createSelectFork("https://rpc.testnet.citrea.xyz");
        bmi = new BitcoinMinerIncentives();
    }

    function testSetBlockMiner() public {

    }
}
