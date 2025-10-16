## TEE Validation Registry (Sepolia Testnet)

This document explains the on-chain TEE Validation Registry contract, how to view and interact with it on Sepolia Testnet, and how to query it programmatically.

- Network: Sepolia Testnet (chainId 84532)
- Deployed address: `0xFcF136B76d4365Dcd06a00DC3Dc7CF835aE50ee5`
- BaseScan link: https://sepolia.basescan.org/address/0xFcF136B76d4365Dcd06a00DC3Dc7CF835aE50ee5


## What this contract does

Contract name: `TEEValidationRegistry`

High-level purpose: Maintain a registry of TEE-verified agents whose attestations are verified by a designated zk verifier. Each successful verification persists a concise agent record on-chain and emits events for indexing.

Key concepts and data shapes:

- Agent struct (returned by `getAgent` and stored in `agents[agentId]`):
	- `agentId` (uint256): Sequential identifier assigned by the registry.
	- `teeArch` (bytes32): Architecture identifier of the TEE (e.g., Nitro, SGX, etc.). The specific encoding is up to the integrator (commonly a bytes32 tag or hash of a string label).
	- `codeMeasurement` (bytes32): A keccak256 hash derived from all PCR values in the verifier journal (see below).
	- `pubkey` (bytes): The agent’s public key bytes extracted from the verifier’s journal.
	- `agentAddress` (address): An address recovered from `journal.userData` (the first 20 bytes), representing the agent’s on-chain identity.
	- `url` (string): A public endpoint or reference URL for the agent.

- Ownership model:
	- The registry owner (from `Ownable`) can set the `zkVerifier` contract address via `setZKVerifier(address)`.
	- Each `agentId` has an owner recorded in `agentOwners[agentId]` (the caller who validated it). Only this owner can update or remove that agent.

- zk verifier dependency:
	- `zkVerifier` must be set to a contract that implements `INitroEnclaveVerifier`.
	- `validateAgent` and `updateAgent` both call `INitroEnclaveVerifier(zkVerifier).verify(output, zkCoprocessor, proofBytes)` and require `journal.result == VerificationResult.Success`.

- Code measurement derivation:
	- The verifier journal provides an array of PCRs, each having 48 bytes (split as `bytes32 first` and `bytes16 second`).
	- The contract concatenates all PCR values in order and computes `keccak256(allPcrBytes)` to produce `codeMeasurement`.


## Public interface (selected)

Reads:
- `zkVerifier() -> address`
- `getAgentCount() -> uint256`
- `getAgentList() -> uint256[]`
- `getAgent(uint256 agentId) -> (uint256 agentId, bytes32 teeArch, bytes32 codeMeasurement, bytes pubkey, address agentAddress, string url)`
- `agents(uint256 agentId) -> Agent` (same fields as `getAgent`)
- `agentOwners(uint256 agentId) -> address`

Writes:
- `setZKVerifier(address verifier)` (onlyOwner)
- `validateAgent(string url, bytes32 teeArch, ZkCoProcessorType zkCoprocessor, bytes output, bytes proofBytes) -> uint256 agentId`
- `updateAgent(uint256 agentId, string url, bytes32 teeArch, ZkCoProcessorType zkCoprocessor, bytes output, bytes proofBytes)` (only agent owner)
- `removeAgent(uint256 agentId)` (only agent owner)

Events:
- `ZKVerifierSet(address verifier)`
- `AgentValidated(uint256 agentId, bytes32 teeArch, bytes32 codeMeasurement, bytes pubkey, address agentAddress, string url, address zkVerifier, bytes zkProof, address owner)`
- `AgentUpdated(uint256 agentId, bytes32 teeArch, bytes32 codeMeasurement, bytes pubkey, address agentAddress, string url, address zkVerifier, bytes zkProof, address owner)`
- `AgentRemoved(uint256 agentId, address owner)`

Notes and constraints:
- `validateAgent` and `updateAgent` revert unless `zkVerifier` is set and the zk verification succeeds.
- `updateAgent` and `removeAgent` require `msg.sender` to match `agentOwners[agentId]`.
- `agentId` is assigned sequentially starting from 0 and tracked by `agentCount` and `agentList`.


## How to view the contract on BaseScan

1) Open BaseScan on Sepolia Testnet at the contract page:
	 - https://sepolia.basescan.org/address/0xFcF136B76d4365Dcd06a00DC3Dc7CF835aE50ee5

2) Tabs you’ll use:
	 - Overview: Basic address and txn info.
	 - Contract:
		 - If the source is verified, you’ll see “Read Contract” and “Write Contract” sub-tabs.
		 - If not verified, the read/write UI may not appear. Use the programmatic options below or a local ABI to interact.
	 - Events: Browse emitted events (`AgentValidated`, `AgentUpdated`, `AgentRemoved`, `ZKVerifierSet`).

3) Reading data on BaseScan (when verified):
	 - Contract -> Read Contract:
		 - `getAgentCount()` returns the total number of agents ever created.
		 - `getAgentList()` returns the array of agentIds currently in the registry (after removals, it’s not necessarily [0..count-1]).
		 - `getAgent(agentId)` returns the full `Agent` tuple.
		 - `agents(agentId)` returns the same `Agent` data from the public mapping.
		 - `agentOwners(agentId)` shows the owner address for an agent.
		 - `zkVerifier()` shows the currently configured verifier address.

4) Writing on BaseScan (when verified):
	 - Contract -> Write Contract:
		 - `setZKVerifier(address)`: Only the registry owner (deployer) can call.
		 - `validateAgent(url, teeArch, zkCoprocessor, output, proofBytes)`: Anyone can call, but it will succeed only if the provided proof verifies against `zkVerifier`.
		 - `updateAgent(agentId, ...)`: Only the owner of that `agentId` can call.
		 - `removeAgent(agentId)`: Only the owner of that `agentId` can call.

If the “Read/Write Contract” interface is not available (unverified):
- You can still inspect transactions, logs, and decoded inputs/outputs.
- To interact, use a script with the ABI (see examples below) or CLI tools like Foundry `cast` with a local ABI.

