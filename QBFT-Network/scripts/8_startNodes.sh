#!/bin/bash

if [ -z "$1" ]; then
   echo "Usage: $0 <Node-X>"
   exit 1
fi

NODE_DIR="$1"
GENESIS_FILE="genesis.json"
LOG_DIR="logs"
BOOTNODES_FILE="bootnodes.txt"
NODE_ADDRESS_DIR="NodeAddresses"

# Check if the node directory exists
if [ ! -d "$NODE_DIR" ]; then
   echo "Node directory $NODE_DIR does not exist. Add Validator first!"
   exit 1
fi

# Tentukan port RPC dan P2P berdasarkan node
NODE_NUMBER=$(echo $NODE_DIR | grep -o '[0-9]*')
P2P_PORT=$((30303 + NODE_NUMBER - 1))
RPC_HTTP_PORT=$((8545 + NODE_NUMBER - 1))

# Check if the node is already running
NODE_PID=$(ps -ef | grep 'besu' | grep "$NODE_DIR" | grep -v 'grep' | awk '{print $2}')
if [ -n "$NODE_PID" ]; then
    echo "Node $NODE_DIR is already running with PID $NODE_PID."
    exit 1
fi

# Mulai node
echo "Starting $NODE_DIR..."
nohup besu --data-path="${NODE_DIR}/data" \
    --genesis-file="${GENESIS_FILE}" \
    --bootnodes="$(cat $BOOTNODES_FILE)" \
    --p2p-port=${P2P_PORT} \
    --rpc-http-enabled \
    --rpc-http-api=EEA,WEB3,ETH,NET,TRACE,DEBUG,ADMIN,TXPOOL,PERM,QBFT \
    --host-allowlist="*" \
    --rpc-http-port=${RPC_HTTP_PORT} \
    --rpc-http-cors-origins="*" \
    --min-gas-price=0 > "${LOG_DIR}/node${NODE_NUMBER}.log" 2>&1 &

# Wait for the node to start
sleep 10

# Capture the node address and save it to the NodeAddresses directory
NODE_ADDRESS=$(grep -o "Node address [^ ]*" "${LOG_DIR}/node${NODE_NUMBER}.log" | awk '{print $3}')
echo "$NODE_ADDRESS" > "${NODE_ADDRESS_DIR}/${NODE_DIR}.address"

echo "$NODE_DIR started successfully."
