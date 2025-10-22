# Claude Code Tutorial Guide: ERC-8004 TEE Agent Development

This tutorial guides Claude Code through the complete process of building, deploying, and registering a Trusted Execution Environment (TEE) agent on the ERC-8004 registry.

## Overview

This repository provides a reference implementation for building ERC-8004 compliant TEE agents using AWS Nitro Enclaves. By completing this tutorial, you will:

- Deploy a TEE agent inside an AWS Nitro Enclave
- Generate a ZK proof verifying the agent runs in a genuine TEE
- Register the agent on-chain on Base Sepolia
- Test cryptographically signed responses from the agent
- Obtain a unique Agent ID for on-chain verification

## Prerequisites

Before starting this tutorial, ensure you have:

1. **AWS Nitro Enclave Environment**: Access credentials (EC2_HOST, EC2_PEM_KEY, EC2_USER)
2. **Base Sepolia Wallet**: Ethereum address and private key with testnet ETH
3. **Environment Configuration**: A properly configured `.env` file
4. **GitHub Account**: For forking and customizing the agent repository

## 🤖 Instructions for Claude Code

This tutorial is designed to be executed by Claude Code with user interaction at key points. Follow these critical guidelines:

### Key Principles

1. **Data Capture and State Management**: Extract and store critical values throughout the tutorial:
   - **PEM filename** from email (e.g., `0x1d0531Fc8a495409C928db7CF17ca7608b3467BF.pem`)
   - **EC2_HOST** (IP address) from email (e.g., `54.180.105.144`)
   - **ETH_ADDRESS** from email (e.g., `0x1d0531Fc8a495409C928db7CF17ca7608b3467BF`)
   - **PROOF_FILE** from Step 5 output (e.g., `proof_ac75ca763c4747be_20251022024237623.json`)
   - **AGENT_ID** from Step 6 output (e.g., `28`)

   **Recommended approach**: Store these in shell variables and optionally in a `.env.temp` file:
   ```bash
   echo "PROOF_FILE=$PROOF_FILE" >> .env.temp
   echo "AGENT_ID=$AGENT_ID" >> .env.temp
   source .env.temp  # To reload in new commands
   ```

2. **User Engagement**: Prompt users to manually edit configuration files (Step 1 & 2) rather than doing it automatically

3. **Wait Points**: Always wait for user confirmation before proceeding after:
   - Creating `.env` file (user must add private key)
   - Showing `agent.json` (user should customize it)

4. **Timing**: Respect wait times (15 seconds after deployment) to avoid errors

5. **Verification**: Verify files exist before using them:
   ```bash
   [ -f "$PROOF_FILE" ] && echo "Found" || echo "ERROR: File not found"
   ```

6. **Error Prevention**: Check prerequisites before each step (e.g., private key before Step 6)

### Critical Checkpoints
- ⚠️ **Step 0**: FIRST verify user has downloaded email file to base directory
- ⚠️ **Step 1**: Stop after creating `.env` - wait for user to add PRIVATE_KEY
- ⚠️ **Step 2**: Don't auto-edit `agent.json` - prompt user to customize it
- ⚠️ **Step 3**: Wait 15 seconds after deployment completes
- ⚠️ **Step 5**: Capture the exact proof filename for Step 6
- ⚠️ **Step 6**: Verify private key exists before registration
- ⚠️ **Step 7**: Use the Agent ID captured from Step 6

---

## Tutorial Workflow

### Step 0: Download Email File (USER ACTION REQUIRED)

**⚠️ CRITICAL - User Action Required BEFORE Starting**

Before Claude Code can begin the tutorial, you must:

1. **Locate the email** containing your AWS EC2 access credentials
   - This email was sent after you applied for the lab environment
   - Subject line typically contains "AWS EC2 Access" or similar
   - Contains EC2 instance IP address and SSH private key (PEM file)

2. **Download the email file** to this repository's base directory:
   - Save the email as a `.eml` file (e.g., `aws-credentials.eml`)
   - Place it in: `/home/yl/Desktop/work/8004-ri-tutorial/`
   - The file should be in the same directory as this README

3. **Verify the email is in the correct location**:
   ```bash
   ls -la *.eml
   ```
   You should see your email file listed.

**Once the email file is downloaded, tell Claude Code to proceed with Step 1.**

---

### Step 1: Environment Setup

**Action**: Extract PEM key from email and verify environment configuration

**Step 1a: Download and Decode PEM Key**

**⚠️ Action for Claude Code**: FIRST check that the user has downloaded the email file:

```bash
# Check for email file in base directory
ls -la *.eml
```

If no email file is found, **STOP** and prompt the user to complete Step 0 first.

