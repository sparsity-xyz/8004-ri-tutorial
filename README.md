# Sparsity Trustless Agents Framework

## Overview

The Sparsity Trustless Agents Framework provides a comprehensive solution for building and deploying secure, privacy-preserving applications in a trusted execution environment (TEE). By leveraging AWS Nitro Enclaves, the framework ensures that sensitive data is processed in isolation, protecting it from unauthorized access and potential breaches.

## Three-Layer Framework

Sparsity's layered approach enables developers to quickly build, certify, and deploy secure TEE applications with minimal friction, leveraging both AWS Nitro Enclaves and advanced compliance and hosting solutions.

see [Sparsity Offerings](Sparsity_Offerings.md) for details.

## Pre-requisites: AWS Nitro Enclaves Environment

Before using Sparsity's offerings, ensure you have an AWS Nitro Enclaves environment set up. This includes having an AWS account, configuring Nitro Enclaves on your EC2 instances, and setting up necessary IAM roles and permissions.

see [AWS_Nitro_Enclave_Runtime.md](AWS_Nitro_Enclave_Runtime.md) for details.

**BuildETH 2025 - Oct 9**

For participants in "BuildETH 2025", please join our [Discord channel](https://discord.com/channels/1249529367986569277/1424654814423289877) to get FREE access to ec2 instances to build your first TEE app.

Submit your application here: [Lab env application](https://docs.google.com/forms/d/e/1FAIpQLSd-VVhQdfgUlH1F1lyT4mwjdgZQNESZQxl5tGamrRXLlQvZHA/viewform)

## Use enclave-toolkit to build TEE agents

AWS provides the Nitro Enclaves solution as a TEE environment. However, implementing a fully-functional agent inside a Nitro Enclave requires developers to handle several platform and integration concerns themselves — for example:

- proxy-in / proxy-out (host <-> enclave communication)
- TLS for secure transport
- Attestation generation and verification
- KMS integration for secure key operations
- And other enclave/host interaction plumbing

Using our `enclave-toolkit` makes developing your enclave agent much simpler by providing helpers, patterns, and working examples for these common building blocks.

You can follow the guidance in [Develop your agent with enclave-toolkit](xxx.md) to get started.

Or a simpler way is to start is to fork this repository and begin from the working example application under the `src/` folder, then follow the [Deployment Guide](Deploy_Enclave_Agents.md) to deploy your agent to an AWS Nitro Enclave and register it on the registry.

## Use trustless-agent-framework to build 8004-compliant TEE agents

ERC-8004 provides a standard for discovering agents and establishing trust through reputation and validation.

For agents running inside a TEE environment, our `trustless-agent-framework` delivers an end-to-end solution to:

- Generate a zero-knowledge (ZK) proof that attests to the agent's behavior and integrity
- Publish and validate the agent in an on-chain ERC-8004-compatible registry
- Enable discovery and reputation tracking so your agent can be found and trusted by a large audience

You can follow the the [Validation Guide](Validate_Enclave_Agents.md) to get your agent validated in 8004-compliant registry.

On-chain registry address: [8004-compliant registry](https://sepolia.basescan.org/address/0x3dfA3C604aE238E03DfE63122Edd43A4aD916460)

Agent explorer / discovery URL: [Agent explorer](https://sepolia.basescan.org/address/0x3dfA3C604aE238E03DfE63122Edd43A4aD916460)


## Use Nova to deploy agents to Sparsity-run TEE cloud

More details coming soon.