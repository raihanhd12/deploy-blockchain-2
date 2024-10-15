#!/bin/bash

LOG_DIR="logs"
QUORUM_EXPLORER_LOG="${LOG_DIR}/quorum-explorer.log"

# Find all running besu processes and terminate them
echo "Stopping all besu nodes..."

# Get the list of process IDs for besu
PIDS=$(ps -ef | grep 'besu' | grep -v 'grep' | awk '{print $2}')

if [ -z "$PIDS" ]; then
    echo "No besu nodes are running."
else
    # Terminate each process
    for PID in $PIDS; do
        echo "Stopping besu node with PID $PID"
        kill -9 $PID
    done
    echo "All besu nodes stopped successfully."
fi

# Find and stop the Quorum Explorer process
echo "Stopping Quorum Explorer..."

# Get the process ID for Quorum Explorer
EXPLORER_PID=$(ps -ef | grep 'npm run dev' | grep -v 'grep' | awk '{print $2}')

if [ -z "$EXPLORER_PID" ]; then
    echo "Quorum Explorer is not running."
else
    # Terminate the process
    echo "Stopping Quorum Explorer with PID $EXPLORER_PID"
    kill -9 $EXPLORER_PID
    echo "Quorum Explorer stopped successfully."
fi

# Remove the quorum-explorer.log file
if [ -f "$QUORUM_EXPLORER_LOG" ]; then
    echo "Removing Quorum Explorer log file..."
    rm "$QUORUM_EXPLORER_LOG"
    echo "Quorum Explorer log file removed successfully."
else
    echo "Quorum Explorer log file does not exist."
fi
