#!/bin/bash
set -e

# Load environment variables
if [ ! -f .env ]; then
    echo "Error: .env file not found"
    exit 1
fi
source .env

PROOF_PATH=${PROOF_PATH:-proof.json}

echo "=== Nitro Attestation Proof Service ==="
echo "Service URL: $ETH_PROVER_SERVICE_URL"
echo "Attestation URL: $ATTESTATION_URL"
echo

# Upload attestation
echo "Uploading attestation..."
RESPONSE=$(curl -s -X POST "$ETH_PROVER_SERVICE_URL/upload" \
    -H "Content-Type: application/json" \
    -d "{\"url\": \"$ATTESTATION_URL\"}")

echo "$RESPONSE" | jq .
DIR_NAME=$(echo "$RESPONSE" | jq -r '.directory_name')

if [ "$DIR_NAME" = "null" ] || [ -z "$DIR_NAME" ]; then
    echo "Error: Failed to upload attestation"
    exit 1
fi

echo
echo "Directory: $DIR_NAME"
echo "Polling for proof (timeout: 100s)..."
echo

# Poll for proof with 100 second total timeout
START_TIME=$(date +%s)
TIMEOUT=100

while true; do
    ELAPSED=$(($(date +%s) - START_TIME))
    
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "Timeout: Proof not ready after ${TIMEOUT}s"
        exit 1
    fi
    
    STATUS_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" "$ETH_PROVER_SERVICE_URL/proof/$DIR_NAME")
    HTTP_STATUS=$(echo "$STATUS_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
    BODY=$(echo "$STATUS_RESPONSE" | sed '/HTTP_STATUS/d')
    
    if [ "$HTTP_STATUS" = "200" ]; then
        echo "Proof ready! Downloading..."
        PROOF_FILE="proof_${DIR_NAME}.json"
        curl -s "$ETH_PROVER_SERVICE_URL/proof/$DIR_NAME" -o "$PROOF_FILE"
        echo "Saved to: $PROOF_FILE"
        exit 0
    elif [ "$HTTP_STATUS" = "202" ]; then
        echo "[${ELAPSED}s] Processing..."
        echo "$BODY"
        echo "$HTTP_STATUS"
        sleep 5
    else
        echo "Error (HTTP $HTTP_STATUS):"
        echo "$BODY"
        exit 1
    fi
done

