# Trustless Agents Framework - Deployment Guide

This guide walks you through deploying a TEE-based agent on AWS Nitro Enclaves and registering it on the Base Sepolia registry.

## Prerequisites

### Required Software
- SSH client
- Python 3.11-3.12
- Docker (for local testing)
- Foundry (forge, cast)
- jq (JSON processor)

### Required Resources
1. **TEE-enabled EC2 instance** - Contact Sparsity to get:
   - EC2 instance with Nitro Enclave support
   - SSH PEM key for access
2. **Testnet tokens** - Provide your Base Sepolia address to receive test ETH
3. **Registry contract address** - Get the TEE Validation Registry address on Base Sepolia

## Setup

### 1. Clone and Configure

```bash
# Clone the repository, or your own fork
git clone https://github.com/sparsity-xyz/sparsity-trustless-agents-framework.git
cd sparsity-trustless-agents-framework

# Copy environment template
cp .env.example .env

# Edit .env with your values
nano .env
```

Required `.env` configuration:
```bash
# EC2 Configuration
EC2_HOST=ec2-xx-xxx-xxx-xxx.compute-1.amazonaws.com
EC2_USER=ec2-user
EC2_PEM_KEY=/path/to/your-key.pem

# Enclave Settings
ENCLAVE_MEMORY=4096
ENCLAVE_CPU_COUNT=2
DOCKER_IMAGE_NAME=nitro-agent
EIF_FILE_NAME=nitro-agent.eif

# Application Variables
OPENAI_API_KEY=your-openai-api-key-here

# Attestation Service
ETH_PROVER_SERVICE_URL=http://13.124.55.154:8000
ATTESTATION_URL=http://your-ec2-host/attestation/download

# Registry Contract (Base Sepolia)
REGISTRY=0x96486304d71690c5a133a3780E9D637bd7d6E85B
RPC_URL=https://sepolia.base.org
PRIVATE_KEY=your-private-key-here

# Agent Configuration
AGENT_ID=123
AGENT_URL=http://your-ec2-host
TEE_ARCH=nitro
PROOF_PATH=proof.json
```

### 2. Setup EC2 Instance

Copy and run the setup script on your EC2 instance:

```bash
# Copy setup script to EC2
scp -i $EC2_PEM_KEY scripts/setup-ec2.sh $EC2_USER@$EC2_HOST:~/

# SSH into EC2
ssh -i $EC2_PEM_KEY $EC2_USER@$EC2_HOST

# Run setup (will automatically reboot after completion)
bash setup-ec2.sh
```

The setup script will:
- Install AWS Nitro CLI
- Install Docker
- Configure Nitro Enclaves allocator
- Add user to necessary groups
- Reboot the instance

After reboot, verify the setup:
```bash
# SSH back in
ssh -i $EC2_PEM_KEY $EC2_USER@$EC2_HOST

# Check Nitro CLI
nitro-cli --version

# Verify Docker
docker --version

# Check groups
groups  # Should include: docker, ne
```

## Development

### 3. Build Your Application

Edit `src/main.py` to implement your agent logic:

```python
from fastapi import Request
from dotenv import load_dotenv
import os
from nitro_toolkit.enclave import BaseNitroEnclaveApp

load_dotenv()

class App(BaseNitroEnclaveApp):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.add_endpoints()

    def add_endpoints(self):
        self.app.add_api_route("/your_endpoint", self.your_handler, methods=["POST"])
    
    async def your_handler(self, request: Request):
        # Your logic here
        return self.response("result")

if __name__ == "__main__":
    app = App()
    app.run()
```

### 4. Local Testing (Optional)

Test your application locally with Docker:

```bash
# Build and run locally
./scripts/deploy-local.sh

# Test endpoints
curl http://localhost:9982/hello_world
curl -X POST http://localhost:9982/add_two -H "Content-Type: application/json" -d '{"a": 5, "b": 3}'

# Stop container
docker stop nitro-test
```

## Deployment

### 5. Deploy to EC2 Nitro Enclave

Deploy your application to the remote EC2 instance:

```bash
./scripts/deploy-remote.sh
```

This script will:
1. Terminate existing enclaves
2. Copy source files to EC2
3. Build Docker image with Nitro flags
4. Build enclave image (.eif)
5. Install nitro-toolkit on host
6. Start host proxy on port 80
7. Run the enclave in debug mode

Output example:
```
Building enclave image...
Enclave Image successfully created.
{
  "Measurements": {
    "PCR0": "ab9c4343b98d60c941741b372ca6f65f...",
    "PCR1": "4b4d5b3661b3efc12920900c80e126e4...",
    "PCR2": "a2f83b249f95da41574191af53c592fe..."
  }
}
```

### 6. Test Deployed Agent

```bash
# Test health endpoint
curl http://$EC2_HOST/hello_world

# Test your custom endpoints
curl -X POST http://$EC2_HOST/your_endpoint \
  -H "Content-Type: application/json" \
  -d '{"your": "data"}'
```

