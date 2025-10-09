#!/bin/bash
set -euo pipefail

# Usage: ./scripts/explore-agents.sh <REGISTRY_ADDRESS> <RPC_URL>

if [ $# -ne 2 ]; then
    echo "Usage: $0 <REGISTRY_ADDRESS> <RPC_URL>"
    exit 1
fi

REGISTRY="$1"
RPC_URL="$2"

# Check for cast command
if ! command -v cast >/dev/null 2>&1; then
    echo "Error: cast command not found (install foundry)"
    exit 1
fi

# Get agent IDs from agentList
AGENT_LIST_RAW=$(cast call "$REGISTRY" "getAgentList()(uint256[])" --rpc-url "$RPC_URL" 2>/dev/null || echo "")

if [ -z "$AGENT_LIST_RAW" ]; then
    echo "Error: Failed to read agentList from contract"
    exit 1
fi

# Parse agent IDs
AGENT_IDS=$(echo "$AGENT_LIST_RAW" | tr -d '[]' | tr ',' ' ')

# Get agent count
AGENT_COUNT=$(cast call "$REGISTRY" "getAgentCount()(uint256)" --rpc-url "$RPC_URL" 2>/dev/null || echo "0")

if [ "$AGENT_COUNT" -eq 0 ]; then
    echo "No agents registered"
    exit 0
fi

# Print header
echo
echo "═══════════════════════════════════════════════════════════════════════════════════════════════════"
echo "                                     Registered Agents ($AGENT_COUNT)"
echo "═══════════════════════════════════════════════════════════════════════════════════════════════════"
echo
printf "%-10s %-45s %-20s %-30s\n" "ID" "URL" "TEE Arch" "Code Measurement"
echo "───────────────────────────────────────────────────────────────────────────────────────────────────────"

# Iterate through agents
for AGENT_ID in $AGENT_IDS; do
    AGENT_DATA=$(cast call "$REGISTRY" "agents(uint256)(uint256,bytes32,bytes32,bytes,string)" "$AGENT_ID" --rpc-url "$RPC_URL" 2>/dev/null || echo "")
    
    if [ -z "$AGENT_DATA" ]; then
        printf "%-10s %s\n" "$AGENT_ID" "Error reading agent data"
        continue
    fi
    
    # Parse response
    RETURNED_AGENT_ID=$(echo "$AGENT_DATA" | sed -n '1p')
    TEE_ARCH_HEX=$(echo "$AGENT_DATA" | sed -n '2p')
    CODE_MEASUREMENT_HEX=$(echo "$AGENT_DATA" | sed -n '3p')
    PUBKEY_HEX=$(echo "$AGENT_DATA" | sed -n '4p')
    URL=$(echo "$AGENT_DATA" | sed -n '5p')
    
    # Convert TEE arch
    TEE_ARCH=$(cast --to-ascii "$TEE_ARCH_HEX" 2>/dev/null | tr -d '\0' || echo "$TEE_ARCH_HEX")
    
    # Truncate URL
    if [ ${#URL} -gt 43 ]; then
        URL_DISPLAY="${URL:0:40}..."
    else
        URL_DISPLAY="$URL"
    fi
    
    # Truncate code measurement
    if [ ${#CODE_MEASUREMENT_HEX} -gt 30 ]; then
        CODE_MEASUREMENT_DISPLAY="${CODE_MEASUREMENT_HEX:0:27}..."
    else
        CODE_MEASUREMENT_DISPLAY="$CODE_MEASUREMENT_HEX"
    fi
    
    printf "%-10s %-45s %-20s %-30s\n" "$RETURNED_AGENT_ID" "$URL_DISPLAY" "$TEE_ARCH" "$CODE_MEASUREMENT_DISPLAY"
done

echo "───────────────────────────────────────────────────────────────────────────────────────────────────────"
echo
