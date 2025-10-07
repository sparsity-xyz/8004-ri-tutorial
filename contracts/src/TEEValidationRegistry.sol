// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Ownable} from "@solady/auth/Ownable.sol";
import {INitroEnclaveVerifier, ZkCoProcessorType, VerifierJournal, VerificationResult} from "./interfaces/INitroEnclaveVerifier.sol";

import {console} from "forge-std/console.sol";

struct Agent {
    uint256 agentId;
    bytes32 teeArch;
    bytes32 codeMeasurement;
    bytes pubkey;
    string url;
}

contract TEEValidationRegistry is Ownable {
    address public zkVerifier;
    mapping(uint256 => Agent) public agents;

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

    constructor() {
        _initializeOwner(msg.sender);
    }

    function setZKVerifier(address verifier) external onlyOwner {
        zkVerifier = verifier;
        emit ZKVerifierSet(verifier);
    }

    function validateAgent(
        uint256 agentId,
        string calldata url,
        bytes32 teeArch,
        ZkCoProcessorType zkCoprocessor,
        bytes calldata output,
        bytes calldata proofBytes
    ) public {
        require(zkVerifier != address(0), "Invalid zkVerifier");

        // Verify the attestation using NitroEnclaveVerifier
        VerifierJournal memory journal = INitroEnclaveVerifier(zkVerifier).verify(output, zkCoprocessor, proofBytes);
        
        // Check verification result
        require(journal.result == VerificationResult.Success, "Attestation verification failed");
        
        // Compute the hash of all PCR values for codeMeasurement
        bytes memory allPcrBytes = new bytes(journal.pcrs.length * 48);
        uint256 offset = 0;
        for (uint256 i = 0; i < journal.pcrs.length; i++) {
            bytes32 first = journal.pcrs[i].value.first;
            for (uint256 j = 0; j < 32; j++) {
                allPcrBytes[offset + j] = first[j];
            }
            bytes16 second = journal.pcrs[i].value.second;
            for (uint256 j = 0; j < 16; j++) {
                allPcrBytes[offset + 32 + j] = second[j];
            }
            offset += 48;
        }
        bytes32 codeMeasurement = keccak256(allPcrBytes);

        agents[agentId] = Agent({
            agentId: agentId,
            teeArch: teeArch,
            codeMeasurement: codeMeasurement,
            pubkey: journal.publicKey,
            url: url
        });

        emit AgentValidated(agentId, teeArch, codeMeasurement, journal.publicKey, url, zkVerifier, output);
        
        console.log("Agent validated successfully!");
        console.log("Agent ID:", agentId);
        console.log("TEE Arch:");
        console.logBytes32(teeArch);
        console.log("Code Measurement:");
        console.logBytes32(codeMeasurement);
        console.log("Public Key:");
        console.logBytes(journal.publicKey);
        console.log("URL:", url);
        console.log("ZK Verifier:", zkVerifier);
    }

    function getAgent(uint256 agentId) public view returns (Agent memory) {
        return agents[agentId];
    }
}
