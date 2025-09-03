// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IBitcoinLightClient.sol";
import "bitcoin-spv/solidity/contracts/ValidateSPV.sol";
import "bitcoin-spv/solidity/contracts/BTCUtils.sol";
import "bitcoin-spv/solidity/contracts/CheckBitcoinSigs.sol";

contract BitcoinMinerIncentives {
    using BTCUtils for bytes;
    using BytesLib for bytes;

    struct BtcTxn {
        bytes4 version;
        bytes vin;
        bytes vout;
        bytes4 locktime;
        bytes intermediateNodes;
        uint256 index;
    }

    struct IncentiveForTx {
        uint256 amount;
        bool claimed;
        uint32 expiryTime;
    }

    struct IncentiveByUser {
        uint256 amount;
        bool refunded;
    }

    uint32 public constant TX_INCENTIVE_REFUND_AFTER = 2 weeks;
    uint32 public constant TX_INCENTIVE_CLAIMER_GRACE_PERIOD = 1 days;
    uint256 public constant BLOCK_REWARD_AMOUNT = 0.01 ether;
    uint256 public totalBlockReward;

    mapping(uint256 => address) public miners;
    mapping(uint256 => bool) public blockRewardClaimed;
    mapping(bytes32 => IncentiveForTx) public txIncentives;
    mapping(address => mapping(bytes32 => IncentiveByUser)) public txIncentivesByUser;

    event TotalBlockRewardUpdated(uint256 newTotal);
    event BlockMinerSet(uint256 blockHeight, address miner);
    event TxIncentivized(bytes32 txId, uint256 amount);
    event BlockRewardClaimed(uint256 blockHeight, address miner);
    event IncentiveForTxClaimed(bytes32 txId, address miner, uint256 amount);
    event IncentiveForTxRefunded(bytes32 txId, address user, uint256 amount);

    receive() external payable {
        totalBlockReward += msg.value;
        emit TotalBlockRewardUpdated(totalBlockReward);
    }

    IBitcoinLightClient public lightClient = IBitcoinLightClient(address(0x3100000000000000000000000000000000000001));

    function setBlockMiner(uint256 blockHeight, bytes memory blockHeader, bytes memory minerPubkey, BtcTxn memory coinbaseTxn) public {
        bytes32 coinbaseTxId = ValidateSPV.calculateTxId(coinbaseTxn.version, coinbaseTxn.vin, coinbaseTxn.vout, coinbaseTxn.locktime);
        require(lightClient.verifyInclusionByTxId(blockHeight, coinbaseTxId, blockHeader, coinbaseTxn.intermediateNodes, 0));
        
        bytes memory output0 = coinbaseTxn.vout.extractOutputAtIndex(0);
        bytes memory expectedP2wpkh = abi.encodePacked(hex"0014", output0.extractHash());
        bytes memory p2wpkh = calculateP2WPKH(minerPubkey);
        require(keccak256(expectedP2wpkh) == keccak256(p2wpkh), "Miner pubkey does not match the pubkey in the coinbase transaction");
        address miner = calculateEvmAddress(minerPubkey);
        miners[blockHeight] = miner;

        emit BlockMinerSet(blockHeight, miner);
    }

    function claimBlockReward(uint256 blockHeight) public {
        require(!blockRewardClaimed[blockHeight], "Reward already claimed");
        blockRewardClaimed[blockHeight] = true;

        address miner = miners[blockHeight];
        require(miner != address(0), "Miner address not set for this block");

        require(totalBlockReward >= BLOCK_REWARD_AMOUNT, "Insufficient funds for block reward");
        totalBlockReward -= BLOCK_REWARD_AMOUNT;

        (bool success, ) = miner.call{value: BLOCK_REWARD_AMOUNT}("");
        require(success, "Failed to send reward to miner");

        emit BlockRewardClaimed(blockHeight, miner);
    }

    function incentivizeTx(bytes32 txId) public payable {
        _incentivizeTx(txId);
    }

    function incentivizeTx(bytes32 txId, bytes calldata /* signedTx */) public payable {
        // @dev signedTx's txId should match the provided txId, this is to be verified off-chain
        _incentivizeTx(txId);
    }

    function _incentivizeTx(bytes32 txId) internal {
        require(msg.value > 0, "Incentive amount must be greater than 0");
        require(!txIncentives[txId].claimed, "Transaction incentive already claimed");
        txIncentives[txId].amount += msg.value;
        txIncentivesByUser[msg.sender][txId].amount += msg.value;
        // Set expiry time only if the first time incentivizing to prevent DoS via extending expiry indefinitely
        if (txIncentives[txId].expiryTime == 0) {
            txIncentives[txId].expiryTime = uint32(block.timestamp) + TX_INCENTIVE_REFUND_AFTER;
        }
        emit TxIncentivized(txId, msg.value);
    }

    function claimIncentiveForTx(bytes32 txId, uint256 blockHeight, bytes memory blockHeader, bytes memory intermediateNodes, uint256 index) public {
        require(lightClient.verifyInclusionByTxId(blockHeight, txId, blockHeader, intermediateNodes, index), "Transaction not included in the specified block");

        require(!txIncentives[txId].claimed, "Transaction incentive already claimed");
        txIncentives[txId].claimed = true;

        // Tx needs to be mined before expiry to be eligible for incentive
        uint32 blockTime = blockHeader.extractTimestamp();
        require(blockTime <= txIncentives[txId].expiryTime, "Transaction incentive has expired");

        address miner = miners[blockHeight];
        require(miner != address(0), "Miner address not set for this block");

        uint256 incentiveAmount = txIncentives[txId].amount;
        require(incentiveAmount > 0, "No incentive for this transaction");

        (bool success, ) = miner.call{value: incentiveAmount}("");
        require(success, "Failed to send incentive to miner");

        emit IncentiveForTxClaimed(txId, miner, incentiveAmount);
    }

    function refundIncentiveForTx(bytes32 txId) public {
        IncentiveForTx memory txIncentive = txIncentives[txId];
        require(!txIncentive.claimed, "Transaction incentive already claimed");
        require(block.timestamp > txIncentive.expiryTime + TX_INCENTIVE_CLAIMER_GRACE_PERIOD, "Transaction incentive not yet expired");

        IncentiveByUser memory userIncentive = txIncentivesByUser[msg.sender][txId];
        require(userIncentive.amount > 0, "No incentive to refund for this user");
        require(!userIncentive.refunded, "Incentive already refunded for this user");

        txIncentivesByUser[msg.sender][txId].refunded = true;

        (bool success, ) = msg.sender.call{value: userIncentive.amount}("");
        require(success, "Failed to refund incentive to user");

        emit IncentiveForTxRefunded(txId, msg.sender, userIncentive.amount);
    }

    function calculateP2WPKH(bytes memory pubkey) internal view returns (bytes memory) {
        return CheckBitcoinSigs.p2wpkhFromPubkey(pubkey);
    }

    function calculateEvmAddress(bytes memory pubkey) internal pure returns (address) {
        require(pubkey.length == 65, "Invalid public key length");
        return address(uint160(uint256(keccak256(pubkey.slice(1, 64)))));
    }
}
