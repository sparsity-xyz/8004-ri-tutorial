# Sparsity Trustless Agents Framework

<p align="center">🚀 Reference Implementation of TEE Registry in <a href="https://8004.org">ERC-8004</a></p>

## 📘 Overview

<a href="https://8004.org">ERC-8004</a> defines trustless agents in the Ethereum ecosystem. An important component in 8004 is the validation registry. Validation ensures the integrity of agents through economic-staking or TEE. This repo provides a tutorial on building 8004 agents using TEE on the Sparsity reference implementation. For a deep dive into the 8004 registry design, please see [this doc](https://docs.google.com/document/d/127pkxlBE0048N-MNsX66Ctz5dmRxHvaJRASAr01EVVc/edit?tab=t.0#heading=h.x6rb197jqjog).

## 🏗️ Architecture Overview

<img width="1273" height="525" alt="Screenshot 2025-10-16 at 2 00 21 AM" src="https://github.com/user-attachments/assets/81e1f1cb-a8a1-496d-9f35-8df096681fb0" />

Sparsity Trustless Agents Framework enables developers to build and deploy TEE agents that can be registered and validated on-chain. 

On-Chain TEE registry contract serves as the central point for registering and validating TEE agents. It stores information about registered agents, including their metadata, validation status, and associated ZK proofs.

Note that one field here is the `codeMeasurement`. It can be thought of as a hash of the agent's codebase. This needs to be published on-chain so that the agent user can use it to verify the integrity of the agent. To facilitate this, the agent developer must publish the agent code somewhere so that anyone in the world can deterministically reproduce the `codeMeasurement` from the source code. 

Currently, the smart contract is deployed on Base Sepolia. You can use our [TEE Agent Explorer](https://explorer.agents.sparsity.ai/) to explore registered agents.

Or you can explore the contract [here](https://sepolia.basescan.org/address/0x396540938a5867A383DAef4c80172190189f80fC) on-chain directly. See more details in [TEE Agent Registry Contract](docs/TEE_Agent_Registry.md).

## 🚀 Even Quicker Start with Claude Code

> **⚡ New!** Build and deploy your TEE agent in minutes using Claude Code's AI-powered workflow automation!

**Why use Claude Code?**
- 🤖 **AI-Guided Setup**: Claude walks you through each step with context-aware assistance
- 🔄 **Auto-Execution**: No manual copy-paste—Claude can run scripts directly in your environment
- 🛠️ **Smart Debugging**: Real-time error detection and fixes as you build
- 📝 **Interactive Documentation**: Ask questions about any step and get instant explanations

### 1. Fork & Clone
Fork this repo to your own GitHub account, then clone it to your local machine.

```bash
git clone https://github.com/[your-username]/8004-ri-tutorial --depth=1
cd 8004-ri-tutorial
```

### 2. Download email from Sparsity as .eml file

If you have applied for the Sparsity Lab Environment, you will receive an email with the necessary details to start your tutorial. Download that email as a `.eml` file to your local machine.

move .eml file to the cloned repo directory.

### 3. Ask Claude Code to build and deploy your agent

Prompt:

```
Hi Claude, I have cloned the Sparsity Trustless Agents Framework repo and have the lab environment email saved as `lab_environment.eml` in the repo directory.
Please guide me through the steps to set up my environment, build my TEE agent, request a ZK proof, and register it on Base Sepolia.
You can refer to the README.md file in the repo for detailed instructions.
```

**Prefer the full manual tutorial?** Continue to the [detailed Quick Start](#quick-start) below for step-by-step instructions.

## ⚡ Quick Start

This tutorial will guide you through the complete process of building, deploying, and registering a TEE (Trusted Execution Environment) agent on the ERC-8004 registry.

### What You'll Get

By the end of this tutorial, you will have:
- ✅ A TEE agent running inside an AWS Nitro Enclave
- ✅ A ZK proof verifying your agent runs in a genuine TEE
- ✅ Your agent registered on-chain on Base Sepolia
- ✅ Cryptographically signed responses from your agent
- ✅ A unique Agent ID that others can use to verify your agent

### Tutorial Steps

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

For participants in "Sparsity Workshop", you can apply for a lab environment by submitting this form:

- Lab environment application: https://tinyurl.com/sparsity-8004-lab

You will receive an email with the necessary details to start your tutorial shortly.

**Build your own AWS Nitro Enclave environment**

You can also setup your own AWS Nitro Enclaves environment. Please see [AWS_Nitro_Enclave_Runtime.md](docs/AWS_Nitro_Enclave_Runtime.md) for details.


### 1. Fork & Clone

Fork this repo to your own GitHub account, then clone it to your local machine.

```bash
git clone https://github.com/[your-username]/8004-ri-tutorial --depth=1
cd 8004-ri-tutorial
```

**Note:** Replace `[your-username]` with your actual GitHub username.

### 2. Edit .env for Nitro Enclave Runtime and Base Sepolia Setup

```bash
cp .env.example .env
nano .env
```

Please fill in the required values in `.env` as described in the file. The key variables you need to configure are:

- `EC2_HOST`: Your EC2 instance public IP address
- `EC2_PEM_KEY`: Path to your SSH private key file (e.g., `~/.ssh/your-key.pem`)
- `EC2_USER`: SSH username (typically `ec2-user` for Amazon Linux)
- `ETH_ADDRESS`: Your Ethereum wallet address on Base Sepolia
- `PRIVATE_KEY`: Your Ethereum wallet private key (keep this secure!)

If you have submitted the lab environment application form, you will receive these details via email.

### 3. Edit Agent Code

You need to change `src/agent.json` to customize your agent, so that your agent can be identified on-chain.

```json
{
  "name": "[Your Agent Name]",
  "description": "[Your description here]",
  "code_repository": "https://github.com/[your-username]/8004-ri-tutorial",
}
```

You can also modify other files in the `src/` directory to implement your own agent logic.

NOTE: There is a "/chat" endpoint in the agent code that your agent can integrate with OpenAI. If you want to test this endpoint, make sure you have set up the OpenAI API key in your `src/.env` file (different from the main `.env` file).

```bash
cp src/.env.example src/.env
nano src/.env
```

### 4. Build & Deploy Your Agent

If you have modified the agent code, please make sure you have tested locally with Docker first.

```bash
./scripts/build-and-deploy-local.sh
```

After local testing, deploy your agent to the EC2 Nitro Enclave by running:

```bash
./scripts/build-and-deploy-remote.sh
```

This script will:
1. Terminate any existing enclaves
2. Copy your source code to the EC2 instance
3. Build the Docker image
4. Create the Enclave Image File (EIF)
5. Start the host proxy
6. Launch the enclave

If everything goes well, you should see output like below:

```
...
==> Running enclave in debug mode
Start allocating memory...
Started enclave with enclave-cid: 16, memory: 4096 MiB, cpu-ids: [1, 3]
{
  "EnclaveName": "demo-agent",
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

Now you can test your agent!

```bash
# Replace with your actual EC2 public IP (same as EC2_HOST in .env)
export AGENT_URL=[your-ec2-public-ip]

# Test the agent metadata endpoint
curl -s http://$AGENT_URL/agent.json | jq

# Test the add_two endpoint (should return {"sig":"...", "data":"4"})
curl -X POST http://$AGENT_URL/add_two \
    -H "Content-Type: application/json" \
    -d '{"a": 2, "b": 2}'

# Test the hello_world endpoint
curl -s http://$AGENT_URL/hello_world | jq

# (Optional) Test the chat endpoint - requires OpenAI API key in src/.env
curl -X POST http://$AGENT_URL/chat \
    -H "Content-Type: application/json" \
    -d '{"prompt": "What is 2+2?"}'
```

**Expected response format:**
All computational endpoints return JSON with two fields:
- `sig`: A cryptographic signature proving the response came from your TEE agent
- `data`: The actual result of the computation

Example:
```json
{
  "sig": "8917658a56488c11e41f46407ef43552623f592a2c7269f60203e3f604488f1d...",
  "data": "4"
}
```


### 5. Request ZK Proof of Your Agent

After successful deployment and testing, you can request a ZK proof of your agent. This proof cryptographically verifies that your agent is running in a genuine AWS Nitro Enclave.

```bash
./scripts/attest-and-prove.sh
```

**What this script does:**
1. Downloads the attestation document from your running enclave
2. Uploads it to the Succinct ZK proof generation service
3. Polls the service until the proof is ready (typically 60-70 seconds)
4. Saves the proof file locally with a timestamp

The proof file will be saved in the current directory. If successful, you should see output like below:

```
...
[INFO] [40s] Processing (HTTP 202)
[INFO] Request Succinct Explorer URL: https://explorer.mainnet.succinct.xyz/request/0x3618c37e...
[OK] Proof ready (elapsed 65s)
[OK] Saved proof to proof_c929d31acdd3cf31_20251010041858969.json
[OK] Proof file structure validated

==> Summary
[INFO] Directory: c929d31acdd3cf31_20251010041858969
[INFO] Elapsed: 65s
[INFO] Output: proof_c929d31acdd3cf31_20251010041858969.json
[NEXT] Next: ./scripts/validate-and-register-agent.sh --proof-path proof_c929d31acdd3cf31_20251010041858969.json
```

**Note:** You can track the proof generation progress on the Succinct Explorer using the URL shown in the output.

### 6. Register & Validate Your Agent

Now we'll register your agent on the Base Sepolia blockchain using the ZK proof you just generated. This proof verifies that your agent is running in a genuine TEE environment.

**Important:** Copy the exact command from the previous step's output (the `[NEXT]` line), or run:

```bash
./scripts/validate-and-register-agent.sh --proof-path [proof_generated_from_previous_step.json]
```

NOTE: you can just copy the command from the output of the previous step.

**What this script does:**
1. Validates the proof file structure
2. Extracts TEE measurements and public keys
3. Submits a blockchain transaction to register your agent
4. Returns your unique Agent ID

You should see output like below:

```
[OK] Agent registered (no AgentModified event parsed)
[WARN] Could not extract agent ID from transaction logs
==> Summary
[INFO] Elapsed: 1s
[INFO] Registry: 0x396540938a5867A383DAef4c80172190189f80fC
[INFO] Agent URL: https://lottery.zfdang.com
[INFO] Proof: proof_c929d31acdd3cf31_20251023031608055.json
[INFO] Next: Update agent metadata / publish discovery record if required
==> Explorer references
[NEXT] Contract:    https://sepolia.basescan.org/address/0x396540938a5867A383DAef4c80172190189f80fC
[NEXT] Identity Contract:    https://sepolia.basescan.org/address/0x8004AA63c570c570eBF15376c0dB199918BFe9Fb
```

**Congratulations!** Your agent is now registered and validated on-chain!

**Save your Agent ID** - you'll need it to verify signatures and for others to interact with your agent.

### 7. Explore Agents

We provide multiple ways to explore registered agents & play with them:

1. **TEE Agent Explorer**: Browse all registered TEE agents at [https://explorer.agents.sparsity.ai/](https://explorer.agents.sparsity.ai/)
2. **Base Sepolia Block Explorer**: View the registry contract directly at [https://sepolia.basescan.org/address/0x396540938a5867A383DAef4c80172190189f80fC](https://sepolia.basescan.org/address/0x396540938a5867A383DAef4c80172190189f80fC). See help in [TEE Agent Registry Contract](docs/TEE_Agent_Registry.md)

## 🔧 Troubleshooting

### SSH connection issues

If deployment fails with SSH errors:

1. **Check PEM key permissions**:
   ```bash
   chmod 400 ~/.ssh/your-key.pem
   ```

2. **Verify EC2 instance is running**: Check AWS console or run:
   ```bash
   ssh -i $EC2_PEM_KEY $EC2_USER@$EC2_HOST "echo 'Connected successfully'"
   ```

3. **Check .env variables**: Ensure `EC2_HOST`, `EC2_USER`, and `EC2_PEM_KEY` are correctly set

### Need Base Sepolia testnet ETH?

Get free testnet ETH from Base Sepolia faucets:
- [Base Sepolia Faucet](https://www.coinbase.com/faucets/base-ethereum-sepolia-faucet)
- Or bridge from Ethereum Sepolia using [Base Bridge](https://bridge.base.org/)

## 🧩 More about Sparsity Solution

Sparsity's layered approach enables developers to quickly build, certify, and deploy secure TEE applications with minimal friction, leveraging both AWS Nitro Enclaves and advanced compliance and hosting solutions.

In this tutorial, we have covered the first two layers: building TEE agents with enclave-toolkit and validating them with trustless-agent-framework.

If you want to know more about Sparsity's offerings, see [Sparsity Offerings](Sparsity_Offerings.md) for details.

## 🛟 Support

If you run into issues or have questions, here are the best ways to reach us:

- Discord: join our community and ask in the support channel — https://discord.gg/6vrFdpnFvm
- Email: send detailed issues to support@sparsity.xyz (include repo, branch, steps to reproduce, and any logs)
- X (Twitter): mention @sparsity_xyz for short questions or announcements
- GitHub: open an issue in this repository with the bug or feature request — include reproduction steps and relevant logs

When opening an issue or contacting support, please include:

1. The command you ran and the expected vs actual result
2. Environment details (OS, Docker/Nitro versions, AWS region)
3. Relevant log excerpts or error messages

We aim to respond within 48 hours for community channels and email depending on volume.

## ⚖️ License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

---

<div align="center">
**⭐ Star this repo if you find it useful! ⭐**

Made with ❤️ by the Sparsity team
</div>
