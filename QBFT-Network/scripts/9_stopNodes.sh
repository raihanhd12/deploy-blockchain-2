#!/bin/bash

if [ -z "$1" ]; then
   echo "Usage: $0 <Node-X>"
   exit 1
fi

NODE_DIR="$1"

# Mendapatkan PID dari node yang berjalan berdasarkan direktori data
NODE_PID=$(ps -ef | grep 'besu' | grep "$NODE_DIR" | grep -v 'grep' | awk '{print $2}')

if [ -z "$NODE_PID" ]; then
   echo "Node $NODE_DIR is not running."
else
   echo "Stopping Besu node with PID $NODE_PID from directory $NODE_DIR..."
   kill -9 $NODE_PID
   echo "Node $NODE_DIR stopped successfully."

   # Verifikasi bahwa node telah berhenti
   sleep 2
   NODE_PID_CHECK=$(ps -ef | grep 'besu' | grep "$NODE_DIR" | grep -v 'grep' | awk '{print $2}')
   if [ -z "$NODE_PID_CHECK" ]; then
      echo "Node $NODE_DIR has been successfully stopped."
   else
      echo "Failed to stop Node $NODE_DIR. PID still exists: $NODE_PID_CHECK"
   fi
fi
