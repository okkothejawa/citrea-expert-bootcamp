// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IBitcoinLightClient.sol";
import "bitcoin-spv/solidity/contracts/ValidateSPV.sol";

contract BitcoinMinerIncentives {
    receive() external payable {}

    IBitcoinLightClient public lightClient = IBitcoinLightClient(address(0x3100000000000000000000000000000000000001));

    function incentivizeMiner(uint256 blockHeight, uint256 reward, bytes memory blockHeader, bytes memory minerPubkey) public payable {
        
    }

    function checkDifficulty(bytes memory blockHeader) internal {
    }
}
