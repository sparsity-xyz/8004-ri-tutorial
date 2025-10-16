# Sparsity Solution: Three-Layer Framework

Sparsity organizes its offerings into three distinct layers, each designed to streamline the development, compliance, and deployment of Trusted Execution Environment (TEE) applications. Below is an overview of each layer and its key components.

## Architecture Overview

Below is a compact ASCII diagram that visualizes the three layers and their key components

```
						+--------------------------------+
						|         NOVA PLATFORM          |
						|       (Layer 3 — Top)          |
						|  - App registration            |
						|  - Deploy & run in Sparsity    |
						+--------------------------------+
									  ^
									  |
						 (optional managed execution)
									  |
						+--------------------------------+
						|     TRUSTLESS AGENT (8004)     |
						|          (Layer 2)             |
						|  - 8004 registry               |
						|  - ZK proving                  |
						|  - App runs in developer's     |
						|    own enclave                 |
						+--------------------------------+
									  ^
									  |
						(developer-managed compliance & proofs)
									  |
						+--------------------------------+
						|        ENCLAVE TOOLKIT         |
						|         (Layer 1 — Bottom)     |
						|  - Proxy in enclave            |
						|  - Attestation generation      |
						|  - KMS integration             |
						|  - Host proxy                  |
						+--------------------------------+
									  |
									  |
							 Developer / Host
							 (builds & runs apps)
```

This diagram shows how developers build using the Enclave Toolkit (Layer 1), make their apps 8004-compliant with the Trustless Agent (Layer 2), and optionally deploy to the Nova platform (Layer 3) for managed execution.

---

## Layer 1: Enclave Toolkit
**Purpose:** Accelerate the development of TEE applications by providing essential tools and integrations for AWS Nitro Enclaves.

**Features:**
- **Proxy in Enclave:** Enables secure communication within the enclave.
- **Attestation Generation:** Facilitates the creation of attestation documents for verifying enclave integrity.
- **KMS Integration:** Seamlessly connects with AWS Key Management Service for secure key operations inside the enclave.
- **Host Proxy:** Manages communication between the host and the enclave, ensuring isolation and security.

---

## Layer 2: Trustless Agent (8004 Compliant)
**Purpose:** Help developers build AWS TEE applications that comply with ERC-8004 standards for trustless agents.

**Features:**
- **8004 Registry:** Maintains a registry of compliant agents and applications.
- **ZK Proving:** Integrates zero-knowledge proof mechanisms for enhanced privacy and trust.
- **App Running in Developer’s Own Enclave:** Supports deployment and execution of applications within the developer's own AWS Nitro Enclave.

---

## Layer 3: Nova Platform

**High-level Summary:** Similar to Vercel for websites, Nova is designed specifically for TEE applications.

**Purpose:** Sparsity-operated platform for hosting, deploying, and managing TEE applications—similar to Vercel, but for TEE.

**Features:**
- **App Registration:** Allows developers to register their TEE applications on the Nova platform.
- **App Deployment & Run in Sparsity-Run TEE Cloud Environments:** Provides managed infrastructure for deploying and running TEE applications securely in Sparsity's cloud.


---

Sparsity's layered approach enables developers to quickly build, certify, and deploy secure TEE applications with minimal friction, leveraging both AWS Nitro Enclaves and advanced compliance and hosting solutions.