**Action for Claude Code**: Decode the email to extract the PEM key file:

The email contains a base64-encoded PEM key file as an attachment. Extract it using this exact method:

**Step 1: Identify the PEM filename from the email**
```bash
# Read the email to find the PEM filename
# It will be in a line like: filename="0x1d0531Fc8a495409C928db7CF17ca7608b3467BF.pem"
grep 'filename.*\.pem' *.eml
```

**Step 2: Identify the email filename**
```bash
# Get the actual email filename (don't assume the name)
EMAIL_FILE=$(ls *.eml)
echo "Email file: $EMAIL_FILE"
```

**Step 3: Extract the base64-encoded PEM key**
```bash
# The base64 content is typically at lines 122-151 in the Sparsity welcome email
# This command works for the standard Sparsity email format
sed -n '122,151p' "$EMAIL_FILE" | tr -d '\r\n' | base64 -d > [PEM_FILENAME].pem

# Example with actual filename:
# sed -n '122,151p' "welcome to sparsity.eml" | tr -d '\r\n' | base64 -d > 0x1d0531Fc8a495409C928db7CF17ca7608b3467BF.pem
```

**Step 4: Set correct permissions**
```bash
chmod 400 [PEM_FILENAME].pem
```

**Step 5: Verify the extraction was successful**
```bash
# Check file was created and has content
ls -la [PEM_FILENAME].pem

# Verify it starts with the correct header
head -1 [PEM_FILENAME].pem  # Should show "-----BEGIN RSA PRIVATE KEY-----"

# Check file size (should be around 1674 bytes)
wc -c [PEM_FILENAME].pem
```

**Troubleshooting PEM Extraction**:
- If the file is created but empty (0 bytes), the line numbers may be wrong for your email format
- To find the correct line numbers, search for the base64 content:
  ```bash
  grep -n "Content-Transfer-Encoding: base64" *.eml
  # The base64 content starts a few lines after this
  # Look for lines that are all uppercase/lowercase letters, numbers, +, /, and =
  ```
- If extraction still fails, you can manually extract:
  1. Open the email file in a text editor
  2. Find the section after "Content-Transfer-Encoding: base64"
  3. Copy all the base64 lines (between the headers and the boundary marker)
  4. Save to a file and decode: `base64 -d < base64_content.txt > [PEM_FILENAME].pem`

**Note**: If you have a different email format, you may need to adjust the line numbers (122,151).

**IMPORTANT**:
- Save the PEM key in the **project directory**, NOT in `~/.ssh/`
- The PEM filename will be specified in the email (e.g., `0x1d0531Fc8a495409C928db7CF17ca7608b3467BF.pem`)
- Permissions must be `400` (read-only for owner) for SSH to accept the key

**Expected Result**: A `.pem` file extracted to the project directory with `400` permissions.

**Step 1b: Configure Environment Variables**

**Action for Claude Code**: Create a `.env` file based on `.env.example` and populate it with the information extracted from the email.

**Step 1: Extract information from email**
```bash
# Extract EC2 IP address from email
# Look for pattern like "IP Address: 54.180.105.144"
grep -i "IP Address" *.eml | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}'

# Or search for the IP in the SSH connection command
grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' *.eml | head -1

# Extract Ethereum address (it's in the greeting and filename)
# Look for pattern like "Hi 0x1d0531Fc8a495409C928db7CF17ca7608b3467BF"
grep -oE '0x[a-fA-F0-9]{40}' *.eml | head -1
```

**Step 2: Create .env file**
```bash
cp .env.example .env
```

**Step 3: Populate .env with extracted values**

Update the following variables in `.env`:
- `EC2_HOST`: EC2 instance public IP address (extracted from email, e.g., `54.180.105.144`)
- `EC2_PEM_KEY`: **Relative path** to extracted SSH private key file in project directory (e.g., `./0x1d0531Fc8a495409C928db7CF17ca7608b3467BF.pem`)
- `EC2_USER`: SSH username (always `ec2-user` for AWS)
- `ETH_ADDRESS`: Ethereum wallet address on Base Sepolia (extracted from email, the 0x address)
- `PRIVATE_KEY`: Set to placeholder `YOUR_PRIVATE_KEY_HERE_64_HEX_CHARS_NO_0x_PREFIX` (user will add this later)

**⚠️ CRITICAL - Action for Claude Code**:
After creating the `.env` file, you MUST:
1. **STOP** before proceeding to Step 2
2. **Prompt the user** to manually add their Base Sepolia PRIVATE_KEY to the `.env` file
3. Inform the user that the private key must be **64 hexadecimal characters without the 0x prefix**
4. Wait for user confirmation before continuing

