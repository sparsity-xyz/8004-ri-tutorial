#!/bin/bash
set -e

# Load environment variables
if [ ! -f .env ]; then
    echo "Error: .env file not found"
    exit 1
fi
source .env

# Check required variables
if [ -z "$REGISTRY" ] || [ -z "$RPC_URL" ] || [ -z "$PRIVATE_KEY" ]; then
    echo "Error: REGISTRY, RPC_URL, and PRIVATE_KEY must be set in .env"
    exit 1
fi

# Default parameters (can be overridden by environment or CLI)
PROOF_PATH=${PROOF_PATH:-proof.json}
AGENT_ID=${AGENT_ID:-123}
AGENT_URL=${AGENT_URL:-"http://example.com"}
TEE_ARCH=${TEE_ARCH:-"nitro"}

# CLI argument parsing to allow passing proof path
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--proof-path)
            if [[ -n "$2" && "$2" != -* ]]; then
                PROOF_PATH="$2"
                shift 2
            else
                echo "Error: $1 requires a value"
                exit 1
            fi
            ;;
        --proof-path=*)
            PROOF_PATH="${1#*=}"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--proof-path PATH]"
            echo
            echo "Options:"
            echo "  -p, --proof-path PATH   Path to proof JSON (overrides .env PROOF_PATH)"
            echo "  -h, --help              Show this help message"
            exit 0
            ;;
        *)
            echo "Error: Unknown argument: $1"
            exit 1
            ;;
    esac
done

echo "=== Validating Agent with TEEValidationRegistry ==="
echo "Registry: $REGISTRY"
echo "Agent ID: $AGENT_ID"
echo "URL: $AGENT_URL"
echo "TEE Arch: $TEE_ARCH"
echo "Proof path: $PROOF_PATH"
echo

# Ensure proof file exists
if [ ! -f "$PROOF_PATH" ]; then
    echo "Error: proof file not found at '$PROOF_PATH'"
    exit 1
fi

# Parse proof JSON
JOURNAL=$(jq -r '.raw_proof.journal' "$PROOF_PATH")
ONCHAIN_PROOF=$(jq -r '.onchain_proof' "$PROOF_PATH")
PROOF_TYPE=$(jq -r '.proof_type' "$PROOF_PATH")
ZK_TYPE=$(jq -r '.zktype' "$PROOF_PATH")

# Verify proof type
if [ "$PROOF_TYPE" != "Verifier" ]; then
    echo "Error: Expected proof_type 'Verifier', got: $PROOF_TYPE"
    exit 1
fi

# Convert zktype to enum value (0 = Risc0, 1 = SP1)
if [ "$ZK_TYPE" = "Risc0" ]; then
    ZK_TYPE_ENUM=1
elif [ "$ZK_TYPE" = "Succinct" ]; then
    ZK_TYPE_ENUM=2
else
    echo "Error: Unknown zktype: $ZK_TYPE"
    exit 1
fi

# Convert TEE arch to bytes32
TEE_ARCH_BYTES32=$(echo -n "$TEE_ARCH" | xxd -p | tr -d '\n' | awk '{printf "0x%-64s\n", $0}' | sed 's/ /0/g')

echo "Converted values:"
echo "  TEE Arch (bytes32): $TEE_ARCH_BYTES32"
echo "  ZK Type (enum): $ZK_TYPE_ENUM ($ZK_TYPE)"
echo

# First check if zkVerifier is set
echo "Checking zkVerifier..."
ZK_VERIFIER=$(cast call "$REGISTRY" "zkVerifier()(address)" --rpc-url "$RPC_URL")
echo "zkVerifier: $ZK_VERIFIER"

if [ "$ZK_VERIFIER" = "0x0000000000000000000000000000000000000000" ]; then
    echo "Error: zkVerifier is not set in registry"
    exit 1
fi

echo

# Call validateAgent with correct parameter order from interface
echo "Calling validateAgent..."
cast send "$REGISTRY" \
    "validateAgent(uint256,string,bytes32,uint8,bytes,bytes)" \
    "$AGENT_ID" \
    "$AGENT_URL" \
    "$TEE_ARCH_BYTES32" \
    "$ZK_TYPE_ENUM" \
    "$JOURNAL" \
    "$ONCHAIN_PROOF" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --gas-limit 3000000

echo
echo "=== Agent validated successfully! ==="

