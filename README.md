# Sparsity Trustless Agents Framework

<p align="center">🚀 Reference Implementation of TEE Registry in <a href="https://8004.org">ERC-8004</a></p>

## Overview

<a href="https://8004.org">ERC-8004</a> defines trustless agents in the Ethereum ecosystem. An important component in 8004 is the validation registry. Validation ensures the integrity of agents through economic-staking or TEE. This repo provides a tutorial on building 8004 agents using TEE on the Sparsity reference implementation. For a deep dive into the 8004 registry design, please see [this doc](https://docs.google.com/document/d/127pkxlBE0048N-MNsX66Ctz5dmRxHvaJRASAr01EVVc/edit?tab=t.0#heading=h.x6rb197jqjog).

## Architecture Overview

<img width="944" height="417" alt="Screenshot 2025-10-09 at 1 28 55 AM" src="https://github.com/user-attachments/assets/9058a6aa-ed9a-408f-8802-672e40ed43cf" />

In the 8004 TEE registry, the TEE Registry smart contract stores 


## Three-Layers Solution

Sparsity's layered approach enables developers to quickly build, certify, and deploy secure TEE applications with minimal friction, leveraging both AWS Nitro Enclaves and advanced compliance and hosting solutions.

see [Sparsity Offerings](Sparsity_Offerings.md) for details.

## 0. Pre-requisites: AWS Nitro Enclaves Environment

Before using Sparsity's offerings, ensure you have an AWS Nitro Enclaves environment set up. This includes having an AWS account, configuring Nitro Enclaves on your EC2 instances, and setting up necessary IAM roles and permissions.

see [AWS_Nitro_Enclave_Runtime.md](AWS_Nitro_Enclave_Runtime.md) for details.

**BuildETH 2025 — Oct 9**

Participants in BuildETH 2025 can request free EC2 access to build their first TEE application. Join our discussion via our Discord channel:

- Discord: https://discord.gg/2C5eTvxW

To apply for a lab environment, submit this form:

- Lab environment application: https://tinyurl.com/sparsity-8004-lab

<img width="300" alt="QR Code for application" src="online-application.png" />

## 1. Use enclave-toolkit to build TEE agents

AWS provides the Nitro Enclaves solution as a TEE environment. However, implementing a fully-functional agent inside a Nitro Enclave requires developers to handle several platform and integration concerns themselves — for example:

- proxy-in / proxy-out (host <-> enclave communication)
- TLS for secure transport
- Attestation generation and verification
- KMS integration for secure key operations
- And other enclave/host interaction plumbing

Using our `enclave-toolkit` makes developing your enclave agent much simpler by providing helpers, patterns, and working examples for these common building blocks.

A simpler way is to start is to fork this repository and begin from the working example application under the `src/` folder, then follow the [Deploy Enclave Agents](Deploy_Enclave_Agents.md) to deploy your agent to an AWS Nitro Enclave.

## 2. Use trustless-agent-framework to validate 8004-compliant TEE agents

[ERC-8004](https://eips.ethereum.org/EIPS/eip-8004) provides a standard for discovering agents and establishing trust through reputation and validation.

For agents running inside a TEE environment, our `trustless-agent-framework` delivers an end-to-end solution to:

- Generate a zero-knowledge (ZK) proof that attests to the agent's behavior and integrity
- Publish and validate the agent in an on-chain ERC-8004-compatible registry
- Enable discovery and reputation tracking so your agent can be found and trusted by a large audience

You can follow the [Validation Guide](Validate_Enclave_Agents.md) to get your agent validated in 8004-compliant registry.

On-chain registry contract: [8004-compliant registry](https://sepolia.basescan.org/address/0x3dfA3C604aE238E03DfE63122Edd43A4aD916460)

Agent explorer / discovery URL: [Agent explorer](https://sepolia.basescan.org/address/0x3dfA3C604aE238E03DfE63122Edd43A4aD916460)


## 3. Use Nova Platform to deploy agents to Sparsity-run TEE cloud

Similar to Vercel for websites, Nova is designed specifically for TEE applications

More details coming soon.

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
