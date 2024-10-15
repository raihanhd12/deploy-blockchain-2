#!/bin/bash

LOG_DIR="logs"
BOOTNODES_FILE="bootnodes.txt"
NODE_ADDRESS_DIR="NodeAddresses"
QUORUM_EXPLORER_DIR="quorum-explorer"

# Create log directory and node address directory if they don't exist
mkdir -p "${LOG_DIR}"
mkdir -p "${NODE_ADDRESS_DIR}"

# Function to start a node
start_node() {
    local NODE_DIR=$1
    local NODE_NUMBER=$2
    local P2P_PORT=$((30303 + NODE_NUMBER - 1))
    local RPC_HTTP_PORT=$((8545 + NODE_NUMBER - 1))

    # Check if the node is already running
    NODE_PID=$(ps -ef | grep 'besu' | grep "$NODE_DIR" | grep -v 'grep' | awk '{print $2}')
    if [ -n "$NODE_PID" ]; then
        echo "Node $NODE_DIR is already running with PID $NODE_PID."
        return
    fi

    echo "Starting $NODE_DIR..."
    if [ "$NODE_NUMBER" -eq 1 ]; then
        nohup besu --data-path="${NODE_DIR}/data" \
            --genesis-file="${NODE_DIR}/../genesis.json" \
            --p2p-port=${P2P_PORT} \
            --rpc-http-enabled \
            --rpc-http-api=EEA,WEB3,ETH,NET,TRACE,DEBUG,ADMIN,TXPOOL,PERM,QBFT \
            --host-allowlist="*" \
            --rpc-http-port=${RPC_HTTP_PORT} \
            --rpc-http-cors-origins="*" \
            --min-gas-price=0 > "${LOG_DIR}/node${NODE_NUMBER}.log" 2>&1 &
    else
        nohup besu --data-path="${NODE_DIR}/data" \
            --genesis-file="${NODE_DIR}/../genesis.json" \
            --bootnodes="$(cat $BOOTNODES_FILE)" \
            --p2p-port=${P2P_PORT} \
            --rpc-http-enabled \
            --rpc-http-api=EEA,WEB3,ETH,NET,TRACE,DEBUG,ADMIN,TXPOOL,PERM,QBFT \
            --host-allowlist="*" \
            --rpc-http-port=${RPC_HTTP_PORT} \
            --rpc-http-cors-origins="*" \
            --min-gas-price=0 > "${LOG_DIR}/node${NODE_NUMBER}.log" 2>&1 &
    fi

    # Wait for the node to start
    sleep 10

    # Capture the node address and save it to the NodeAddresses directory
    NODE_ADDRESS=$(grep -o "Node address [^ ]*" "${LOG_DIR}/node${NODE_NUMBER}.log" | awk '{print $3}')
    echo "$NODE_ADDRESS" > "${NODE_ADDRESS_DIR}/${NODE_DIR}.address"

    echo "$NODE_DIR started successfully."
}

# Start Node-1 as the bootnode and redirect output to log file
start_node "Node-1" 1

# Capture the enode URL from the log file and save it to bootnodes.txt
ENODE_URL=$(grep -o "enode://[^@]*@[^:]*:[0-9]*" "${LOG_DIR}/node1.log")

if [ -z "$ENODE_URL" ]; then
    echo "Failed to capture Node-1 enode URL."
    exit 1
fi

echo "Node-1 started with enode URL: $ENODE_URL"
echo "$ENODE_URL" > "$BOOTNODES_FILE"

# Start subsequent nodes dynamically
NODE_COUNTER=2
for NODE_DIR in Node-*; do
    if [ "$NODE_DIR" != "Node-1" ] && [ -d "$NODE_DIR" ]; then
        start_node "$NODE_DIR" "$NODE_COUNTER"
        NODE_COUNTER=$((NODE_COUNTER + 1))
    fi
done

echo "All nodes started successfully."

# Ensure the quorum-explorer.log file exists
touch "${LOG_DIR}/quorum-explorer.log"

# Start Quorum Explorer
cd "${QUORUM_EXPLORER_DIR}"
echo "Starting Quorum Explorer..."
npm install >> "../${LOG_DIR}/quorum-explorer.log" 2>&1
nohup npm run dev >> "../${LOG_DIR}/quorum-explorer.log" 2>&1 &
echo "Quorum Explorer started successfully."
