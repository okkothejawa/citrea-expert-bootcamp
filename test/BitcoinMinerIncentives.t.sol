// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {BitcoinMinerIncentives} from "../src/BitcoinMinerIncentives.sol";
import "bitcoin-spv/solidity/contracts/ValidateSPV.sol";
import "bitcoin-spv/solidity/contracts/CheckBitcoinSigs.sol";


contract BitcoinMinerIncentivesTest is Test {
    BitcoinMinerIncentives bmi;

    function setUp() public {
        bmi = new BitcoinMinerIncentives();
    }

    function testIncentive() public {
        vm.deal(address(bmi), 0.01 ether);
        bytes memory blockHeader = hex"0000002041e7d147af6a599d289b0e012383f4ebd77663f46547313ec9bb47021d00000075c3823ceb511ba78014706e3bfbf5e1d35c21ac1be74f28fe845fd265df87ffee2b9e66ae77031ec9a60e00";
        bytes memory minerPubkey = hex"046783b5ca89d7845fa9874685593a980a982d5cdb0e63b80456de91f704b4985854029f23360cb0f9597bc717eae72f055e07e1a5c7253ec9027d11e208b99129";
        
        bytes4 version = hex"02000000";
        bytes memory vin = hex"010000000000000000000000000000000000000000000000000000000000000000ffffffff04034a6306feffffff";
        bytes memory vout = hex"021ffd029500000000160014652be9203bf5b60d4c2205612edbe2d537c1be0c0000000000000000776a24aa21a9ed0be041774d1c61595182e721c5097876abc8e91ec0c4b80ecd80376029f165924c4fecc7daa2490047304402202f92cb50502c5caafcb868cd70da1ea299bc034214c6f73e4a522f2f7302ad4102203ed3cb706856eafed382dd8a75ad1650169024a4ae6e5a6574c9b5d18805e58c0100";
        bytes4 locktime = hex"00000000";

        bytes memory intermediateNodes = hex"db90907211d60c424f589f2617c2c96d17c0256d9df47e0dbe963621de23cdb461d902cb548c3dc301068725aae39c29d25f0d0a0bb491f60179837ede933a7f";
        uint256 index = 0;

        BitcoinMinerIncentives.BtcTxn memory coinbaseTxn = BitcoinMinerIncentives.BtcTxn(version, vin, vout, locktime, intermediateNodes, index);
        bmi.incentivizeMiner(418634, blockHeader, minerPubkey, coinbaseTxn);
    }
}