**Example Private Key Format**:
```bash
# ✅ CORRECT (64 hex chars, no 0x)
export PRIVATE_KEY='a1b2c3d4e5f6...64_hex_characters_total'

# ❌ WRONG (has 0x prefix)
export PRIVATE_KEY='0xa1b2c3d4e5f6...'
```

**Step 4: Verify .env configuration**
```bash
# Source the .env file
source .env

# Verify all variables are set
echo "EC2_HOST: $EC2_HOST"
echo "EC2_PEM_KEY: $EC2_PEM_KEY"
echo "EC2_USER: $EC2_USER"
echo "ETH_ADDRESS: $ETH_ADDRESS"
echo "PRIVATE_KEY: $PRIVATE_KEY"

# Verify SSH key exists and has correct permissions
ls -la $EC2_PEM_KEY

# Test SSH connection
ssh -i $EC2_PEM_KEY -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST "echo 'SSH connection successful'"
```

**Expected Outcome**:
- All variables are displayed (PRIVATE_KEY will be placeholder)
- PEM file has `-r--------` permissions (400)
- SSH connection succeeds and prints "SSH connection successful"

**If SSH connection fails**:
1. Check PEM file permissions: `chmod 400 $EC2_PEM_KEY`
2. Verify EC2_HOST is correct IP address (no extra characters)
3. Verify EC2_PEM_KEY path is correct (starts with `./`)
4. Try manual SSH: `ssh -i ./[PEM_FILE] ec2-user@[IP_ADDRESS]`

**Troubleshooting**:
- If PEM file not found in email, check for attachments or base64-encoded content
- If SSH fails, verify PEM key permissions: `chmod 400 $EC2_PEM_KEY`
- If host verification prompts, add to known_hosts: `ssh-keyscan -H $EC2_HOST >> ~/.ssh/known_hosts`

---

### Step 2: Customize Agent Metadata

**⚠️ CRITICAL - Action for Claude Code**:
**DO NOT** automatically edit `src/agent.json`. Instead:

1. **Read** the current `src/agent.json` file to show the user what needs to be customized
2. **Prompt the user** to manually edit the file themselves for better engagement
3. Explain what fields need to be changed:
   - `name`: A unique agent name (e.g., "MyAwesomeAgent_2025")
   - `description`: Describe what your agent does
   - `code_repository`: Your GitHub repository URL (if you forked it)

**Example customization**:
```json
{
  "name": "MyTradingAgent_v1",
  "description": "AI-powered trading agent with real-time market analysis",
  "code_repository": "https://github.com/yourusername/8004-ri-tutorial"
}
```

**Guidelines for Users**:
- Choose a unique, descriptive name that identifies this agent
- Write a meaningful description of agent capabilities
- If you forked the repo, update `code_repository` with your GitHub URL
- Keep other fields unchanged (version, schema_version, tee_arch, etc.)

**Optional - Advanced Customization**:
Users can also customize `src/main.py` to add new endpoints or modify agent behavior. This is optional but encouraged for learning!

**Verification (for Claude Code)**:
After the user confirms they've edited the file:
```bash
cat src/agent.json | jq
```

**Expected Outcome**: Valid JSON with customized name, description, and optionally repository.

---

### Step 3: Build and Deploy Agent

**Action**: Deploy the agent to AWS Nitro Enclave

**Command**:
```bash
./scripts/build-and-deploy-remote.sh
```

**What This Does**:
1. Terminates any existing enclaves on the EC2 instance
2. Copies source code to the remote EC2 instance
3. Builds Docker image with agent code
4. Creates Enclave Image File (EIF) with code measurements
5. Starts the host proxy for external communication
6. Launches the enclave in the Nitro environment

**Expected Output**:
```
==> Running enclave in debug mode
Start allocating memory...
Started enclave with enclave-cid: 16, memory: 4096 MiB, cpu-ids: [1, 3]
{
  "EnclaveName": "demo-agent",
  "EnclaveID": "i-0f881432b6288ad0f-enc199cc4a57a29c28",
  "ProcessID": 28667,
  "EnclaveCID": 16,
  "NumberOfCPUs": 2,
  "CPUIDs": [1, 3],
  "MemoryMiB": 4096
}
[OK] Deployment workflow completed
```

**⚠️ CRITICAL - Action for Claude Code**:
After deployment completes:
1. **WAIT** for 15 seconds using `sleep 15` command
2. Explain to the user that this wait time is necessary for:
   - The enclave to fully initialize
   - The host proxy to establish connection
   - Internal services to start up
3. **DO NOT** proceed to Step 4 endpoint testing until the wait completes

