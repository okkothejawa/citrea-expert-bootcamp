// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Test, console} from "forge-std/Test.sol";

import "./IBitcoinLightClient.sol";
import "bitcoin-spv/solidity/contracts/ValidateSPV.sol";
import "bitcoin-spv/solidity/contracts/BTCUtils.sol";
import "bitcoin-spv/solidity/contracts/CheckBitcoinSigs.sol";


contract BitcoinMinerIncentives {
    using BTCUtils for bytes;
    struct BtcTxn {
        bytes4 version;
        bytes vin;
        bytes vout;
        bytes4 locktime;
        bytes intermediateNodes;
        uint256 index;
    }

    uint256 rewardAmount = 0.01 ether;

    mapping(uint256 => bool) public claimed;

    receive() external payable {}

    IBitcoinLightClient public lightClient = IBitcoinLightClient(address(0x3100000000000000000000000000000000000001));

    function incentivizeMiner(uint256 blockHeight, bytes memory blockHeader, bytes memory minerPubkey, BtcTxn memory coinbaseTxn) public {
        require(!claimed[blockHeight], "Reward already claimed");
        claimed[blockHeight] = true;

        bytes32 providedBlockHash = blockHeader.hash256();
        bytes32 trueBlockHash = lightClient.getBlockHash(blockHeight);
        require(providedBlockHash == trueBlockHash, "Provided block hash does not match the true block hash");

        bytes32 txRoot = blockHeader.extractMerkleRootLE();
        bytes32 coinbaseTxId = ValidateSPV.calculateTxId(coinbaseTxn.version, coinbaseTxn.vin, coinbaseTxn.vout, coinbaseTxn.locktime);
        require(ValidateSPV.prove(coinbaseTxId, txRoot, coinbaseTxn.intermediateNodes, 0), "Coinbase transaction is not included in the block");
        
        bytes memory output0 = coinbaseTxn.vout.extractOutputAtIndex(0);
        bytes memory scriptHash = abi.encodePacked(hex"0014", output0.extractHash());
        bytes memory btcScript = calculateBitcoinScript(minerPubkey);
        require(keccak256(scriptHash) == keccak256(btcScript), "Miner pubkey does not match the pubkey in the coinbase transaction");

        address minerEVMAddress = calculateEVMAddress(minerPubkey);
        (bool success, ) = minerEVMAddress.call{value: rewardAmount}("");
        require(success, "Failed to send reward to miner");
    }

    function calculateBitcoinScript(bytes memory pubkey) internal view returns (bytes memory) {
        return CheckBitcoinSigs.p2wpkhFromPubkey(pubkey);
    }

    function calculateEVMAddress(bytes memory pubkey) internal pure returns (address) {
        bytes32 res1;
        bytes32 res2;
        assembly {
            res1 := mload(add(add(pubkey, 32), 1))
            res2 := mload(add(add(pubkey, 32), 33))
        }
        bytes32 hashed = keccak256(abi.encodePacked(res1, res2));
        return address(uint160(uint256(hashed)));
    }
}
