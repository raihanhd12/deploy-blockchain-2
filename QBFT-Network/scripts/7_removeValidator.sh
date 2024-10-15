#!/bin/bash

# Check if a node name is provided as a parameter
if [ -z "$1" ]; then
    echo "Usage: $0 <node-name>"
    exit 1
fi

NODE_NAME=$1
LOG_DIR="logs"
NODE_ADDRESS_DIR="NodeAddresses"
CONFIG_FILE="quorum-explorer/src/config/config.json"
ADDRESS_FILE="${NODE_ADDRESS_DIR}/${NODE_NAME}.address"

# Check if the address file exists
if [ ! -f "$ADDRESS_FILE" ]; then
    echo "No address file found for node ${NODE_NAME}."
    exit 1
fi

VALIDATOR_ADDRESS=$(cat "$ADDRESS_FILE")

# Get all existing node directories and calculate the majority
EXISTING_NODE_COUNT=$(ls -d Node-* | wc -l)
MAJORITY_COUNT=$(( (EXISTING_NODE_COUNT / 2) + 1 ))

# Discard any pending votes to add or remove the validator from a majority of existing nodes
echo "Discarding any pending votes for validator ${VALIDATOR_ADDRESS} from ${MAJORITY_COUNT} nodes..."
for i in $(seq 1 $EXISTING_NODE_COUNT); do
    RPC_PORT=$((8544 + i))
    echo "Discarding vote from node with RPC port ${RPC_PORT}..."
    RESPONSE=$(curl -s -m 10 -X POST --data '{"jsonrpc":"2.0","method":"qbft_discardValidatorVote","params":["'"${VALIDATOR_ADDRESS}"'"], "id":1}' http://127.0.0.1:${RPC_PORT})
    if echo "$RESPONSE" | grep -q '"result":true'; then
        echo "Vote discarded from node with RPC port ${RPC_PORT}."
    else
        echo "Failed to discard vote from node with RPC port ${RPC_PORT}. Response: $RESPONSE"
    fi
    echo ""
done

# Propose removing the validator from a majority of existing nodes
echo "Proposing to remove validator ${VALIDATOR_ADDRESS} from ${MAJORITY_COUNT} nodes..."
VALIDATOR_VOTE_COUNT=0
for i in $(seq 1 $EXISTING_NODE_COUNT); do
    if [ $VALIDATOR_VOTE_COUNT -ge $MAJORITY_COUNT ]; then
        break
    fi
    RPC_PORT=$((8544 + i))
    echo "Proposing to remove validator from node with RPC port ${RPC_PORT}..."
    RESPONSE=$(curl -s -m 10 -X POST --data '{"jsonrpc":"2.0","method":"qbft_proposeValidatorVote","params":["'"${VALIDATOR_ADDRESS}"'", false], "id":1}' http://127.0.0.1:${RPC_PORT})
    if echo "$RESPONSE" | grep -q '"result":true'; then
        VALIDATOR_VOTE_COUNT=$((VALIDATOR_VOTE_COUNT + 1))
        echo "Validator removal vote succeeded from node with RPC port ${RPC_PORT}."
    else
        echo "Validator removal vote failed from node with RPC port ${RPC_PORT}. Response: $RESPONSE"
    fi
    echo ""
done

if [ $VALIDATOR_VOTE_COUNT -ge $MAJORITY_COUNT ]; then
    echo "Validator ${VALIDATOR_ADDRESS} removed successfully."
    # Ensure no background process is running for the node
    pkill -f "${NODE_NAME}/data" || true

    # Remove the node directory, address file, and log file
    NODE_PATH="${NODE_NAME}"
    if [ -d "$NODE_PATH" ]; then
        rm -rf "$NODE_PATH"
        echo "Node directory ${NODE_PATH} removed successfully."
    else
        echo "Node directory ${NODE_PATH} not found."
    fi
    if [ -f "$ADDRESS_FILE" ]; then
        rm "$ADDRESS_FILE"
        echo "Node address file ${ADDRESS_FILE} removed successfully."
    else
        echo "Node address file ${ADDRESS_FILE} not found."
    fi
    LOG_FILE="${LOG_DIR}/node${NODE_NAME##*-}.log"
    if [ -f "$LOG_FILE" ]; then
        rm "$LOG_FILE"
        echo "Log file ${LOG_FILE} removed successfully."
    else
        echo "Log file ${LOG_FILE} not found."
    fi

    # Update config.json for Quorum Explorer
    jq --arg rpcUrl "http://localhost:$((8544 + ${NODE_NAME##*-}))" 'del(.nodes[] | select(.rpcUrl == $rpcUrl))' ${CONFIG_FILE} > tmp.$$.json && mv tmp.$$.json ${CONFIG_FILE}
    echo "Updated Quorum Explorer config by removing validator node ${NODE_NAME} with address ${VALIDATOR_ADDRESS}."
else
    echo "Failed to get majority vote for removing validator ${VALIDATOR_ADDRESS}."
    exit 1
fi
