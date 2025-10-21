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

Or you can explore the contract [here](https://sepolia.basescan.org/address/0xe718aec274E36781F18F42C363A3B516a4427637) on-chain directly. See more details in [TEE Agent Registry Contract](docs/TEE_Agent_Registry.md).

## ⚡ Quick Start

This tutorial will guide you through the complete process of building, deploying, and registering a TEE (Trusted Execution Environment) agent on the ERC-8004 registry.

### What You'll Build

By the end of this tutorial, you will have:
- ✅ A TEE agent running inside an AWS Nitro Enclave
- ✅ A ZK proof verifying your agent runs in a genuine TEE
- ✅ Your agent registered on-chain on Base Sepolia
- ✅ Cryptographically signed responses from your agent
- ✅ A unique Agent ID that others can use to verify your agent

### Prerequisites

- Access to an AWS Nitro Enclave environment (apply at https://tinyurl.com/sparsity-8004-lab)
- Basic familiarity with command line, Docker, and Git
- A Base Sepolia wallet with some testnet ETH for gas fees

### Time Required

- **Total**: ~15-20 minutes
- Setup and deployment: 5 minutes
- ZK proof generation: ~65 seconds
- On-chain registration: ~2 seconds
- Testing and verification: 5 minutes

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

**Important:** Ensure your PEM key file has correct permissions:
```bash
chmod 400 ~/.ssh/your-key.pem
```

**Note on SSH host verification:** When you first connect to your EC2 instance, SSH may prompt you to verify the host fingerprint and add it to known_hosts. If the deployment script hangs or prompts for input, you can pre-add the host to your known_hosts file:
```bash
ssh-keyscan -H $EC2_HOST >> ~/.ssh/known_hosts
```
Or connect manually once first:
```bash
ssh -i $EC2_PEM_KEY $EC2_USER@$EC2_HOST
# Type 'yes' when prompted, then exit
```

### 3. Edit Agent Code

You need to change `src/agent.json` to customize your agent, so that your agent can be identified on-chain.

```json
{
  "name": "[Your Agent Name]",
  "description": "[Your description here]",
  "code_repository": "https://github.com/[your-username]/sparsity-trustless-agents-framework",
}
```

You can also modify other files in the `src/` directory to implement your own agent logic.

NOTE: There is a "/chat" endpoint in the agent code that your agent can integrate with OpenAI. If you want to test this endpoint, make sure you have set up the OpenAI API key in your `src/.env` file (different from the main `.env` file).

```bash
cp src/.env.example src/.env
nano src/.env
```

### 4. Build & Deploy Your Agent

**Note:** Local Docker testing with `./scripts/build-and-deploy-local.sh` is currently under maintenance. You can proceed directly to remote deployment.

Deploy your agent to the EC2 Nitro Enclave by running:

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

**Important:** Wait 10-15 seconds after deployment completes for the enclave to fully start up before testing endpoints.

Now you can test your agent!

```bash
# Replace with your actual EC2 public IP (same as EC2_HOST in .env)
export AGENT_URL=54.180.244.54

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
./scripts/validate-and-register-agent.sh --proof-path proof_c929d31acdd3cf31_20251010041858969.json
```

Replace the proof filename with your actual proof file name.

**What this script does:**
1. Validates the proof file structure
2. Extracts TEE measurements and public keys
3. Submits a blockchain transaction to register your agent
4. Returns your unique Agent ID

You should see output like below:

```
==> Sending registerAgent transaction
[OK] Transaction submitted
{
  "transactionHash": "0xba702163a283a243fbdf66237e152ade21f78a61199c6270914d73cec59bb7c0",
  ...
}
[OK] Agent registered successfully
[INFO] Agent ID (uint256): 25
[INFO] Agent ID (hex): 0x0000000000000000000000000000000000000000000000000000000000000019
==> Summary
[INFO] Elapsed: 2s
[INFO] Registry: 0xe718aec274E36781F18F42C363A3B516a4427637
[INFO] Agent URL: 3.101.88.86
[INFO] Proof: proof_c929d31acdd3cf31_20251010041858969.json
==> Explorer references
[NEXT] Contract:    https://sepolia.basescan.org/address/0xe718aec274E36781F18F42C363A3B516a4427637
[NEXT] Agent ID (uint256): 25
```

**Congratulations!** Your agent is now registered and validated on-chain!

**Save your Agent ID** - you'll need it to verify signatures and for others to interact with your agent.

#### Verify Agent Signatures

Now you can verify that responses from your agent are cryptographically signed by the registered TEE agent. First, set up the Python verification environment:

```bash
# Activate the virtual environment
source .venv/bin/activate

# Install verification dependencies
pip install -r ./scripts/verifier/requirements.txt
```

Then verify agent signatures:

```bash
# Set your agent ID (replace with your actual ID from the previous step)
export AGENT_ID=25

# Verify the hello_world endpoint
python3 ./scripts/verifier/verify.py --agent-id=$AGENT_ID --url-path=/hello_world

# Verify the add_two endpoint with POST data
python3 ./scripts/verifier/verify.py --agent-id=$AGENT_ID --url-path=/add_two --data='{"a": 1, "b": 2}'
```

**Expected output:**
```
----------------------------------------------------------------------
➤ TEE Agent Verification
----------------------------------------------------------------------
➤ Step 1/3: Query agent on-chain
✓ Agent loaded from chain

➤ Step 2/3: Query agent endpoint
✓ Agent responded with JSON

➤ Step 3/3: Verify signature
✓ Signature verified (0xB2c3fe983f3cAb06B766bFF53DD1Db7Ac4d2A8e9)
```

The verification script:
1. Fetches your agent's public key from the on-chain registry
2. Calls your agent endpoint and gets the signed response
3. Cryptographically verifies that the signature matches the registered agent

### 7. Explore Agents

We provide multiple ways to explore registered agents:

1. **TEE Agent Explorer**: Browse all registered agents at [http://18.144.124.66:8080/](http://18.144.124.66:8080/)
2. **Base Sepolia Block Explorer**: View the registry contract directly at [https://sepolia.basescan.org/address/0xe718aec274E36781F18F42C363A3B516a4427637](https://sepolia.basescan.org/address/0xe718aec274E36781F18F42C363A3B516a4427637)
3. **Contract Documentation**: See [TEE Agent Registry Contract](docs/TEE_Agent_Registry.md) for detailed contract interaction instructions

## 🔧 Troubleshooting

### Agent endpoint not responding

If `curl http://$AGENT_URL/agent.json` fails or times out:

1. **Wait longer**: The enclave needs 10-15 seconds to start after deployment
2. **Check enclave is running**: SSH into your EC2 instance and run:
   ```bash
   nitro-cli describe-enclaves
   ```
   You should see an active enclave with status information.

3. **Check host proxy logs**: On the EC2 instance:
   ```bash
   tail -f ~/host.log
   ```

4. **Redeploy if needed**: Sometimes redeploying helps:
   ```bash
   ./scripts/build-and-deploy-remote.sh
   ```

### Python virtual environment issues

If you get `ModuleNotFoundError` when running the verifier:

```bash
# Make sure you're in the project root directory
cd /path/to/8004-ri-tutorial

# Activate the virtual environment
source .venv/bin/activate

# Verify activation (should show .venv path)
which python3

# Install dependencies
pip install -r ./scripts/verifier/requirements.txt
```

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

### Proof generation timeout

If `./scripts/attest-and-prove.sh` times out:

1. **Check agent is accessible**: Ensure `http://$EC2_HOST/attestation/download` returns data
2. **Increase timeout**: Run with custom timeout:
   ```bash
   ./scripts/attest-and-prove.sh --timeout 300
   ```
3. **Check Succinct service**: The ZK proof service might be experiencing high load

### Transaction fails during registration

If the blockchain transaction fails:

1. **Check ETH balance**: Ensure your wallet has enough Base Sepolia ETH for gas
2. **Verify PRIVATE_KEY format**: Should be a 64-character hex string (without 0x prefix in .env)
3. **Check RPC endpoint**: Verify `https://sepolia.base.org` is accessible

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