**Why This Matters**: If you test endpoints too early, they will fail with "connection refused" errors, even though deployment was successful. The enclave needs time to boot up inside the TEE environment.

**Troubleshooting**:
- If deployment fails, check SSH connection and .env variables
- If enclave start fails, SSH into EC2 and check: `nitro-cli describe-enclaves`
- Check host proxy logs: `ssh -i $EC2_PEM_KEY $EC2_USER@$EC2_HOST "tail -f ~/host.log"`

---

### Step 4: Test Agent Endpoints

**Action**: Verify agent is responding correctly

**⚠️ IMPORTANT**: Use the direct IP address from .env. The EC2_HOST is typically the IP address (e.g., 54.180.105.144).

**Simple Method - Use direct IP from .env**:
Look at your .env file and find the EC2_HOST value, then use it directly in the curl commands.

**Test all agent endpoints**:
```bash
# Replace 54.180.105.144 with your actual EC2_HOST IP from .env

# Test agent metadata (no signature)
curl -s http://54.180.105.144/agent.json | jq

# Test hello_world endpoint (returns signed response)
curl -s http://54.180.105.144/hello_world | jq

# Test add_two endpoint with POST data (returns signed response)
curl -s -X POST http://54.180.105.144/add_two \
    -H "Content-Type: application/json" \
    -d '{"a": 2, "b": 2}' | jq
```

**Step 3: Verify response format**
```bash
# Check that hello_world returns both 'sig' and 'data' fields
curl -s http://$EC2_IP/hello_world | jq 'has("sig") and has("data")'
# Should output: true
```

**Expected Response Format**:
All computational endpoints return JSON with two fields:
```json
{
  "sig": "8917658a56488c11e41f46407ef43552623f592a2c7269f60203e3f604488f1d...",
  "data": "4"
}
```

**Verification**:
- `sig`: Cryptographic signature from the TEE agent
- `data`: Actual computation result

**Troubleshooting**:
- If connection times out, wait longer (enclave needs 10-15 seconds to start)
- If 404 errors, verify deployment completed successfully
- If no response, check enclave status: `ssh -i $EC2_PEM_KEY $EC2_USER@$EC2_HOST "nitro-cli describe-enclaves"`

---

### Step 5: Generate ZK Proof

**Action**: Request a Zero-Knowledge proof of TEE attestation

**Command**:
```bash
./scripts/attest-and-prove.sh
```

**What This Does**:
1. Downloads attestation document from running enclave
2. Uploads attestation to Succinct ZK proof generation service
3. Polls the service until proof is ready (typically 60-70 seconds)
4. Saves proof file locally with timestamp

**Expected Output**:
```
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

**⚠️ CRITICAL - Action for Claude Code**:
After the proof is generated, you MUST capture the proof filename for use in Step 6.

**Simple Method - Use the output directly**:

The script output will show a `[NEXT]` line with the exact command to run:
```
[NEXT] Next: ./scripts/validate-and-register-agent.sh --proof-path proof_c929d31acdd3cf31_20251010041858969.json
```

**Simply copy the filename from this line** (e.g., `proof_c929d31acdd3cf31_20251010041858969.json`) and use it directly in Step 6.

**Verification (optional)**:
```bash
# Use the filename from the [NEXT] line above
PROOF_FILE="proof_c929d31acdd3cf31_20251010041858969.json"  # Replace with actual filename

# Verify it exists and is valid JSON
ls -la "$PROOF_FILE"
jq -r 'keys[]' "$PROOF_FILE" | head -6
# Should show: onchain_proof, program_id, proof_type, raw_proof, zktype, zkvm_version
```

**Alternative - If you need to find it programmatically**:
```bash
# Find the most recent proof file
ls -t proof_*.json | head -1
```

**Store for reference (optional)**:
```bash
echo "export PROOF_FILE=proof_[actual_filename].json" > .env.temp
# Or keep it in a variable for the session
```

**Troubleshooting**:
- If agent URL not accessible, verify Step 4 tests pass
- If timeout occurs, the ZK proof service may be under high load (can take 60-150 seconds)
- Check Succinct Explorer URL for detailed proof generation status
- If proof generation fails, you can retry: `./scripts/attest-and-prove.sh`

---

### Step 6: Register Agent On-Chain

**⚠️ PREREQUISITE CHECK - Action for Claude Code**:
Before running this step, verify:
1. The `.env` file contains a valid `PRIVATE_KEY` (64 hex chars, no 0x prefix)
2. The user has confirmed they added their private key
3. If not confirmed, **STOP** and prompt the user to add it now

**Action**: Submit blockchain transaction to register the agent

**Step 1: Verify you have the proof filename from Step 5**
```bash
# If you stored it in .env.temp
source .env.temp 2>/dev/null && echo "PROOF_FILE: $PROOF_FILE"

