// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IBitcoinLightClient {
    function blockNumber() external view returns (uint256);
    function initializeBlockNumber(uint256) external;
    function setBlockInfo(bytes32, bytes32, uint256) external;
    function getBlockHash(uint256) external view returns (bytes32);
    function getWitnessRootByHash(bytes32) external view returns (bytes32);
    function getWitnessRootByNumber(uint256) external view returns (bytes32);
    function verifyInclusion(bytes32, bytes32, bytes calldata, uint256) external view returns (bool);
    function verifyInclusion(uint256, bytes32, bytes calldata, uint256) external view returns (bool);
    function verifyInclusionByTxId(uint256, bytes32, bytes calldata, bytes calldata, uint256) external view returns (bool);
}