#!/bin/bash
set -euo pipefail

#
# explore-agents.sh - Query and display registered agents from TEE validation registry
#
# This script queries the TEEValidationRegistry contract to list all registered agents
# and their details including URL, TEE architecture, code measurement, and public key.
#
# Usage:
#   ./scripts/explore-agents.sh                    # List all agents (table format)
#   ./scripts/explore-agents.sh --agent-id 1       # Show details for agent ID 1
#   ./scripts/explore-agents.sh --format json      # Output as JSON
#   ./scripts/explore-agents.sh --format csv       # Output as CSV
#   ./scripts/explore-agents.sh --quiet            # Suppress progress messages
#

# Color & logging helpers
if [ -t 1 ] && [ "${NO_COLOR:-0}" != "1" ]; then
	RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[0;33m"; BLUE="\033[0;34m"; BOLD="\033[1m"; RESET="\033[0m"
else
	RED=""; GREEN=""; YELLOW=""; BLUE=""; BOLD=""; RESET=""
fi
info(){ [ "$QUIET" = "1" ] || printf "%b%s%b\n" "${BLUE}" "[INFO] $*" "${RESET}"; }
step(){ [ "$QUIET" = "1" ] || printf "%b%s%b\n" "${BOLD}${BLUE}" "==> $*" "${RESET}"; }
success(){ [ "$QUIET" = "1" ] || printf "%b%s%b\n" "${GREEN}" "[OK] $*" "${RESET}"; }
warn(){ [ "$QUIET" = "1" ] || printf "%b%s%b\n" "${YELLOW}" "[WARN] $*" "${RESET}"; }
err(){ printf "%b%s%b\n" "${RED}" "[ERROR] $*" "${RESET}" 1>&2; }
highlight(){ [ "$QUIET" = "1" ] || printf "%b%s%b\n" "${BOLD}${YELLOW}" "$*" "${RESET}"; }

trap 'err "Script failed at line $LINENO"; exit 1' ERR

usage(){ cat <<EOF
Usage: $0 [options]
    -f, --format FORMAT   Output format: table (default), json, csv
    -a, --agent-id ID     Show details for specific agent ID only
    -q, --quiet           Suppress progress messages
    --no-color            Disable colored output
    -h, --help            Show this help
EOF
}

# Parse arguments
FORMAT="table"
AGENT_ID=""
QUIET=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--format) FORMAT="$2"; shift 2;;
        -a|--agent-id) AGENT_ID="$2"; shift 2;;
        -q|--quiet) QUIET=1; shift;;
        --no-color) NO_COLOR=1; shift;;
        -h|--help) usage; exit 0;;
        *) err "Unknown argument: $1"; usage; exit 1;;
    esac
done

# Validate format
if [[ ! "$FORMAT" =~ ^(table|json|csv)$ ]]; then
    err "Invalid format: $FORMAT (must be table, json, or csv)"
    exit 1
fi

# Load environment variables
if [ ! -f .env ]; then
    err ".env file not found, please create one based on .env.example"
    exit 1
fi
source .env
step "Loaded .env file"

# Check required variables
step "Validating environment variables"
if [ -z "$REGISTRY" ] || [ -z "$RPC_URL" ]; then
    err "REGISTRY and RPC_URL must be set in .env"
    exit 1
fi
success "Environment validation passed"

# Check for cast command
if ! command -v cast >/dev/null 2>&1; then
    err "cast command not found (install foundry: https://book.getfoundry.sh/getting-started/installation)"
    exit 1
fi
success "Foundry cast available"

step "Querying registry contract"
info "Registry: $REGISTRY"
info "RPC URL: $RPC_URL"

# Get agent IDs from agentList array
step "Fetching agent list from contract"
AGENT_LIST_RAW=$(cast call "$REGISTRY" "getAgentList()(uint256[])" --rpc-url "$RPC_URL" 2>/dev/null || echo "")