# Or find it again
PROOF_FILE=$(ls -t proof_*.json | head -1)
echo "Using proof file: $PROOF_FILE"

# Verify the file exists
[ -f "$PROOF_FILE" ] && echo "Proof file found" || echo "ERROR: Proof file not found!"
```

**Step 2: Run registration with the captured proof filename**
```bash
# Use the PROOF_FILE variable (recommended)
./scripts/validate-and-register-agent.sh --proof-path "$PROOF_FILE"

# Or use the actual filename directly (example):
# ./scripts/validate-and-register-agent.sh --proof-path proof_ac75ca763c4747be_20251022024237623.json
```

**⚠️ Action for Claude Code**: You MUST use the exact filename captured in Step 5. Do not guess or use a placeholder.

**What This Does**:
1. Validates the proof file structure
2. Extracts TEE code measurements and public keys from proof
3. Constructs blockchain transaction with agent metadata
4. Submits transaction to Base Sepolia registry contract
5. Returns unique Agent ID

**Expected Output**:
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

**⚠️ CRITICAL - Action for Claude Code**:
After registration succeeds, you MUST capture the Agent ID for use in Step 7.

**Simple Method - Extract from output**:

The script output will show:
```
[INFO] Agent ID (uint256): 28
[NEXT] Agent ID (uint256): 28
```

**Simply note the Agent ID number** (e.g., `28`) and use it directly in Step 7.

**Store for reference**:
```bash
# Store the Agent ID you see in the output
echo "export AGENT_ID=28" >> .env.temp  # Replace 28 with actual Agent ID
```

**Verification (optional)**:
```bash
# Verify you captured it correctly
source .env.temp && echo "Agent ID: $AGENT_ID"
```

**⚠️ Remember**: You MUST use this exact Agent ID number in Step 7. Do not lose this value.

**Verification**:
```bash
# Verify transaction on block explorer
echo "Transaction: https://sepolia.basescan.org/tx/[transactionHash]"

# Verify agent registered on-chain
echo "Agent ID: [Agent ID from output]"
```

**Troubleshooting**:
- If transaction fails, check wallet has Base Sepolia ETH for gas
- Verify PRIVATE_KEY format in .env (64-char hex without 0x prefix)
- Check RPC endpoint is accessible: `curl -X POST https://sepolia.base.org`
- If private key error: Remove any 0x prefix and ensure exactly 64 hex characters

---

### Step 7: Verify Agent Signatures

**Action**: Cryptographically verify agent responses using on-chain public key

**Step 1: Setup Python Environment**
```bash
# Create virtual environment if it doesn't exist
python3 -m venv .venv 2>/dev/null || echo "Virtual environment already exists"

# Activate virtual environment
source .venv/bin/activate

# Verify activation (should show .venv path)
which python3

# Install verification dependencies
pip install -q -r ./scripts/verifier/requirements.txt
```

**Step 2: Verify you have the Agent ID from Step 6**
```bash
# If you stored it in .env.temp
source .env.temp 2>/dev/null && echo "AGENT_ID: $AGENT_ID"

# If not stored, you need to manually set it from Step 6 output
AGENT_ID=28  # Replace with your actual Agent ID from Step 6
echo "Using Agent ID: $AGENT_ID"

# Verify it's a number
[[ "$AGENT_ID" =~ ^[0-9]+$ ]] && echo "Valid Agent ID" || echo "ERROR: Invalid Agent ID format"
```

**Step 3: Run signature verification with the captured Agent ID**

**⚠️ Action for Claude Code**: You MUST use the exact Agent ID captured in Step 6. Do not use a placeholder.

```bash
# Ensure virtual environment is active
source .venv/bin/activate

# Verify hello_world endpoint
python3 ./scripts/verifier/verify.py --agent-id=$AGENT_ID --url-path=/hello_world

# Verify add_two endpoint with POST data
python3 ./scripts/verifier/verify.py --agent-id=$AGENT_ID --url-path=/add_two --data='{"a": 1, "b": 2}'
```

**Example with actual Agent ID 28**:
```bash
python3 ./scripts/verifier/verify.py --agent-id=28 --url-path=/hello_world
python3 ./scripts/verifier/verify.py --agent-id=28 --url-path=/add_two --data='{"a": 1, "b": 2}'
```

**Expected Output**:
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

**What This Verifies**:
1. Agent public key retrieved from on-chain registry
2. Agent endpoint returns signed response
3. Signature cryptographically matches registered agent key
4. Response authenticity is guaranteed by TEE

