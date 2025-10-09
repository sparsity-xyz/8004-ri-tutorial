#!/bin/bash
set -e

# Rich, parameterized proof request script.
# Features: colored output, configurable timeout/interval, JSON validation, timestamped filename, summary.

# Color handling
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
highlight(){ [ "$QUIET" = "1" ] || printf "%b%s%b\n" "${BOLD}${YELLOW}" "[NEXT] $*" "${RESET}"; }

trap 'err "Script failed at line $LINENO"; exit 1' ERR

usage(){ cat <<EOF
Usage: $0 [options]
    -t, --timeout SEC     Total timeout seconds (default 150)
    -i, --interval SEC    Poll interval seconds (default 5)
    -o, --output FILE     Explicit output file (default: proof_<dir>_<ts>.json)
            --no-color        Disable colored output
    -q, --quiet           Suppress progress logs (errors still print)
    -h, --help            Show this help
EOF
}

TIMEOUT=150
INTERVAL=5
OUTPUT_FILE=""
QUIET=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--timeout) TIMEOUT="$2"; shift 2;;
        -i|--interval) INTERVAL="$2"; shift 2;;
        -o|--output) OUTPUT_FILE="$2"; shift 2;;
        --no-color) NO_COLOR=1; shift;;
        -q|--quiet) QUIET=1; shift;;
        -h|--help) usage; exit 0;;
        *) err "Unknown argument: $1"; usage; exit 1;;
    esac
done

step "Checking required tools"
MISSING_TOOLS=()
for t in curl jq; do
    command -v "$t" >/dev/null 2>&1 || MISSING_TOOLS+=("$t")
done
if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    err "Missing required tools: ${MISSING_TOOLS[*]}"; exit 1
fi
success "Toolchain OK (curl, jq)"

START_TS_READABLE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
START_TIME=$(date +%s)

# Load env
if [ ! -f .env ]; then err ".env file not found, please create one based on .env.example"; exit 1; fi
source .env
step "Loaded .env file"

# Validate required vars
step "Validating required environment variables"
if [ -z "$ETH_PROVER_SERVICE_URL" ] || [ -z "$ATTESTATION_URL" ] || [ -z "$ETH_ADDRESS" ]; then
    err "ETH_PROVER_SERVICE_URL, ATTESTATION_URL, and ETH_ADDRESS must be set in .env"; exit 1; fi
success "Environment variables present"

# Simple ETH address format validation (0x + 40 hex chars)
if [[ ! "$ETH_ADDRESS" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
    err "ETH_ADDRESS '$ETH_ADDRESS' is not a valid hex address (expected 0x followed by 40 hex characters)"; exit 1
fi
success "ETH address format valid"


step "Proof request context"
info "Service URL: $ETH_PROVER_SERVICE_URL"
info "Attestation URL: $ATTESTATION_URL"
info "ETH Address: $ETH_ADDRESS"
info "Timeout: ${TIMEOUT}s | Interval: ${INTERVAL}s"

step "Uploading attestation"
UPLOAD_RESPONSE=$(curl -s -X POST "$ETH_PROVER_SERVICE_URL/upload" -H "Content-Type: application/json" -d "{\"url\": \"$ATTESTATION_URL\", \"eth_address\": \"$ETH_ADDRESS\"}")

if ! echo "$UPLOAD_RESPONSE" | jq . >/dev/null 2>&1; then
    warn "Upload response not valid JSON"
    echo "$UPLOAD_RESPONSE"
else
    info "Upload response:"
    echo "$UPLOAD_RESPONSE" | jq .
fi

DIR_NAME=$(echo "$UPLOAD_RESPONSE" | jq -r '.directory_name' 2>/dev/null || true)
if [ -z "$DIR_NAME" ] || [ "$DIR_NAME" = "null" ]; then
    err "Upload failed (no directory_name in response)"; 
    exit 1; 
fi
success "Upload accepted (directory: $DIR_NAME)"

step "Polling for proof"
info "Polling started at: $START_TS_READABLE (UTC)"

while true; do
    ELAPSED=$(( $(date +%s) - START_TIME ))
    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then err "Timeout: proof not ready after ${TIMEOUT}s"; exit 1; fi

    STATUS_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" "$ETH_PROVER_SERVICE_URL/proof/$DIR_NAME")
    HTTP_STATUS=$(echo "$STATUS_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
    BODY=$(echo "$STATUS_RESPONSE" | sed '/HTTP_STATUS/d')

    case "$HTTP_STATUS" in
        200)
            success "Proof ready (elapsed ${ELAPSED}s)"
            if [ -z "$OUTPUT_FILE" ]; then
                OUTPUT_FILE="proof_${DIR_NAME}.json"
            fi
            echo "$BODY" > "$OUTPUT_FILE"
            success "Saved proof to $OUTPUT_FILE"
            if jq -e '.raw_proof.journal and .onchain_proof' "$OUTPUT_FILE" >/dev/null 2>&1; then
                success "Proof file structure validated"
            else
                warn "Proof file missing expected fields"
            fi
            END_TIME=$(date +%s)
            TOTAL=$((END_TIME-START_TIME))
            echo
            step "Summary"
            info "Directory: $DIR_NAME"
            info "Elapsed: ${TOTAL}s"
            info "Output: $OUTPUT_FILE"
            highlight "Next: ./scripts/validate-agent.sh --proof-path $OUTPUT_FILE"
            exit 0
            ;;
        202)
            info "[${ELAPSED}s] Processing (HTTP 202)"
            STAGE=$(echo "$BODY" | jq -r '.stage // empty' 2>/dev/null || true)
            [ -n "$STAGE" ] && info "Stage: $STAGE"
            SUCCINCT_EXPLORER_URL=$(echo "$BODY" | jq -r '.succinct_explorer_url // empty' 2>/dev/null || true)
            if [ -n "$SUCCINCT_EXPLORER_URL" ] && [ "$SUCCINCT_EXPLORER_URL" != "null" ]; then
                info "Request Succinct Explorer URL: $SUCCINCT_EXPLORER_URL"
            fi
            sleep "$INTERVAL"
            ;;
        *)
            err "Unexpected HTTP status $HTTP_STATUS"; echo "$BODY" | jq . 2>/dev/null || echo "$BODY"; exit 1
            ;;
    esac
done

