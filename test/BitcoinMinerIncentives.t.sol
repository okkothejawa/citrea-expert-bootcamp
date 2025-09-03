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
        
        // https://mempool.space/testnet4/block/0000000003c1888ee2c9ca5a0570556567286c78c9f71d084b2ac93df631bdf5
        uint256 blockHeight = 100018;
        bytes memory minerPubkey = hex"040ec9db9c13a8ab81686c405f1ff82b62494faaeae4cf4c67d46233399c34149416b20a1f917e54994e1ba11af87f4d3282cb410427168addcc1a4b80bc15d299";
        bytes memory blockHeader = hex"00006120568e38945e395ed0996edfaedc35ec539fdb7b3ffd8a626901000000000000003e69c3b37fc8674d253c4320e167ca45a93aa7acd45a40df33a9986cdd496126739ab468ffff001d8c0299ec";

        bytes4 version = hex"01000000";
        bytes memory vin = hex"010000000000000000000000000000000000000000000000000000000000000000ffffffff2703b2860100040190b468041533e3090caafbae68000000000026cc3f0a636b706f6f6c032f302fffffffff";
        bytes memory vout = hex"02ad250d2a01000000160014f7e30e04d4c474790185e802d84426ea6b8d074c0000000000000000266a24aa21a9ed396c34ad6f28ee8d839ce6fb49d1c2dedebef5499c8dea19d1ad582254b5e5f3";
        bytes4 locktime = hex"00000000";

        bytes memory intermediateNodes = hex"5AFF57377D61068662222EE90CEF16AAE48BD2128AB462BF0BC313CC22B1F236F333CB522AED40CC05A91086FC20A2D547172E66C60C646A0B197CB7AE723663A6EA617AE01B2DAACFC88A60E2D94A85164DB7FAD807093904969EAD67A69A9E";
        BitcoinMinerIncentives.BtcTxn memory coinbaseTxn = BitcoinMinerIncentives.BtcTxn({
            version: version,
            vin: vin,
            vout: vout,
            locktime: locktime,
            intermediateNodes: intermediateNodes,
            index: 0
        });

        bmi.setBlockMiner(blockHeight, blockHeader, minerPubkey, coinbaseTxn);

        address donator = makeAddr("donator");
        vm.deal(donator, 1 ether);

        vm.prank(donator);
        (bool success, ) = address(bmi).call{value: 0.5 ether}("");
        require(success, "Failed to donate");

        assertEq(address(bmi).balance, 0.5 ether);
        assertEq(bmi.totalBlockReward(), 0.5 ether);
    }

    function testClaimBlockReward() public {
        uint256 blockHeight = 100018;
        address miner = bmi.miners(blockHeight);
        vm.prank(miner);
        bmi.claimBlockReward(blockHeight);

        assertEq(address(bmi).balance, 0.5 ether - bmi.BLOCK_REWARD_AMOUNT());
        assertEq(bmi.totalBlockReward(), 0.5 ether - bmi.BLOCK_REWARD_AMOUNT());
    }
}