**Troubleshooting**:
- If ModuleNotFoundError, ensure virtual environment is activated
- If signature verification fails, agent may have been redeployed (new keys)
- If agent not found, verify AGENT_ID matches registration output

---

### Step 8: Summary and Exploration

**Action for Claude Code**: Present a complete summary of the tutorial with all captured values.

**Step 1: Load all captured values**
```bash
# Load values from temp file if available
source .env.temp 2>/dev/null
source .env

# Display all key values
echo "=== Tutorial Summary ==="
echo "Agent Name: $(cat src/agent.json | jq -r '.name')"
echo "Agent ID: $AGENT_ID"
echo "Agent URL: http://$EC2_HOST"
echo "ETH Address: $ETH_ADDRESS"
echo "Proof File: $PROOF_FILE"
```

**Step 2: Present completion summary to user**

**⚠️ Action for Claude Code**: Use the actual values you captured throughout the tutorial. Do not use placeholders.

Present to the user:
```
🎉 Tutorial Complete!

Your TEE Agent Details:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Agent Name:           [from agent.json]
Agent ID:             [captured from Step 6]
Agent URL:            http://[EC2_HOST]
Owner Address:        [ETH_ADDRESS from .env]
Agent Wallet:         [from Step 6 output]
Transaction Hash:     [from Step 6 output]
Proof File:           [captured from Step 5]
Code Repository:      [from agent.json]

Explore Your Agent:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. TEE Agent Explorer:
   http://18.144.124.66:8080/
   Search for your Agent ID: [AGENT_ID]

2. Registry Contract (Base Sepolia):
   https://sepolia.basescan.org/address/0xe718aec274E36781F18F42C363A3B516a4427637

3. Your Registration Transaction:
   https://sepolia.basescan.org/tx/[TRANSACTION_HASH]

4. Succinct ZK Proof Explorer:
   [URL from Step 5 output]

Test Your Agent:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
curl -s http://[EC2_HOST]/agent.json | jq
curl -s http://[EC2_HOST]/hello_world | jq

Next Steps:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- Customize src/main.py to add new functionality
- Redeploy with code changes (requires new proof & registration)
- Share your Agent ID with others to demonstrate TEE verification
- Build applications that consume your agent's signed responses
```

**Step 3: Provide explorer links**
```bash
echo "View your agent in the TEE Agent Explorer:"
echo "http://18.144.124.66:8080/"
echo ""
echo "View registry contract on Base Sepolia:"
echo "https://sepolia.basescan.org/address/0xe718aec274E36781F18F42C363A3B516a4427637"
```

**How Others Can Interact With Your Agent**:
Others can interact with your agent by:
1. Looking up your Agent ID ($AGENT_ID) in the registry
2. Retrieving your public key from on-chain storage
3. Calling your agent endpoints at http://$EC2_HOST
4. Verifying response signatures using your public key
5. Confirming code measurements match your repository

---

## Tutorial Completion Checklist

After completing all steps, verify:

- [ ] Agent deployed successfully to AWS Nitro Enclave
- [ ] All agent endpoints responding with signed data
- [ ] ZK proof generated and saved locally
- [ ] Agent registered on Base Sepolia blockchain
- [ ] Agent ID obtained and recorded
- [ ] Signature verification passes for all endpoints
- [ ] Agent visible in TEE Agent Explorer
- [ ] Transaction confirmed on Base Sepolia block explorer

---

## Key Concepts Explained

### TEE (Trusted Execution Environment)
A secure, isolated environment where code executes with cryptographic guarantees:
- Code integrity is measured and attested
- Private keys are generated and stored securely inside the enclave
- External parties cannot tamper with execution
- Attestation documents prove genuine TEE execution

### Code Measurement
A cryptographic hash of the agent's Docker image:
- Deterministically computed during enclave build
- Included in attestation documents
- Published on-chain during registration
- Allows anyone to verify the exact code running in the TEE

### ZK Proof (Zero-Knowledge Proof)
A cryptographic proof that verifies attestation validity:
- Proves the attestation comes from genuine AWS Nitro hardware
- Does not reveal sensitive attestation details
- Verifiable on-chain without trust in external parties
- Generated by Succinct proof service

### Agent Signatures
Every agent response includes a cryptographic signature:
- Signed using private key generated inside the TEE
- Public key stored on-chain during registration
- Proves response came from the registered TEE agent
- Cannot be forged by external parties

### ERC-8004 Registry
Smart contract that stores agent registrations:
- Maps Agent IDs to metadata (name, description, URLs)
- Stores public keys for signature verification
- Records code measurements for reproducibility
- Provides on-chain validation of TEE agents