if [ -z "$AGENT_LIST_RAW" ]; then
    err "Failed to read agentList from contract"
    exit 1
fi

# Parse the array - cast returns array in format [id1,id2,id3,...]
# Remove brackets and split by comma
AGENT_IDS=$(echo "$AGENT_LIST_RAW" | tr -d '[]' | tr ',' ' ')

# Count agents
AGENT_COUNT=$(cast call "$REGISTRY" "getAgentCount()(uint256)" --rpc-url "$RPC_URL" 2>/dev/null || echo "")

if [ "$AGENT_COUNT" -eq 0 ]; then
    warn "No agents registered yet"
    exit 0
fi

success "Found $AGENT_COUNT registered agent(s)"

# If specific agent ID requested, show only that one
if [ -n "$AGENT_ID" ]; then
    step "Fetching details for agent ID: $AGENT_ID"
    
    # Call agents mapping
    # Returns: struct Agent { uint256 agentId, bytes32 teeArch, bytes32 codeMeasurement, bytes pubkey, string url }
    AGENT_DATA=$(cast call "$REGISTRY" "agents(uint256)(uint256,bytes32,bytes32,bytes,string)" "$AGENT_ID" --rpc-url "$RPC_URL" 2>/dev/null || echo "")
    
    if [ -z "$AGENT_DATA" ]; then
        err "Agent ID $AGENT_ID not found or error reading from contract"
        exit 1
    fi
    
    # Parse the tuple response (5 fields)
    RETURNED_AGENT_ID=$(echo "$AGENT_DATA" | sed -n '1p')
    TEE_ARCH_HEX=$(echo "$AGENT_DATA" | sed -n '2p')
    CODE_MEASUREMENT_HEX=$(echo "$AGENT_DATA" | sed -n '3p')
    PUBKEY_HEX=$(echo "$AGENT_DATA" | sed -n '4p')
    URL=$(echo "$AGENT_DATA" | sed -n '5p')
    
    # Convert TEE arch from bytes32 to string using cast
    TEE_ARCH=$(cast --to-ascii "$TEE_ARCH_HEX" 2>/dev/null | tr -d '\0' || echo "$TEE_ARCH_HEX")
    
    # Code measurement should stay as hex (it's a hash)
    CODE_MEASUREMENT="$CODE_MEASUREMENT_HEX"
    
    if [ "$FORMAT" = "json" ]; then
        cat <<JSON
{
  "agentId": $RETURNED_AGENT_ID,
  "url": $URL,
  "teeArch": "$TEE_ARCH",
  "codeMeasurement": "$CODE_MEASUREMENT_HEX",
  "pubkey": "$PUBKEY_HEX"
}
JSON
    else
        echo
        highlight "═══════════════════════════════════════════════════════════════════"
        highlight "                         Agent Details"
        highlight "═══════════════════════════════════════════════════════════════════"
        echo
        printf "%b%-20s%b %s\n" "${BOLD}" "Agent ID:" "${RESET}" "$RETURNED_AGENT_ID"
        printf "%b%-20s%b %s\n" "${BOLD}" "URL:" "${RESET}" "$URL"
        printf "%b%-20s%b %s\n" "${BOLD}" "TEE Architecture:" "${RESET}" "$TEE_ARCH"
        printf "%b%-20s%b %s\n" "${BOLD}" "Code Measurement:" "${RESET}" "$CODE_MEASUREMENT_HEX"
        printf "%b%-20s%b\n%s\n" "${BOLD}" "Public Key:" "${RESET}" "$PUBKEY_HEX"
        echo
    fi
    
    exit 0
fi

# List all agents
step "Fetching all registered agents"

# Prepare output based on format
if [ "$FORMAT" = "json" ]; then
    echo "["
fi

if [ "$FORMAT" = "csv" ]; then
    echo "AgentID,URL,TEEArch,CodeMeasurement,Pubkey"
fi