## Attestation & Registration

### 7. Generate Attestation Proof

Request proof generation from the Nitro attestation service:

```bash
# Set attestation URL in .env
ATTESTATION_URL=http://$EC2_HOST/attestation/download

# Request proof (waits up to 100 seconds)
./scripts/request-proof.sh
```

The script will:
1. Upload attestation document URL to prover service
2. Poll for proof completion (100s timeout)
3. Download proof to `proof.json`

Output:
```
=== Nitro Attestation Proof Service ===
Uploading attestation...
Directory: attestation_20241007_062915
Polling for proof (timeout: 100s)...
[0s] Processing...
[5s] Processing...
...
Proof ready! Downloading...
Saved to: proof.json
```

### 8. Register Agent on Base Sepolia

Submit the proof to the registry contract:

```bash
# Ensure all variables are set in .env
# REGISTRY, RPC_URL, PRIVATE_KEY, AGENT_ID, AGENT_URL, TEE_ARCH

# Validate and register agent
./scripts/validate-agent.sh
```

The script will:
1. Check if zkVerifier is set in registry
2. Parse proof JSON
3. Convert parameters to correct format
4. Submit transaction to registry

Output:
```
=== Validating Agent with TEEValidationRegistry ===
Registry: 0x96486304d71690c5a133a3780E9D637bd7d6E85B
Agent ID: 123
URL: 43.201.69.136
TEE Arch: nitro

Checking zkVerifier...
zkVerifier: 0x...

Calling validateAgent...
blockHash            0x02c2d5578e901d9cf0f54a9f0fa2a1b1f3c5597f...
status               1 (success)

=== Agent validated successfully! ===
```

### 9. Verify Registration

Check that your agent is registered:

```bash
# Query agent info from registry
cast call $REGISTRY \
  "getAgent(uint256)(uint256,bytes32,bytes32,bytes,string)" \
  $AGENT_ID \
  --rpc-url $RPC_URL
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│                   User/Client                    │
└────────────────────┬────────────────────────────┘
                     │ HTTP
                     ▼
┌─────────────────────────────────────────────────┐
│              EC2 Host (Port 80)                  │
│  ┌───────────────────────────────────────────┐  │
│  │        Host Proxy (host.py)               │  │
│  │  - Routes requests via VSOCK              │  │
│  └───────────────┬───────────────────────────┘  │
│                  │ VSOCK (CID 16)                │
│  ┌───────────────▼───────────────────────────┐  │
│  │      Nitro Enclave (Isolated TEE)         │  │
│  │  ┌─────────────────────────────────────┐  │  │
│  │  │     Your Application (main.py)      │  │  │
│  │  │  - FastAPI endpoints                │  │  │
│  │  │  - Secure computation               │  │  │
│  │  │  - Attestation generation           │  │  │
│  │  └─────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
                     │
                     │ Attestation
                     ▼
┌─────────────────────────────────────────────────┐
│        Nitro Attestation Prover Service          │
│         (generates ZK proofs)                    │
└────────────────────┬────────────────────────────┘
                     │ Proof
                     ▼
┌─────────────────────────────────────────────────┐
│    TEEValidationRegistry (Base Sepolia)          │
│    - Verifies proofs                             │
│    - Registers agents                            │
└─────────────────────────────────────────────────┘
```

## Troubleshooting

### Enclave fails to start
```bash
# Check enclave logs
ssh -i $EC2_PEM_KEY $EC2_USER@$EC2_HOST
cat ~/enclave.log

# Check host proxy logs
cat ~/host.log

# Describe running enclaves
nitro-cli describe-enclaves

# Check console output
nitro-cli console --enclave-id <id>
```

### Docker permission denied
```bash
# Ensure you've rebooted after setup
# Or run with sudo temporarily
sudo docker build ...
```

### Proof generation timeout
- Increase timeout in `request-proof.sh`
- Check attestation URL is accessible
- Verify prover service is running

### Transaction reverts
```bash
# Check zkVerifier is set
cast call $REGISTRY "zkVerifier()(address)" --rpc-url $RPC_URL

# Verify proof format
cat proof.json | jq .

# Check gas limit
# Add --gas-limit 5000000 to cast send
```

## Scripts Reference

| Script | Purpose |
|--------|---------|
| `setup-ec2.sh` | Configure EC2 instance for Nitro Enclaves |
| `deploy-local.sh` | Test application locally with Docker |
| `deploy-remote.sh` | Deploy application to EC2 Nitro Enclave |
| `request-proof.sh` | Generate attestation proof via prover service |
| `validate-agent.sh` | Register agent on Base Sepolia registry |

## Additional Resources

- [AWS Nitro Enclaves Documentation](https://docs.aws.amazon.com/enclaves/)
- [Nitro Toolkit Repository](https://github.com/nitro-toolkit)
- [Base Sepolia Faucet](https://www.coinbase.com/faucets/base-ethereum-sepolia-faucet)
- [Sparsity Documentation](https://docs.sparsity.ai)