---

## Common Tasks

### Redeploying Agent After Code Changes

```bash
# 1. Edit source code (e.g., src/agent.json, src/*.py)
# 2. Redeploy to enclave
./scripts/build-and-deploy-remote.sh

# 3. Wait for enclave startup
sleep 15

# 4. Test endpoints
curl -s http://$AGENT_URL/agent.json | jq

# 5. Generate new proof (code measurement changed)
./scripts/attest-and-prove.sh

# 6. Register as new agent (or update existing)
./scripts/validate-and-register-agent.sh --proof-path proof_[NEW_FILENAME].json
```

**Note**: Code changes produce different code measurements, requiring new proof and registration.

### Checking Enclave Status

```bash
# SSH into EC2 instance
ssh -i $EC2_PEM_KEY $EC2_USER@$EC2_HOST

# Check running enclaves
nitro-cli describe-enclaves

# View enclave console output
nitro-cli console --enclave-id i-[INSTANCE_ID]-enc[ENCLAVE_ID]

# Check host proxy logs
tail -f ~/host.log
```

### Manual Agent Testing

```bash
# Test metadata endpoint
curl http://$AGENT_URL/agent.json | jq

# Test computation with signature
curl -X POST http://$AGENT_URL/add_two \
  -H "Content-Type: application/json" \
  -d '{"a": 100, "b": 200}' | jq

# Extract just the signature
curl -s http://$AGENT_URL/hello_world | jq -r '.sig'

# Extract just the data
curl -s http://$AGENT_URL/hello_world | jq -r '.data'
```

### Querying Registry Contract

```bash
# Install web3.py if needed
pip install web3

# Query agent details (Python)
python3 -c "
from web3 import Web3
w3 = Web3(Web3.HTTPProvider('https://sepolia.base.org'))
registry = w3.eth.contract(
    address='0xe718aec274E36781F18F42C363A3B516a4427637',
    abi=[{'inputs':[{'type':'uint256','name':'agentId'}],'name':'getAgent','outputs':[{'type':'tuple','components':[{'type':'address','name':'owner'},{'type':'string','name':'metadataURI'},{'type':'address','name':'publicKey'}]}],'stateMutability':'view','type':'function'}]
)
agent = registry.functions.getAgent($AGENT_ID).call()
print(f'Owner: {agent[0]}')
print(f'Metadata: {agent[1]}')
print(f'PublicKey: {agent[2]}')
"
```

---

## File Structure Reference

```
8004-ri-tutorial/
├── .env                          # Environment configuration (SSH, blockchain)
├── .env.example                  # Template for .env file
├── src/
│   ├── agent.json               # Agent metadata (customize this)
│   ├── main.py                  # Agent HTTP server implementation
│   ├── .env.example             # Template for OpenAI API key
│   └── Dockerfile               # Container build configuration
├── scripts/
│   ├── build-and-deploy-remote.sh    # Deploy agent to EC2 Nitro Enclave
│   ├── build-and-deploy-local.sh     # Local Docker testing (under maintenance)
│   ├── attest-and-prove.sh           # Generate ZK proof from attestation
│   ├── validate-and-register-agent.sh # Register agent on-chain
│   └── verifier/
│       ├── verify.py                 # Signature verification script
│       └── requirements.txt          # Python dependencies
├── docs/
│   ├── CLAUDE_TUTORIAL.md           # This file
│   ├── AWS_Nitro_Enclave_Runtime.md # Setup your own AWS environment
│   └── TEE_Agent_Registry.md        # Registry contract documentation
├── proof_*.json                 # Generated ZK proof files
└── README.md                    # Main project documentation
```

---

## Troubleshooting Reference

### Issue: "Connection refused" when testing agent

**Symptoms**: `curl http://$AGENT_URL/agent.json` returns connection error

**Solutions**:
1. Wait 15 seconds after deployment for enclave startup
2. Verify enclave is running: `ssh -i $EC2_PEM_KEY $EC2_USER@$EC2_HOST "nitro-cli describe-enclaves"`
3. Check security group allows inbound HTTP (port 80)
4. Verify EC2_HOST in .env matches actual public IP

### Issue: "Permission denied (publickey)"

**Symptoms**: SSH connection fails during deployment

**Solutions**:
1. Check PEM key permissions: `chmod 400 $EC2_PEM_KEY`
2. Verify EC2_PEM_KEY path is correct in .env
3. Ensure EC2_USER matches instance AMI (usually `ec2-user`)
4. Test manual SSH: `ssh -i $EC2_PEM_KEY $EC2_USER@$EC2_HOST`

