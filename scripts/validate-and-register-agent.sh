#!/bin/bash
set -e

# Color & logging helpers (disable with NO_COLOR=1)
if [ -t 1 ] && [ "${NO_COLOR:-0}" != "1" ]; then
    RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[0;33m"; BLUE="\033[0;34m"; BOLD="\033[1m"; RESET="\033[0m"
else
    RED=""; GREEN=""; YELLOW=""; BLUE=""; BOLD=""; RESET=""
fi
info(){ printf "%b%s%b\n" "${BLUE}" "[INFO] $*" "${RESET}"; }
step(){ printf "%b%s%b\n" "${BOLD}${BLUE}" "==> $*" "${RESET}"; }
success(){ printf "%b%s%b\n" "${GREEN}" "[OK] $*" "${RESET}"; }
warn(){ printf "%b%s%b\n" "${YELLOW}" "[WARN] $*" "${RESET}"; }
err(){ printf "%b%s%b\n" "${RED}" "[ERROR] $*" "${RESET}" 1>&2; }

# High-visibility helper (bold yellow) - respects NO_COLOR
highlight(){ if [ "${NO_COLOR:-0}" = "1" ]; then printf "%s\n" "[INFO] $*"; else printf "%b%s%b\n" "${BOLD}${YELLOW}" "[NEXT] $*" "${RESET}"; fi }

trap 'err "Script failed at line $LINENO"; exit 1' ERR




START_TIME=$(date +%s)

step "Checking required local tools"
MISSING=()
for tool in jq cast xxd; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        MISSING+=("$tool")
    fi
done
if [ ${#MISSING[@]} -gt 0 ]; then
    err "Missing required tools: ${MISSING[*]}"
    echo "Please install them before running this script."
    echo "Hints:"; echo "  jq   : package manager (e.g. apt install jq / brew install jq)"; echo "  cast : from Foundry (curl -L https://foundry.paradigm.xyz | bash; foundryup)"; echo "  xxd  : usually in vim-common (apt install xxd) or comes with macOS"
    exit 1
fi
success "All required tools present (jq, cast, xxd)"

step "Loading environment variables"
if [ ! -f .env ]; then
        err ".env file not found, please create one based on .env.example"
        exit 1
fi
source .env
success ".env loaded"

step "Validating required environment variables"
if [ -z "$REGISTRY" ] || [ -z "$RPC_URL" ] || [ -z "$PRIVATE_KEY" ] || [ -z "$IDENTITY_REGISTRY" ]; then
    err "REGISTRY, RPC_URL, PRIVATE_KEY, and IDENTITY_REGISTRY must be set in .env"
    exit 1
fi
success "Environment variables present"

# Default parameters (can be overridden by environment or CLI)
PROOF_PATH=${PROOF_PATH:-proof.json}
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

step "Validation context"
info "Registry: $REGISTRY"
info "Agent URL: $AGENT_URL"
info "TEE Arch: $TEE_ARCH"
info "Proof path: $PROOF_PATH"
echo

step "Checking proof file"
if [ ! -f "$PROOF_PATH" ]; then
    err "Proof file not found at '$PROOF_PATH'"
    exit 1
fi
success "Found proof file"

step "Parsing proof JSON"
JOURNAL=$(jq -r '.raw_proof.journal' "$PROOF_PATH")
ONCHAIN_PROOF=$(jq -r '.onchain_proof' "$PROOF_PATH")
PROOF_TYPE=$(jq -r '.proof_type' "$PROOF_PATH")
ZK_TYPE=$(jq -r '.zktype' "$PROOF_PATH")
success "Parsed proof JSON"

step "Verifying proof type"
if [ "$PROOF_TYPE" != "Verifier" ]; then
    err "Expected proof_type 'Verifier', got: $PROOF_TYPE"
    exit 1
fi
success "Proof type verified (Verifier)"

step "Mapping zk type to enum"
if [ "$ZK_TYPE" = "Risc0" ]; then
    ZK_TYPE_ENUM=1
    info "ZK_TYPE: Risc0 -> 1"
elif [ "$ZK_TYPE" = "Succinct" ]; then
    ZK_TYPE_ENUM=2
    info "ZK_TYPE: Succinct -> 2"
else
    err "Unknown zktype: $ZK_TYPE"
    exit 1
fi
success "ZK type mapping complete"

# Convert TEE arch to bytes32
TEE_ARCH_BYTES32=$(echo -n "$TEE_ARCH" | xxd -p | tr -d '\n' | awk '{printf "0x%-64s\n", $0}' | sed 's/ /0/g')

step "Converted metadata"
info "TEE Arch (bytes32): $TEE_ARCH_BYTES32"
info "ZK Type (enum): $ZK_TYPE_ENUM ($ZK_TYPE)"
echo

# First check if zkVerifier is set
step "Checking zkVerifier"
ZK_VERIFIER=$(cast call "$REGISTRY" "zkVerifier()(address)" --rpc-url "$RPC_URL")
info "zkVerifier: $ZK_VERIFIER"
if [ "$ZK_VERIFIER" = "0x0000000000000000000000000000000000000000" ]; then
    err "zkVerifier is not set in registry"
    exit 1
fi
success "zkVerifier present"
echo

# Call registerAgent with correct parameter order from interface
step "Sending registerAgent transaction"
RESULT=$(cast send "$REGISTRY" \
    "registerAgent(string,bytes32,uint8,bytes,bytes)" \
    "$AGENT_URL" \
    "$TEE_ARCH_BYTES32" \
    "$ZK_TYPE_ENUM" \
    "$JOURNAL" \
    "$ONCHAIN_PROOF" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --gas-limit 3000000 \
    --json)
success "Transaction submitted"
echo "$RESULT" | jq . 2>/dev/null || echo "$RESULT"

# Extract agent ID from event logs (third topic in the AgentModified event)
AGENT_ID=$(echo "$RESULT" | jq -r '.logs[0].topics[3]' 2>/dev/null)

END_TIME=$(date +%s)
TOTAL=$((END_TIME-START_TIME))

if [ -n "$AGENT_ID" ] && [ "$AGENT_ID" != "null" ]; then
    AGENT_ID_DEC=$((AGENT_ID))
    success "Agent registered successfully"
    info "Agent ID (uint256): $AGENT_ID_DEC"
    info "Agent ID (hex): $AGENT_ID"
else
    success "Agent registered (no AgentModified event parsed)"
    warn "Could not extract agent ID from transaction logs"
fi

step "Summary"
info "Elapsed: ${TOTAL}s"
info "Registry: $REGISTRY"
info "Agent URL: $AGENT_URL"
info "Proof: $PROOF_PATH"
info "Next: Update agent metadata / publish discovery record if required"

# Derive explorer base URL heuristically
EXPLORER_BASE=""
CHAIN_LOWER="$(echo "${NETWORK:-}" | tr 'A-Z' 'a-z')"
RPC_LOWER="$(echo "${RPC_URL}" | tr 'A-Z' 'a-z')"

if [ -n "$CHAIN_LOWER" ]; then
    case "$CHAIN_LOWER" in
        *base*sepolia*) EXPLORER_BASE="https://sepolia.basescan.org" ;;
        *base*) EXPLORER_BASE="https://basescan.org" ;;
        *sepolia*) EXPLORER_BASE="https://sepolia.etherscan.io" ;;
        *holesky*) EXPLORER_BASE="https://holesky.etherscan.io" ;;
        *goerli*) EXPLORER_BASE="https://goerli.etherscan.io" ;;
        *arbitrum*sepolia*) EXPLORER_BASE="https://sepolia.arbiscan.io" ;;
        *arbitrum*) EXPLORER_BASE="https://arbiscan.io" ;;
        *optimism*sepolia*) EXPLORER_BASE="https://sepolia-optimism.etherscan.io" ;;
        *optimism*) EXPLORER_BASE="https://optimistic.etherscan.io" ;;
        *polygon*amoy*) EXPLORER_BASE="https://www.oklink.com/amoy" ;;
        *polygon*test*) EXPLORER_BASE="https://mumbai.polygonscan.com" ;;
        *polygon*) EXPLORER_BASE="https://polygonscan.com" ;;
    esac
