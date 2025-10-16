# Sparsity Trustless Agents Framework

<p align="center">🚀 Reference Implementation of TEE Registry in <a href="https://8004.org">ERC-8004</a></p>

## Overview

<a href="https://8004.org">ERC-8004</a> defines trustless agents in the Ethereum ecosystem. An important component in 8004 is the validation registry. Validation ensures the integrity of agents through economic-staking or TEE. This repo provides a tutorial on building 8004 agents using TEE on the Sparsity reference implementation. For a deep dive into the 8004 registry design, please see [this doc](https://docs.google.com/document/d/127pkxlBE0048N-MNsX66Ctz5dmRxHvaJRASAr01EVVc/edit?tab=t.0#heading=h.x6rb197jqjog).

## Architecture Overview

<img width="944" height="417" alt="Screenshot 2025-10-09 at 1 28 55 AM" src="https://github.com/user-attachments/assets/9058a6aa-ed9a-408f-8802-672e40ed43cf" />

Sparsity Trustless Agents Framework enables developers to build and deploy TEE agents that can be registered and validated on-chain. 

On-Chain TEE registry contract serves as the central point for registering and validating TEE agents. It stores information about registered agents, including their metadata, validation status, and associated ZK proofs.

Note that one field here is the `codeMeasurement`. It can be thought of as a hash of the agent's codebase. This needs to be published on-chain so that the agent user can use it to verify the integrity of the agent. To facilitate this, the agent developer must publish the agent code somewhere so that any one in the world can deterministically reproduce the `codeMeasurement` from the source code. 

Currently, the smart contract is deployed on Base Sepolia. You can also use our [TEE Agent Explorer](http://18.144.124.66:8080/) to explore registered agents.

Or you can explore the contract [here](https://sepolia.basescan.org/address/0x10252e516E5eD6013c5bf4233f39A3dF6FA2d076) on-chain directly. See more details in [TEE_Registry_Smart_Contract.md](docs/TEE_Registry_Smart_Contract.md).

## Quick start

The simplest way to get started is to build your agent from our reference implementation. You can follow the steps below to build, deploy, validate, and register your own TEE agent.

  - [0. Pre-requisites: AWS Nitro Enclaves Environment](#0-pre-requisites-aws-nitro-enclaves-environment)
  - [1. Fork & Clone](#1-fork--clone)
  - [2. Edit .env for Nitro Enclave Runtime and Base Sepolia Setup](#2-edit-env-for-nitro-enclave-runtime-and-base-sepolia-setup)
  - [3. Edit Agent Code](#3-edit-agent-code)
  - [4. Build & Deploy Your Agent](#4-build--deploy-your-agent)
  - [5. Request ZK Proof of Your Agent](#5-request-zk-proof-of-your-agent)
  - [6. Register & Validate Your Agent](#6-register--validate-your-agent)
  - [7. Explore Agents](#7-explore-agents)

### 0. Pre-requisites: AWS Nitro Enclaves Environment

Before using Sparsity's offerings, ensure you have an AWS Nitro Enclaves environment set up. The easiest way is to apply for our free lab environment.

**Sparsity Lab Environment**

For participants in "BuildETH 2025", you can apply for a lab environment by submitting this form:

- Lab environment application: https://tinyurl.com/sparsity-8004-lab

You will receive an email with the necessary details to start your tutorial shortly.

**Build your own aws nitro enclave environment**

You can also setup your own AWS Nitro Enclaves environment. Please see [AWS_Nitro_Enclave_Runtime.md](docs/AWS_Nitro_Enclave_Runtime.md) for details.


### 1. Fork & Clone

Fork this repo to your own GitHub account, then clone it to your local machine.

```
git clone https://github.com/[your-username]/sparsity-trustless-agents-framework.git --depth=1
```

### 2. Edit .env for Nitro Enclave Runtime and Base Sepolia Setup

```
cd sparsity-trustless-agents-framework
cp .env.example .env
nano .env
```

Please fill in the required values in `.env` as described in the file. 

If you have submitted the lab environment application form, you will receive the necessary details via email.

### 3. Edit Agent Code

You are encouraged to modify `src/agent.json` to customize your agent's metadata. 

You can also modify other files in the `src/` directory to implement your own agent logic.

NOTE: There is one "/chat" endpoint in the agent code that your agent can integrate with OpenAI. If you want to test this endpoint, make sure you have set up the OpenAI API key in your `src/.env` file (different from the main `.env` file).

```
cp src/.env.example src/.env
nano src/.env
```

### 4. Build & Deploy Your Agent

If you have modified the agent code, please make sure you have tested locally with Docker first.

```
./scripts/deploy-local.sh
```

After that, you can deploy your agent to the EC2 Nitro Enclave by running:

```
./scripts/deploy-remote.sh
```
If everything goes well, you should see output like below:

```
...
==> Running enclave in debug mode
Start allocating memory...
Started enclave with enclave-cid: 16, memory: 4096 MiB, cpu-ids: [1, 3]
{
  "EnclaveName": "test-app",
  "EnclaveID": "i-0f881432b6288ad0f-enc199cc4a57a29c28",
  "ProcessID": 28667,
  "EnclaveCID": 16,
  "NumberOfCPUs": 2,
  "CPUIDs": [
    1,
    3
  ],
  "MemoryMiB": 4096
}
[OK] Enclave launch command executed
==> Generating curl command for enclave API (/agent.json)
[INFO] You can invoke the enclave endpoint with:
  curl -s http://[EC2_HOST]/agent.json | jq
[OK] Deployment workflow completed
```

Then you can play with your agent!

```
export AGENT_URL=[your-ec2-public-ip]

curl -s http://$AGENT_URL/agent.json | jq

curl -X POST http://$AGENT_URL/add_two \
    -H "Content-Type: application/json" \
    -d '{"a": 2, "b": 2}'

# requires OpenAI API key set in /src/.env before build and deploy
curl -X POST http://$AGENT_URL/chat \
    -H "Content-Type: application/json" \
    -d '{"prompt": "What is 2+2?"}'

```
### 5. Request ZK Proof of Your Agent

After deployment, you can request a ZK proof of your agent by running:

```
./scripts/request-proof.sh
```

It will take around 60 seconds to generate the ZK proof. The proof file will be saved in the ./scripts/ directory. If successful, you should see output like below:

```
...
[OK] Proof ready (elapsed 65s)
[OK] Saved proof to proof_c929d31acdd3cf31_20251010041858969.json
[OK] Proof file structure validated

==> Summary
[INFO] Directory: c929d31acdd3cf31_20251010041858969
[INFO] Elapsed: 65s
[INFO] Output: proof_c929d31acdd3cf31_20251010041858969.json
[NEXT] Next: ./scripts/validate-agent.sh --proof-path proof_c929d31acdd3cf31_20251010041858969.json 
```

### 6. Register & Validate Your Agent

We use the generated proof file to register and validate your agent on-chain. Run:

```
./scripts/validate-agent.sh --proof-path proof_generated_from_previous_step.json
```

NOTE: you can just copy the command from the output of the previous step.

You should see output like below:

```
[OK] Agent validated successfully
[INFO] Agent ID (uint256): 25
[INFO] Agent ID (hex): 0x0000000000000000000000000000000000000000000000000000000000000019
==> Summary
[INFO] Elapsed: 1s
[INFO] Registry: 0x10252e516E5eD6013c5bf4233f39A3dF6FA2d076
[INFO] Agent URL: 3.101.88.86
[INFO] Proof: proof_c929d31acdd3cf31_20251010041858969.json
[INFO] Next: Update agent metadata / publish discovery record if required
==> Explorer references
[NEXT] Contract:    https://sepolia.basescan.org/address/0x10252e516E5eD6013c5bf4233f39A3dF6FA2d076
[NEXT] Transactions:https://sepolia.basescan.org/address/0x10252e516E5eD6013c5bf4233f39A3dF6FA2d076#transactions
[NEXT] Events:      https://sepolia.basescan.org/address/0x10252e516E5eD6013c5bf4233f39A3dF6FA2d076#events
[NEXT] Read:        https://sepolia.basescan.org/address/0x10252e516E5eD6013c5bf4233f39A3dF6FA2d076#readContract
[NEXT] Search logs for Agent ID topic: 0000000000000000000000000000000000000000000000000000000000000019
[NEXT] Agent ID (uint256): 25
```

Now your agent is registered and validated on-chain! 

### 7. Explore Agents

We provide multiple ways to explore registered agents.
1. Using our [TEE Agent Explorer](http://18.144.124.66:8080/)
2. Explore the smart contract directly on Base Sepolia, see [Base Sepolia Explorer](https://sepolia.basescan.org/address/0x10252e516E5eD6013c5bf4233f39A3dF6FA2d076).
3. Using the script to explore agents from command line.

List all agents:

```
./scripts/explore-agents.sh
```

Or get details of your agent:

```
./scripts/explore-agents.sh --agent-id <your_agent_id>
```

### 8. Submit your agent to Sparsity for listing

If you want your agent to be highlighted on Sparsity's official explorer, please submit the following details to us via email (support@sparsity.xyz):

1. Agent Name
2. Agent Description
3. Agent ID
4. Link to the Agent's Code Repository
5. Any additional information you think is relevant


## More about Sparsity Solution

Sparsity's layered approach enables developers to quickly build, certify, and deploy secure TEE applications with minimal friction, leveraging both AWS Nitro Enclaves and advanced compliance and hosting solutions.

In this tutorial, we have covered the first two layers: building TEE agents with enclave-toolkit and validating them with trustless-agent-framework.

If you want to know more about Sparsity's offerings, see [Sparsity Offerings](Sparsity_Offerings.md) for details.

## Support

If you run into issues or have questions, here are the best ways to reach us:

- Discord: join our community and ask in the support channel — https://discord.gg/HCnFr7M3
- Email: send detailed issues to support@sparsity.xyz (include repo, branch, steps to reproduce, and any logs)
- X (Twitter): mention @sparsity_xyz for short questions or announcements
- GitHub: open an issue in this repository with the bug or feature request — include reproduction steps and relevant logs

When opening an issue or contacting support, please include:

1. The command you ran and the expected vs actual result
2. Environment details (OS, Docker/Nitro versions, AWS region)
3. Relevant log excerpts or error messages

We aim to respond within 48 hours for community channels and email depending on volume.
