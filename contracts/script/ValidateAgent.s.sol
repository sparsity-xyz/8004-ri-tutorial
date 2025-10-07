// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {ZkCoProcessorType, ITEEValidationRegistry} from "../src/ITEEValidationRegistry.sol";
import {LibString} from "@solady/utils/LibString.sol";

contract ValidateAgentScript is Script {
    using LibString for string;
    using LibString for uint256;

    function readDeployed(string memory key) internal view returns (address) {
        address addr = vm.envAddress(key);
        console.log(string(abi.encodePacked("read ", key, " from env:")), addr);
        return addr;
    }

    function _getZkType(string memory zktype) internal pure returns (ZkCoProcessorType zkType) {
        if (zktype.eq("SP1")) {
            zkType = ZkCoProcessorType.SP1;
        } else if (zktype.eq("Risc0")) {
            zkType = ZkCoProcessorType.Risc0;
        } else {
            revert("unknown zkType");
        }
    }

    function run() public {
        // Read parameters from environment variables
        string memory proofPath = vm.envString("PROOF_PATH");
        uint256 agentId = vm.envUint("AGENT_ID");
        string memory url = vm.envString("AGENT_URL");
        string memory teeArchStr = vm.envString("TEE_ARCH");
        
        validateAgent(proofPath, agentId, url, teeArchStr);
    }

    function validateAgent(
        string memory proofPath,
        uint256 agentId,
        string memory url,
        string memory teeArchStr
    ) public {
        address registry = readDeployed("REGISTRY");
        
        // Convert TEE arch string to bytes32
        // e.g., "nitro" -> 0x6e6974726f000000000000000000000000000000000000000000000000000000
        bytes32 teeArch = bytes32(bytes(teeArchStr));
        
        // Read and parse proof JSON
        string memory proofJson = vm.readFile(proofPath);
        bytes memory journal = vm.parseJsonBytes(proofJson, ".raw_proof.journal");
        bytes memory proof = vm.parseJsonBytes(proofJson, ".onchain_proof");
        string memory proofType = vm.parseJsonString(proofJson, ".proof_type");
        
        // Verify it's a single proof (not batch)
        if (!proofType.eq("Verifier")) {
            revert(string(abi.encodePacked("Expected single proof (Verifier), got: ", proofType)));
        }
        
        // Get ZK coprocessor type
        ZkCoProcessorType zkType = _getZkType(vm.parseJsonString(proofJson, ".zktype"));
        
        console.log("====================================");
        console.log("Validating Agent with TEEValidationRegistry");
        console.log("====================================");
        console.log("Registry:", registry);
        console.log("Agent ID:", agentId);
        console.log("URL:", url);
        console.log("TEE Arch (string):", teeArchStr);
        console.log("TEE Arch (bytes32):", vm.toString(teeArch));
        console.log("ZK Type:", zkType == ZkCoProcessorType.SP1 ? "SP1" : "Risc0");
        console.log("");
        
        // Call validateAgent on the registry
        uint256 gas = gasleft();
        vm.startBroadcast();
        ITEEValidationRegistry(registry).validateAgent(
            agentId,
            url,
            teeArch,
            zkType,
            journal,
            proof
        );
        vm.stopBroadcast();
        
        console.log("");
        console.log("====================================");
        console.log("Agent validated successfully!");
        console.log("====================================");
        console.log("Agent ID:", agentId);
        console.log("Gas used:", gas - gasleft());
    }
}