fi

if [ -z "$EXPLORER_BASE" ]; then
    # Fallback: try inferring from RPC URL
    if echo "$RPC_LOWER" | grep -q "base" && echo "$RPC_LOWER" | grep -q "sepolia"; then
        EXPLORER_BASE="https://sepolia.basescan.org"
    elif echo "$RPC_LOWER" | grep -q "base"; then
        EXPLORER_BASE="https://basescan.org"
    elif echo "$RPC_LOWER" | grep -q "sepolia"; then
        EXPLORER_BASE="https://sepolia.etherscan.io"
    fi
fi

if [ -n "$EXPLORER_BASE" ]; then
    step "Explorer references"
    CONTRACT_URL="$EXPLORER_BASE/address/$REGISTRY"
    IDENTITY_CONTRACT_URL="$EXPLORER_BASE/address/$IDENTITY_REGISTRY"
    TXS_URL="$CONTRACT_URL#transactions"
    EVENTS_URL="$CONTRACT_URL#events"
    READ_URL="$CONTRACT_URL#readContract"
    highlight "Contract:    $CONTRACT_URL"
    highlight "Identity Contract:    $IDENTITY_CONTRACT_URL"
    # highlight "Transactions:$TXS_URL"
    # highlight "Events:      $EVENTS_URL"
    # highlight "Read:        $READ_URL"
    if [ -n "$AGENT_ID" ] && [ "$AGENT_ID" != "null" ]; then
        # Agent ID is a hex topic (bytes32). Provide a log search hint.
        SEARCH_ID=$(echo "$AGENT_ID" | sed 's/^0x//')
        # highlight "Search logs for Agent ID topic: $SEARCH_ID"
        highlight "Agent ID (uint256): $AGENT_ID_DEC"
    fi
    else
        warn "Could not derive explorer URL (set NETWORK env var e.g. NETWORK=base-sepolia for links)"
fi

