## TEE Agent Registry (Base Sepolia)

This document explains the on-chain TEE Agent Registry contract, how to view and interact with it on Base Sepolia.

- Network: Base Sepolia (chainId 84532)
- Deployed address: `0xe718aec274E36781F18F42C363A3B516a4427637`
- BaseScan link: https://sepolia.basescan.org/address/0xe718aec274E36781F18F42C363A3B516a4427637


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

- Code measurement derivation:
	- The verifier journal provides an array of PCRs, each having 48 bytes (split as `bytes32 first` and `bytes16 second`).
	- The contract concatenates all PCR values in order and computes `keccak256(allPcrBytes)` to produce `codeMeasurement`.


## Public interface (selected)

Reads:
- `getAgentCount() -> uint256`
- `getAgentList() -> uint256[]`
- `agents(uint256 agentId) -> Agent` (returns struct with: owner, agentId, teeArch, codeMeasurement, teePubkey, agentWalletAddress, agentUrl)

Writes:
- `registerAgent(string agentUrl, bytes32 teeArch, ZkCoProcessorType zkCoprocessor, bytes publicValues, bytes proofBytes) -> uint256 agentId`
- `updateAgent(uint256 agentId, string agentUrl, bytes32 teeArch, ZkCoProcessorType zkCoprocessor, bytes publicValues, bytes proofBytes)` (only agent owner)
- `removeAgent(uint256 agentId)` (only agent owner)

Events:
- `AgentModified(AgentAction indexed action, uint256 indexed agentId, bytes32 teeArch, bytes32 codeMeasurement, bytes teePubkey, address agentWalletAddress, string agentUrl, address zkVerifier, address indexed owner)`
  - `action` is an enum: `Register` (0) or `Update` (1)
- `AgentRemoved(uint256 indexed agentId, address indexed owner)`

## How to view the contract on BaseScan

1) Open BaseScan on Base Sepolia at the contract page:
	- https://sepolia.basescan.org/address/0xe718aec274E36781F18F42C363A3B516a4427637

2) Tabs you’ll use:
	 - Transactions: View all transactions interacting with the contract.
	 - Token Transfers: View any token transfers (not applicable here).
	 - Contract:
		 - If the source is verified, you’ll see “Read Contract” and “Write Contract” sub-tabs.
		 - If not verified, the read/write UI may not appear. 
	 - Events: Browse emitted events (`AgentModified`, `AgentRemoved`, `ZKVerifierSet`).


3) Reading data on BaseScan (when verified):
	 - Contract -> Read Contract:
		 - `getAgentCount()` -> current active agents (length of agentList).
		 - `getAgentList()` -> array of current agentIds (after removals, not necessarily contiguous).
		 - `agents(agentId)` -> full `Agent` struct (owner, agentId, teeArch, codeMeasurement, teePubkey, agentWalletAddress, agentUrl).

4) Writing on BaseScan (when verified):
	 - Contract -> Write Contract:
		 - `registerAgent(agentUrl, teeArch, zkCoprocessor, publicValues, proofBytes)`: Anyone can call; succeeds only if the provided proof verifies against `zkVerifier`.
		 - `updateAgent(agentId, ...)`: Only the owner of that `agentId` can call.
		 - `removeAgent(agentId)`: Only the owner of that `agentId` can call.

