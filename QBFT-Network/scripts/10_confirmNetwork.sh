#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <Node-X>"
    exit 1
fi

NODE_DIR="$1"
NODE_NUMBER=$(echo $NODE_DIR | grep -o '[0-9]*')
RPC_HTTP_PORT=$((8545 + NODE_NUMBER - 1))
RPC_URL="http://localhost:${RPC_HTTP_PORT}"

# JSON-RPC request payload
PAYLOAD='{"jsonrpc":"2.0","method":"qbft_getValidatorsByBlockNumber","params":["latest"], "id":1}'

# Make the JSON-RPC API call using curl and parse the response using jq
RESPONSE=$(curl -s -X POST --data "$PAYLOAD" $RPC_URL | jq)

if [ -z "$RESPONSE" ]; then
    echo "Node $NODE_DIR ($RPC_URL) is stopped or not responding."
    exit 1
fi

# Display the response
echo "Response from JSON-RPC API for $NODE_DIR ($RPC_URL):"
echo "$RESPONSE"

# Extract and count the number of validators
VALIDATORS=$(echo "$RESPONSE" | jq '.result | length')

echo "Number of validators for $NODE_DIR: $VALIDATORS"

# Confirm the network has at least four validators
if [ "$VALIDATORS" -ge 4 ]; then
    echo "The private network is working correctly with at least four validators for $NODE_DIR."
else
    echo "The private network does not have four validators for $NODE_DIR."
fi