if [ "$FORMAT" = "table" ]; then
    echo
    highlight "═══════════════════════════════════════════════════════════════════════════════════════════════════"
    highlight "                                     Registered Agents"
    highlight "═══════════════════════════════════════════════════════════════════════════════════════════════════"
    echo
    printf "%b%-10s %-45s %-20s %-30s%b\n" "${BOLD}" "ID" "URL" "TEE Arch" "Code Measurement" "${RESET}"
    echo "───────────────────────────────────────────────────────────────────────────────────────────────────────"
fi

# Iterate through agent IDs from the agentList
FIRST=true
for AGENT_ID_ITER in $AGENT_IDS; do
    # Get agent data
    # Returns: struct Agent { uint256 agentId, bytes32 teeArch, bytes32 codeMeasurement, bytes pubkey, string url }
    AGENT_DATA=$(cast call "$REGISTRY" "agents(uint256)(uint256,bytes32,bytes32,bytes,string)" "$AGENT_ID_ITER" --rpc-url "$RPC_URL" 2>/dev/null || echo "")
    
    if [ -z "$AGENT_DATA" ]; then
        if [ "$FORMAT" = "table" ]; then
            printf "%-10s %s\n" "$AGENT_ID_ITER" "Error reading agent data"
        fi
        continue
    fi
    
    # Parse response (5 fields)
    RETURNED_AGENT_ID=$(echo "$AGENT_DATA" | sed -n '1p')
    TEE_ARCH_HEX=$(echo "$AGENT_DATA" | sed -n '2p')
    CODE_MEASUREMENT_HEX=$(echo "$AGENT_DATA" | sed -n '3p')
    PUBKEY_HEX=$(echo "$AGENT_DATA" | sed -n '4p')
    URL=$(echo "$AGENT_DATA" | sed -n '5p')
    
    # Convert TEE arch from bytes32 to string using cast
    TEE_ARCH=$(cast --to-ascii "$TEE_ARCH_HEX" 2>/dev/null | tr -d '\0' || echo "$TEE_ARCH_HEX")
    
    # Truncate URL for display
    if [ ${#URL} -gt 43 ]; then
        URL_DISPLAY="${URL:0:40}..."
    else
        URL_DISPLAY="$URL"
    fi
    
    # Truncate code measurement for display (show first 27 chars + ...)
    if [ ${#CODE_MEASUREMENT_HEX} -gt 30 ]; then
        CODE_MEASUREMENT_DISPLAY="${CODE_MEASUREMENT_HEX:0:27}..."
    else
        CODE_MEASUREMENT_DISPLAY="$CODE_MEASUREMENT_HEX"
    fi
    
    case "$FORMAT" in
        json)
            if [ "$FIRST" = true ]; then
                FIRST=false
            else
                echo ","
            fi
            cat <<JSON
  {
    "agentId": $RETURNED_AGENT_ID,
    "url": $URL,
    "teeArch": "$TEE_ARCH",
    "codeMeasurement": "$CODE_MEASUREMENT_HEX",
    "pubkey": "$PUBKEY_HEX"
  }
JSON
            ;;
        csv)
            echo "$RETURNED_AGENT_ID,$URL,\"$TEE_ARCH\",\"$CODE_MEASUREMENT_HEX\",\"$PUBKEY_HEX\""
            ;;
        table)
            printf "%-10s %-45s %-20s %-30s\n" "$RETURNED_AGENT_ID" "$URL_DISPLAY" "$TEE_ARCH" "$CODE_MEASUREMENT_DISPLAY"
            ;;
    esac
done

if [ "$FORMAT" = "json" ]; then
    echo "]"
fi

if [ "$FORMAT" = "table" ]; then
    echo "───────────────────────────────────────────────────────────────────────────────────────────────────────"
    echo
    success "Listed $AGENT_COUNT agent(s)"
    echo
    highlight "View details: ./scripts/explore-agents.sh --agent-id <ID>"
fi

success "Query completed"

