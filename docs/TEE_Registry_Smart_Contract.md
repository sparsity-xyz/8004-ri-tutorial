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


## Programmatic usage examples

Below are minimal examples for read-only queries. Replace the RPC URL and private key handling per your environment.

### ABI fragment (reads only)

You can save this minimal ABI JSON locally (e.g., `tee_registry_abi.json`) to use with scripts/CLIs:

```json
[
	{"inputs":[],"name":"zkVerifier","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},
	{"inputs":[],"name":"getAgentCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},
	{"inputs":[],"name":"getAgentList","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},
	{"inputs":[{"internalType":"uint256","name":"agentId","type":"uint256"}],"name":"getAgent","outputs":[
		{"components":[
			{"internalType":"uint256","name":"agentId","type":"uint256"},
			{"internalType":"bytes32","name":"teeArch","type":"bytes32"},
			{"internalType":"bytes32","name":"codeMeasurement","type":"bytes32"},
			{"internalType":"bytes","name":"pubkey","type":"bytes"},
			{"internalType":"address","name":"agentAddress","type":"address"},
			{"internalType":"string","name":"url","type":"string"}
		],"internalType":"struct Agent","name":"","type":"tuple"}
	],"stateMutability":"view","type":"function"},
	{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"agents","outputs":[
		{"internalType":"uint256","name":"agentId","type":"uint256"},
		{"internalType":"bytes32","name":"teeArch","type":"bytes32"},
		{"internalType":"bytes32","name":"codeMeasurement","type":"bytes32"},
		{"internalType":"bytes","name":"pubkey","type":"bytes"},
		{"internalType":"address","name":"agentAddress","type":"address"},
		{"internalType":"string","name":"url","type":"string"}
	],"stateMutability":"view","type":"function"},
	{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"agentOwners","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"}
]
```

### web3.py (Python)

```python
from web3 import Web3
import json

ADDR = "0xFcF136B76d4365Dcd06a00DC3Dc7CF835aE50ee5"
RPC  = "https://sepolia.base.org"  # or your provider URL for Sepolia Testnet

w3 = Web3(Web3.HTTPProvider(RPC))
abi = json.load(open("tee_registry_abi.json"))
reg = w3.eth.contract(address=ADDR, abi=abi)

count = reg.functions.getAgentCount().call()
print("agentCount:", count)

ids = reg.functions.getAgentList().call()
print("agentIds:", ids)

if ids:
		agent = reg.functions.getAgent(ids[0]).call()
		# agent is a tuple matching the Agent struct order
		print("first agent:")
		print({
				"agentId": agent[0],
				"teeArch": agent[1].hex(),
				"codeMeasurement": agent[2].hex(),
				"pubkey": agent[3].hex(),
				"agentAddress": agent[4],
				"url": agent[5],
		})
```

### ethers.js (Node.js)

```js
const { ethers } = require("ethers");
const fs = require("fs");

const ADDR = "0xFcF136B76d4365Dcd06a00DC3Dc7CF835aE50ee5";
const RPC  = "https://sepolia.base.org"; // or your provider URL for Sepolia Testnet

async function main() {
	const provider = new ethers.JsonRpcProvider(RPC);
	const abi = JSON.parse(fs.readFileSync("tee_registry_abi.json"));
	const reg = new ethers.Contract(ADDR, abi, provider);

	const count = await reg.getAgentCount();
	console.log("agentCount:", count.toString());

	const ids = await reg.getAgentList();
	console.log("agentIds:", ids.map(x => x.toString()));

	if (ids.length > 0n) {
		const a = await reg.getAgent(ids[0]);
		console.log({
			agentId: a.agentId.toString(),
			teeArch: a.teeArch,
			codeMeasurement: a.codeMeasurement,
			pubkey: ethers.hexlify(a.pubkey),
			agentAddress: a.agentAddress,
			url: a.url
		});
	}
}

main().catch(console.error);
```

