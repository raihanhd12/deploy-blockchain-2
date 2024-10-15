#!/bin/bash

# Path to the source networkFiles directory
SOURCE_DIR="networkFiles"

# Copy the genesis.json file to the root directory
cp "$SOURCE_DIR/genesis.json" .

# Loop through each node directory in networkFiles/keys
NODE_COUNTER=1
for NODE_DIR in "$SOURCE_DIR/keys"/*; do
    if [ -d "$NODE_DIR" ]; then
        # Determine the destination node directory
        NODE_DEST_DIR="Node-${NODE_COUNTER}/data"
        
        # Create the destination directory if it doesn't exist
        mkdir -p "$NODE_DEST_DIR"
        
        # Copy the key files to the destination directory
        cp "$NODE_DIR/key" "$NODE_DEST_DIR/"
        cp "$NODE_DIR/key.pub" "$NODE_DEST_DIR/"
        
        # Increment the node counter
        NODE_COUNTER=$((NODE_COUNTER + 1))
    fi
done

echo "Setup completed successfully."
