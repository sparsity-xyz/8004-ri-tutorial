# Sparsity Trustless Agents Framework

<p align="center">🚀 Reference Implementation of TEE Registry in <a href="https://8004.org">ERC-8004</a></p>

## Overview

<a href="https://8004.org">ERC-8004</a> defines trustless agents in the Ethereum ecosystem. An important component in 8004 is the validation registry. Validation ensures the integrity of agents through economic-staking or TEE. This repo provides a tutorial on building 8004 agents using TEE on the Sparsity reference implementation. For a deep dive into the 8004 registry design, please see [this doc](https://docs.google.com/document/d/127pkxlBE0048N-MNsX66Ctz5dmRxHvaJRASAr01EVVc/edit?tab=t.0#heading=h.x6rb197jqjog).

## Architecture Overview

<img width="944" height="417" alt="Screenshot 2025-10-09 at 1 28 55 AM" src="https://github.com/user-attachments/assets/9058a6aa-ed9a-408f-8802-672e40ed43cf" />

In the 8004 TEE registry, the TEE Registry smart contract stores 

## Table of Contents

- [Three-Layers Solution](#three-layers-solution)
  - [1. Use enclave-toolkit to build TEE agents](#1-use-enclave-toolkit-to-build-tee-agents)
  - [2. Use trustless-agent-framework to validate 8004-compliant TEE agents](#2-use-trustless-agent-framework-to-validate-8004-compliant-tee-agents)
  - [3. Use Nova Platform to deploy agents to Sparsity-run TEE cloud](#3-use-nova-platform-to-deploy-agents-to-sparsity-run-tee-cloud)
- [0. Pre-requisites: AWS Nitro Enclaves Environment](#0-pre-requisites-aws-nitro-enclaves-environment)
- [BuildETH 2025 — Oct 9](#buildeth-2025-—-oct-9)
- [Support](#support)


## Three-Layers Solution

Sparsity's layered approach enables developers to quickly build, certify, and deploy secure TEE applications with minimal friction, leveraging both AWS Nitro Enclaves and advanced compliance and hosting solutions.

see [Sparsity Offerings](Sparsity_Offerings.md) for details.

## Quick start tutorials

The simplest way to get started is to build your agent from our reference implementation.

#### 0. Pre-requisites: AWS Nitro Enclaves Environment

Before using Sparsity's offerings, ensure you have an AWS Nitro Enclaves environment set up. This includes having an AWS account, configuring Nitro Enclaves on your EC2 instances, and installing necessary packages.

see [AWS_Nitro_Enclave_Runtime.md](AWS_Nitro_Enclave_Runtime.md) for details.

**BuildETH 2025 — Oct 9**

For participants in BuildETH 2025, to apply for a lab environment, submit this form:

- Lab environment application: https://tinyurl.com/sparsity-8004-lab

You will receive an email with the necessary details to start your tutorial shortly.

#### 1. fork & clone

fork this repo to your own GitHub account and clone to your local machine

```
git clone https://github.com/[your-username]/sparsity-trustless-agents-framework.git --depth=1
```

#### 2. edit .env

```
cd sparsity-trustless-agents-framework
cp .env.example .env
nano .env
```

Please fill in the required values in `.env` as described in the file. 

If you have submitted the lab environment application form, you will receive the necessary details via email.

#### 3. edit agent code

You are encouraged to modify `src/agent.json` to customize your agent's metadata.

You can also modify other files in the `src/` directory to implement your own agent logic.

#### 4. build & deploy

If you have modified the agent code, please make sure you have tested locally with Docker first.

```
./scripts/deploy-local.sh
```



After that, you can directly deploy to your agent to EC2 Nitro Enclave by running:

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

#### 5. request zk proof


```
./scripts/request-proof.sh
```

#### 6. register & validate

```
hello
```

#### 6. register & validate

```
./scripts/register-agent.sh -p <your-proof-file>
```

#### 7. play with your agent


#### 8. explore agents 

list all agents:
```
./scripts/explore-agents.sh
```
get details of your agent:
```
./scripts/explore-agents.sh --agent-id <your_agent_id>
```


## Related Links

On-chain registry contract: [8004-compliant registry](https://sepolia.basescan.org/address/0x3dfA3C604aE238E03DfE63122Edd43A4aD916460)

Agent explorer / discovery URL: [Agent explorer](https://sepolia.basescan.org/address/0x3dfA3C604aE238E03DfE63122Edd43A4aD916460)


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