### Foundry cast (CLI)

Save the ABI above to `tee_registry_abi.json` and then:

```bash
# Read agent count
cast call 0xFcF136B76d4365Dcd06a00DC3Dc7CF835aE50ee5 "getAgentCount()(uint256)" \
	--rpc-url $BASE_SEPOLIA_RPC

# Read agent list (array of uint256)
cast call 0xFcF136B76d4365Dcd06a00DC3Dc7CF835aE50ee5 "getAgentList()(uint256[])" \
	--rpc-url $BASE_SEPOLIA_RPC

# Read a specific agent by id (example: 0)
cast call 0xFcF136B76d4365Dcd06a00DC3Dc7CF835aE50ee5 \
	"getAgent(uint256)(uint256,bytes32,bytes32,bytes,address,string)" 0 \
	--rpc-url $BASE_SEPOLIA_RPC
```


## Write interactions (overview)

These functions mutate state and require gas and proper permissions:

- `setZKVerifier(address verifier)`
	- Only owner (deployer) can call.
	- Sets the verifier contract used by `validateAgent`/`updateAgent`.

- `validateAgent(string url, bytes32 teeArch, ZkCoProcessorType zkCoprocessor, bytes output, bytes proofBytes)`
	- Anyone can call. Requires `zkVerifier` to be configured and the proof/journal to verify.
	- On success: assigns new `agentId`, stores the `Agent`, emits `AgentValidated` and returns the `agentId`.

- `updateAgent(uint256 agentId, ...)`
	- Only the `agentOwners[agentId]` can call. Re-verifies the provided attestation and updates the stored agent data; emits `AgentUpdated`.

- `removeAgent(uint256 agentId)`
	- Only the `agentOwners[agentId]` can call. Removes from storage and from the `agentList` via swap-and-pop; emits `AgentRemoved`.

Tip: For bytes inputs (`output`, `proofBytes`), pass 0x-prefixed hex. The `teeArch` should be a 32-byte value (0x + 64 hex chars). Strings like `url` are UTF-8.


## Event indexing

You can subscribe to events via any node provider or indexer:

- `AgentValidated` and `AgentUpdated` carry full derived metadata including `codeMeasurement` and `pubkey` for off-chain indexing.
- `AgentRemoved` signals deletions; use `getAgentList()` to derive current active ids.
- `ZKVerifierSet` signals updates to the verifier address.


## Verifier and PCR hashing details

When validating or updating an agent:

1) The registry calls `INitroEnclaveVerifier(zkVerifier).verify(output, zkCoprocessor, proofBytes)`.
2) It requires `journal.result == VerificationResult.Success`.
3) It constructs `codeMeasurement = keccak256(concat(pcr[i].value.first (32 bytes), pcr[i].value.second (16 bytes)) for all i)`.
4) It sets `agentAddress = address(bytes20(journal.userData))`.
5) It persists the `Agent` and ownership, then emits the corresponding event.

For background on how the attestation and journal are produced, see `docs/AWS_Nitro_Enclave_Runtime.md` in this repository.


## Troubleshooting

- If BaseScan doesn’t show Read/Write tabs, the contract might not be verified. Use the ABI with scripts or CLI.
- Calls revert with "Invalid zkVerifier": the owner must first call `setZKVerifier`.
- Calls revert with "Attestation verification failed": the supplied `output`/`proofBytes` do not verify under `zkVerifier` and `zkCoprocessor`.
- Updates/removals revert with permission errors: ensure you’re the recorded `agentOwners[agentId]`.


## Quick reference

- Address (Sepolia Testnet): `0xFcF136B76d4365Dcd06a00DC3Dc7CF835aE50ee5`
- Chain: Sepolia Testnet (84532). Public RPC example: https://sepolia.base.org
- Read first: `getAgentCount`, then `getAgentList`, then `getAgent(<id>)`.
- Ownership: `agentOwners(<id>)` shows the owner who can update/remove.

