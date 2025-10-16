## TEE Validation Registry (Sepolia Testnet)

This document explains the on-chain TEE Validation Registry contract, how to view and interact with it on Sepolia Testnet, and how to query it programmatically.

- Network: Sepolia Testnet (chainId 84532)
- Deployed address: `0xFcF136B76d4365Dcd06a00DC3Dc7CF835aE50ee5`
- BaseScan link: https://sepolia.basescan.org/address/0xFcF136B76d4365Dcd06a00DC3Dc7CF835aE50ee5


## What this contract does

Contract name: `TEEAgentRegistry`

High-level purpose: Maintain a registry of TEE-verified agents whose attestations are verified by a designated zk verifier. Each successful verification persists a concise agent record on-chain and emits events for indexing.

Key concepts and data shapes:

- Agent struct (stored in `agents[agentId]`):
	- `owner` (address): The address that registered this agent and has permission to update or remove it.
	- `agentId` (uint256): Sequential identifier assigned by the registry.
	- `teeArch` (bytes32): Architecture identifier of the TEE (e.g., Nitro, SGX, etc.). The specific encoding is up to the integrator (commonly a bytes32 tag or hash of a string label).
	- `codeMeasurement` (bytes32): A keccak256 hash derived from all PCR values in the verifier journal (see below).
	- `teePubkey` (bytes): The agent's public key bytes extracted from the verifier's journal.
	- `agentWalletAddress` (address): An address recovered from `journal.userData` (the first 20 bytes), representing the agent's on-chain identity.
	- `agentUrl` (string): A public endpoint or reference URL for the agent.

- Ownership model:
	- The registry owner (from `Ownable`) can set the `zkVerifier` contract address via `setZKVerifier(address)`.
	- Each agent's `owner` field stores the address that registered it. Only this owner can update or remove that agent.

- zk verifier dependency:
	- `zkVerifier` must be set to a contract that implements `INitroEnclaveVerifier`.
	- `registerAgent` and `updateAgent` both call `INitroEnclaveVerifier(zkVerifier).verify(publicValues, zkCoprocessor, proofBytes)` and require `journal.result == VerificationResult.Success`.

- Code measurement derivation:
	- The verifier journal provides an array of PCRs, each having 48 bytes (split as `bytes32 first` and `bytes16 second`).
	- The contract concatenates all PCR values in order and computes `keccak256(allPcrBytes)` to produce `codeMeasurement`.


## Public interface (selected)

Reads:
- `zkVerifier() -> address`
- `nextAgentId() -> uint256`
- `getAgentCount() -> uint256`
- `getAgentList() -> uint256[]`
- `agents(uint256 agentId) -> Agent` (returns struct with: owner, agentId, teeArch, codeMeasurement, teePubkey, agentWalletAddress, agentUrl)

Writes:
- `setZKVerifier(address verifier)` (onlyOwner)
- `registerAgent(string agentUrl, bytes32 teeArch, ZkCoProcessorType zkCoprocessor, bytes publicValues, bytes proofBytes) -> uint256 agentId`
- `updateAgent(uint256 agentId, string agentUrl, bytes32 teeArch, ZkCoProcessorType zkCoprocessor, bytes publicValues, bytes proofBytes)` (only agent owner)
- `removeAgent(uint256 agentId)` (only agent owner)

Events:
- `ZKVerifierSet(address indexed verifier)`
- `AgentModified(AgentAction indexed action, uint256 indexed agentId, bytes32 teeArch, bytes32 codeMeasurement, bytes teePubkey, address agentWalletAddress, string agentUrl, address zkVerifier, address indexed owner)`
  - `action` is an enum: `Register` (0) or `Update` (1)
- `AgentRemoved(uint256 indexed agentId, address indexed owner)`

Notes and constraints:
- `registerAgent` and `updateAgent` revert unless `zkVerifier` is set and the zk verification succeeds.
- `updateAgent` and `removeAgent` require `msg.sender` to match `agents[agentId].owner`.
- `agentId` is assigned sequentially starting from 0 and tracked by `nextAgentId` and `agentList`.


## How to view the contract on BaseScan

1) Open BaseScan on Sepolia Testnet at the contract page:
	 - https://sepolia.basescan.org/address/0xFcF136B76d4365Dcd06a00DC3Dc7CF835aE50ee5

2) Tabs you’ll use:
	 - Overview: Basic address and txn info.
	 - Contract:
		 - If the source is verified, you’ll see “Read Contract” and “Write Contract” sub-tabs.
		 - If not verified, the read/write UI may not appear. Use the programmatic options below or a local ABI to interact.
	 - Events: Browse emitted events (`AgentModified`, `AgentRemoved`, `ZKVerifierSet`).

3) Reading data on BaseScan (when verified):
	 - Contract -> Read Contract:
		 - `getAgentCount()` returns the total number of active agents currently in the registry.
		 - `getAgentList()` returns the array of agentIds currently in the registry (after removals, it's not necessarily [0..count-1]).
		 - `nextAgentId()` returns the next agentId that will be assigned (total agents ever created).
		 - `agents(agentId)` returns the full `Agent` struct from the public mapping, including the owner address.
		 - `zkVerifier()` shows the currently configured verifier address.

4) Writing on BaseScan (when verified):
	 - Contract -> Write Contract:
		 - `setZKVerifier(address)`: Only the registry owner (deployer) can call.
		 - `registerAgent(agentUrl, teeArch, zkCoprocessor, publicValues, proofBytes)`: Anyone can call, but it will succeed only if the provided proof verifies against `zkVerifier`.
		 - `updateAgent(agentId, ...)`: Only the owner of that `agentId` can call.
		 - `removeAgent(agentId)`: Only the owner of that `agentId` can call.

If the “Read/Write Contract” interface is not available (unverified):
- You can still inspect transactions, logs, and decoded inputs/outputs.
- To interact, use a script with the ABI (see examples below) or CLI tools like Foundry `cast` with a local ABI.

