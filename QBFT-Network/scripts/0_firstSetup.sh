#!/bin/bash

# Fungsi untuk menghapus semua folder kecuali yang diizinkan
cleanup() {
    # Directories and files to keep
    KEEP_DIRS=("scripts" "quorum-explorer")

    # Remove all directories except the ones in KEEP_DIRS
    echo "Removing existing directories and files except for scripts and quorum-explorer..."
    for item in *; do
        if [[ ! " ${KEEP_DIRS[@]} " =~ " ${item} " ]]; then
            echo "Removing $item"
            rm -rf "$item"
        fi
    done
}

# Fungsi untuk mengkonversi ether ke wei
convert_to_wei() {
    local ether=$1
    local wei=$(echo "$ether * 1000000000000000000" | bc)
    echo $wei
}

# Fungsi untuk membuat file konfigurasi dengan konfigurasi default
create_default_config() {
    CURRENT_TIMESTAMP=$(printf '0x%x\n' $(date +%s))

    cat <<EOL > qbftConfigFile.json
{
    "genesis": {
        "config": {
            "chainId": 1337,
            "berlinBlock": 0,
            "contractSizeLimit": 2147483647,
            "qbft": {
                "blockperiodseconds": 5,
                "epochlength": 30000,
                "requesttimeoutseconds": 10
            }
        },
        "nonce": "0x0",
        "timestamp": "$CURRENT_TIMESTAMP",
        "gasLimit": "0x1fffffffffffff",
        "difficulty": "0x1",
        "mixHash": "0x63746963616c2062797a616e74696e65206661756c7420746f6c6572616e6365",
        "coinbase": "0x0000000000000000000000000000000000000000",
        "alloc": {
            "F84D3c1248c04D7791f7E732B110EF1d337F1CaA": {
                "privateKey": "1bda73f51aeccda93af5e06826dc4fefec67d283911bbc14ebbb1680aeb774d0",
                "balance": "0xad78ebc5ac6200000"
            },
            "d84bF43685Ca85ce262c93DfC1CcBeBdcd7400a8": {
                "privateKey": "bcd58b6b21239ce990e4c0609354fe343eb99ef47b050b8f01fed8acc4bdf012",
                "balance": "0xad78ebc5ac6200000"
            },
            "22165651631705000586f02891ccA61354239095": {
                "privateKey": "445b18b967fa467a2b66684a05a2a199e7d48353d8cb4b885ae06875437c4643",
                "balance": "0xad78ebc5ac6200000"
            }
        }
    },
    "blockchain": {
        "nodes": {
            "generate": true,
            "count": 4
        }
    }
}
EOL
    echo "Default configuration created."
}

# Fungsi untuk membuat file konfigurasi berdasarkan input pengguna
create_custom_config() {
    read -p "Enter chainId: " chainId
    read -p "Select consensus mechanism (ibft, qbft, clique): " consensus
    read -p "Enter block period seconds: " blockPeriodSeconds
    requestTimeoutSeconds=$((blockPeriodSeconds * 2))
    read -p "Enter the number of accounts to allocate: " numAlloc

    addresses=()
    balances=()

    for ((i = 1; i <= numAlloc; i++)); do
        while true; do
            read -p "Enter address for account $i: " address
            address=${address#0x} # Remove leading 0x if present
            if [[ " ${addresses[@]} " =~ " ${address} " ]]; then
                echo "Address $address has already been added. Please enter a different address."
            else
                addresses+=($address)
                break
            fi
        done
        read -p "Enter balance (in ether) for account $i: " balance
        balances+=($(convert_to_wei $balance))
    done

    read -p "Enter the number of nodes: " numNodes

    CURRENT_TIMESTAMP=$(printf '0x%x\n' $(date +%s))

    cat <<EOL > qbftConfigFile.json
{
    "genesis": {
        "config": {
            "chainId": $chainId,
            "berlinBlock": 0,
            "contractSizeLimit": 2147483647,
            "$consensus": {
                "blockperiodseconds": $blockPeriodSeconds,
                "epochlength": 30000,
                "requesttimeoutseconds": $requestTimeoutSeconds
            }
        },
        "nonce": "0x0",
        "timestamp": "$CURRENT_TIMESTAMP",
        "gasLimit": "0x1fffffffffffff",
        "difficulty": "0x1",
        "mixHash": "0x63746963616c2062797a616e74696e65206661756c7420746f6c6572616e6365",
        "coinbase": "0x0000000000000000000000000000000000000000",
        "alloc": {
EOL

    for ((i = 0; i < ${#addresses[@]}; i++)); do
        if (( i == ${#addresses[@]} - 1 )); then
            cat <<EOL >> qbftConfigFile.json
            "${addresses[$i]}": {
                "balance": "${balances[$i]}"
            }
EOL
        else
            cat <<EOL >> qbftConfigFile.json
            "${addresses[$i]}": {
                "balance": "${balances[$i]}"
            },
EOL
        fi
    done

    cat <<EOL >> qbftConfigFile.json
        }
    },
    "blockchain": {
        "nodes": {
            "generate": true,
            "count": $numNodes
        }
    }
}
EOL
    echo "Custom configuration created."
}

# Main script execution
echo "Do you want to use the default configuration? (yes/no)"
read useDefault

if [[ "$useDefault" == "yes" ]]; then
    cleanup
    create_default_config
else
    cleanup
    create_custom_config
fi

echo "Setup complete!"
