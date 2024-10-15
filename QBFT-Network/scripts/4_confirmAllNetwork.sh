#!/bin/bash

LOG_DIR="logs"
NODE_ADDRESS_DIR="NodeAddresses"

# Function to confirm the network status for a given RPC URL
confirm_network() {
    local RPC_URL=$1
    local NODE_NAME=$2

    # JSON-RPC request payload
    PAYLOAD='{"jsonrpc":"2.0","method":"qbft_getValidatorsByBlockNumber","params":["latest"], "id":1}'

    # Make the JSON-RPC API call using curl and parse the response using jq
    RESPONSE=$(curl -s -X POST --data "$PAYLOAD" $RPC_URL | jq)

    if [ -z "$RESPONSE" ]; then
        echo "Node $NODE_NAME ($RPC_URL) is stopped or not responding."
        echo "validators[$NODE_NAME]=stopped" >> $LOG_DIR/validator_count.log
        return
    fi

    # Display the response
    echo "Response from JSON-RPC API for $NODE_NAME ($RPC_URL):"
    echo "$RESPONSE"

    # Extract and count the number of validators
    VALIDATORS=$(echo "$RESPONSE" | jq '.result | length')

    echo "Number of validators for $NODE_NAME: $VALIDATORS"

    # Confirm the network has at least four validators
    if [ "$VALIDATORS" -ge 4 ]; then
        echo "The private network is working correctly with at least four validators for $NODE_NAME."
    else
        echo "The private network does not have four validators for $NODE_NAME."
    fi

    echo "validators[$NODE_NAME]=$VALIDATORS" >> $LOG_DIR/validator_count.log
    echo ""
}

# Loop through each node directory and confirm the network status
NODE_COUNTER=1
> $LOG_DIR/validator_count.log
for NODE_DIR in Node-*; do
    if [ -d "$NODE_DIR" ]; then
        RPC_HTTP_PORT=$((8545 + NODE_COUNTER - 1))
        RPC_URL="http://localhost:${RPC_HTTP_PORT}"
        confirm_network "$RPC_URL" "$NODE_DIR"
        NODE_COUNTER=$((NODE_COUNTER + 1))
    fi
done

echo "Network confirmation completed for all nodes."

# Display summary
echo "Summary of validators count for each node:"
cat $LOG_DIR/validator_count.log | while read line; do
    echo "$line"
done
