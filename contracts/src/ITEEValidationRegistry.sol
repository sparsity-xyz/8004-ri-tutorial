// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

enum ZkCoProcessorType {
    Unknown,
    RiscZero,
    Succinct
}

struct Agent {
    uint256 agentId;
    bytes32 teeArch;
    bytes32 codeMeasurement;
    bytes pubkey;
    string url;
}

interface ITEEValidationRegistry {
    event ZKVerifierSet(address indexed verifier);
    event AgentValidated(
        uint256 indexed agentId,
        bytes32 teeArch,
        bytes32 codeMeasurement,
        bytes pubkey,
        string url,
        address zkVerifier,
        bytes zkProof
    );

    function zkVerifier() external view returns (address);
    
    function agents(uint256 agentId) external view returns (Agent memory);

    function setZKVerifier(address verifier) external;

    function validateAgent(
        uint256 agentId,
        string calldata url,
        bytes32 teeArch,
        ZkCoProcessorType zkCoprocessor,
        bytes calldata output,
        bytes calldata proofBytes
    ) external;

    function getAgent(uint256 agentId) external view returns (Agent memory);
}