### Issue: ZK proof generation timeout

**Symptoms**: `attest-and-prove.sh` times out after 300 seconds

**Solutions**:
1. Verify agent is accessible: `curl http://$AGENT_URL/attestation/download`
2. Check Succinct service status (may be under high load)
3. Retry with longer timeout: `./scripts/attest-and-prove.sh --timeout 600`
4. Monitor proof status on Succinct Explorer (URL in output)

### Issue: "Transaction failed" during registration

**Symptoms**: `validate-and-register-agent.sh` transaction reverts

**Solutions**:
1. Check wallet has Base Sepolia ETH: `cast balance $ETH_ADDRESS --rpc-url https://sepolia.base.org`
2. Verify PRIVATE_KEY format (64 hex chars, no 0x prefix)
3. Test RPC connection: `curl -X POST https://sepolia.base.org -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'`
4. Check gas price is reasonable (may need to increase)

### Issue: Signature verification fails

**Symptoms**: `verify.py` reports signature mismatch

**Solutions**:
1. Verify AGENT_ID matches registered agent
2. Check agent hasn't been redeployed (new keys generated)
3. Ensure agent URL is correct
4. Test endpoint manually: `curl http://$AGENT_URL/hello_world`
5. Verify public key on-chain matches agent

### Issue: Python ModuleNotFoundError

**Symptoms**: `verify.py` can't import required modules

**Solutions**:
1. Activate virtual environment: `source .venv/bin/activate`
2. Verify activation: `which python3` (should show .venv path)
3. Install dependencies: `pip install -r scripts/verifier/requirements.txt`
4. Check Python version: `python3 --version` (requires 3.8+)

---

## Advanced Topics

### Adding Custom Endpoints

To add new agent functionality:

1. Edit `src/main.py` to add new FastAPI route:
```python
@app.post("/my_custom_endpoint")
async def my_custom_endpoint(request: Request):
    data = await request.json()
    result = perform_computation(data)
    return sign_response(result)
```

2. Update `src/agent.json` to document new endpoint:
```json
{
  "endpoints": [
    "/agent.json",
    "/add_two",
    "/hello_world",
    "/my_custom_endpoint"
  ]
}
```

3. Redeploy agent (generates new code measurement)
4. Generate new proof and re-register

### Integrating OpenAI API

The agent includes an optional `/chat` endpoint:

1. Create `src/.env` with OpenAI key:
```bash
cp src/.env.example src/.env
echo "OPENAI_API_KEY=sk-..." >> src/.env
```

2. Deploy agent (API key is encrypted inside enclave)

3. Test chat endpoint:
```bash
curl -X POST http://$AGENT_URL/chat \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Explain TEE agents"}' | jq
```

**Security Note**: API keys are only accessible inside the TEE enclave.

### Reproducible Builds

Anyone can verify your agent by rebuilding from source:

1. Clone your code repository
2. Use exact same source code and dependencies
3. Build Docker image with same Dockerfile
4. Compute code measurement from EIF
5. Compare with on-chain code measurement

If measurements match, the on-chain agent runs that exact code.

---

## Next Steps After Tutorial

After completing this tutorial, you can:

1. **Customize Agent Logic**: Modify `src/main.py` to implement custom business logic
2. **Add More Endpoints**: Create specialized computation endpoints for your use case
3. **Integrate External APIs**: Securely call external services from within the TEE
4. **Build Applications**: Create dApps that interact with your registered TEE agent
5. **Explore Sparsity Offerings**: Learn about advanced features like compliance and hosting

---

## Additional Resources

- **ERC-8004 Standard**: https://8004.org
- **Sparsity Documentation**: https://docs.sparsity.xyz
- **AWS Nitro Enclaves**: https://aws.amazon.com/ec2/nitro/nitro-enclaves/
- **Base Sepolia Faucet**: https://www.coinbase.com/faucets/base-ethereum-sepolia-faucet
- **Succinct ZK Proofs**: https://succinct.xyz
- **TEE Agent Explorer**: http://18.144.124.66:8080/

---

## Support

If you encounter issues:

- **Discord**: https://discord.gg/6vrFdpnFvm (community support)
- **Email**: support@sparsity.xyz (detailed technical issues)
- **GitHub Issues**: https://github.com/sparsity-xyz/8004-ri-tutorial/issues
- **Twitter/X**: @sparsity_xyz (quick questions)

When requesting support, include:
1. Command that failed and error message
2. Environment details (OS, AWS region, EC2 instance type)
3. Relevant log excerpts
4. Steps to reproduce the issue

---

**End of Tutorial Guide**
