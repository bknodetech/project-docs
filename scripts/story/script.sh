#!/bin/bash

# Function to display the main dashboard menu
dashboard_menu() {
    clear
    printf "
    ██████  ██   ██ ███    ██  ██████  ██████  ███████ 
    ██   ██ ██  ██  ████   ██ ██    ██ ██   ██ ██      
    ██████  █████   ██ ██  ██ ██    ██ ██   ██ █████   
    ██   ██ ██  ██  ██  ██ ██ ██    ██ ██   ██ ██      
    ██████  ██   ██ ██   ████  ██████  ██████  ███████ 

    Website: https://bknode.tech        X: https://x.com/bknodetech     Github: https://github.com/bknodetech

    WELCOME TO STORY DASHBOARD BY BKNODE!
    Please choose your action:
    1. Install node
    2. Check logs
    3. Check sync status
    4. Schedule a Story client upgrade
    5. Check version
    6. Quit
    Please enter your choice: "
}

install_node() {
    read -p "Enter your moniker: " moniker

    # Define variables
    local go_version="1.21.13"
    local story_geth_version="0.9.3-b224fdf"
    local story_version="0.11.0-aac4bfe"

    # Install required packages
    sudo apt update && sudo apt upgrade -y && sudo apt install -y \
        curl git jq build-essential gcc unzip wget lz4

    # Install Go
    wget -q "https://golang.org/dl/go$go_version.linux-amd64.tar.gz" -O /tmp/go$go_version.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go$go_version.linux-amd64.tar.gz
    rm /tmp/go$go_version.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin:~/go/bin
    echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
    source ~/.bash_profile

    # Install Story Geth binary
    wget -q "https://story-geth-binaries.s3.us-west-1.amazonaws.com/geth-public/geth-linux-amd64-$story_geth_version.tar.gz" -O /tmp/geth.tar.gz
    tar -xzf /tmp/geth.tar.gz -C /tmp
    sudo mv /tmp/geth-linux-amd64-$story_geth_version/geth ~/go/bin/story-geth
    rm -rf /tmp/geth-linux-amd64-$story_geth_version /tmp/geth.tar.gz

    # Install Story binary using Cosmovisor
    wget -q "https://story-geth-binaries.s3.us-west-1.amazonaws.com/story-public/story-linux-amd64-$story_version.tar.gz" -O /tmp/story.tar.gz
    tar -xzf /tmp/story.tar.gz -C /tmp
    mkdir -p ~/.story/story/cosmovisor/genesis/bin
    sudo mv /tmp/story-linux-amd64-$story_version/story ~/.story/story/cosmovisor/genesis/bin/story
    rm -rf /tmp/story-linux-amd64-$story_version /tmp/story.tar.gz

    # Install the latest version of Cosmovisor
    go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

    # Setup Cosmovisor environment variables
    mkdir -p ~/.story/story/cosmovisor
    echo "export DAEMON_NAME=story" >> ~/.bash_profile
    echo "export DAEMON_HOME=$HOME/.story/story" >> ~/.bash_profile
    echo "export PATH=$HOME/go/bin:$DAEMON_HOME/cosmovisor/current/bin:$PATH" >> ~/.bash_profile
    source ~/.bash_profile

    # Initialize The Iliad Network Node
    ~/.story/story/cosmovisor/genesis/bin/story init --moniker "$moniker" --network iliad

    # Ask user if they want to use a snapshot
    read -p "Do you want to use a snapshot? (yes/no): " use_snapshot
    if [[ "$use_snapshot" == "yes" || "$use_snapshot" == "y"]]; then
        read -p "Enter the Story snapshot URL: " story_snapshot_url
        read -p "Enter the Story Geth snapshot URL: " story_geth_snapshot_url
        wget -q "$story_snapshot_url" -O /tmp/story_snapshot.tar.gz
        wget -q "$story_geth_snapshot_url" -O /tmp/story_geth_snapshot.tar.gz
        mkdir -p ~/.story/story
        mkdir -p ~/.story/geth/iliad/geth
        tar -xzf /tmp/story_snapshot.tar.gz -C ~/.story/story
        tar -xzf /tmp/story_geth_snapshot.tar.gz -C ~/.story/geth/iliad/geth
        rm /tmp/story_snapshot.tar.gz
        rm /tmp/story_geth_snapshot.tar.gz
        printf "\nSnapshot downloaded and extracted successfully!\n"
    fi

    # Update Peers
    local PEERS
    PEERS=$(curl -sS https://story-testnet-rpc.blockhub.id/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}' | paste -sd, -)
    printf "Updating peers...\n"
    sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" "$HOME/.story/story/config/config.toml"

    # Create and Configure systemd Services for Story-Geth and Cosmovisor
    sudo tee /etc/systemd/system/story-geth.service > /dev/null <<EOF
[Unit]
Description=Story Geth Client
After=network.target
[Service]
User=$USER
ExecStart=$HOME/go/bin/story-geth --iliad --syncmode full
Restart=on-failure
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

    sudo tee /etc/systemd/system/story.service > /dev/null <<EOF
[Unit]
Description=Cosmovisor service for Story binary
After=network.target
[Service]
User=$USER
ExecStart=$HOME/go/bin/cosmovisor run run
Restart=on-failure
RestartSec=3
LimitNOFILE=65535
Environment="DAEMON_NAME=story"
Environment="DAEMON_HOME=$HOME/.story/story"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_DATA_BACKUP_DIR=$HOME/.story/story/data"
Environment="UNSAFE_SKIP_BACKUP=true"
[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd, Enable, and Start Services
    sudo systemctl daemon-reload
    sudo systemctl enable story-geth story
    sudo systemctl start story-geth story

    printf "\nStory Node installed successfully!\n"

    # Post-install options
    while true; do
        printf "\nWhat would you like to do next?\n1. Back to dashboard menu\n2. Quit\n"
        read -p "Enter your choice: " post_install_choice
        case $post_install_choice in
            1) return ;;
            2) printf "Exiting the script. Goodbye!\n"; exit 0 ;;
            *) printf "Invalid option. Please try again.\n" ;;
        esac
    done
}

# Function to check logs
check_logs() {
    printf "\nPlease choose the logs to check:\n1. Check Story Logs\n2. Check Story-Geth Logs\n3. Quit\n"
    printf "Please enter your choice: "
    read log_choice

    case $log_choice in
        1) printf "\nChecking Story logs... Press Ctrl+C to exit\n"; sudo journalctl -u story -f -o cat ;;
        2) printf "\nChecking Story-Geth logs... Press Ctrl+C to exit\n"; sudo journalctl -u story-geth -f -o cat ;;
        3) printf "Exiting log check.\n" ;;
        *) printf "Invalid option.\n" ;;
    esac
}

# Function to check sync status
check_sync_status() {
    printf "\nChecking node sync status...\n"
    trap 'return' INT
    while true; do
        local_height=$(curl -s localhost:26657/status | jq -r '.result.sync_info.latest_block_height')
        network_height=$(curl -s https://story-testnet-rpc.blockhub.id/status | jq -r '.result.sync_info.latest_block_height')
        blocks_left=$((network_height - local_height))

        printf "\033[1;32mYour node height:\033[0m \033[1;34m%s\033[0m | \033[1;33mNetwork height:\033[0m \033[1;36m%s\033[0m | \033[1;37mBlocks left:\033[0m \033[1;31m%s\033[0m\n" "$local_height" "$network_height" "$blocks_left"
        sleep 5
    done
}

# Schedule a Story Client Upgrade
schedule_client_upgrade() {
    printf "\nSchedule a Story Client Upgrade\n"
    read -p "Enter the Client Upgrade link: " upgrade_link
    read -p "Enter the Client version: " client_version
    read -p "Enter the Upgrade Height: " upgrade_height
    
    temp_dir=$(mktemp -d)
    cd "$temp_dir"
    printf "Downloading and extracting the Client...\n"
    curl -L "$upgrade_link" | tar -xz

    client_executable=$(find . -type f -executable | head -n 1)
    if [ -z "$client_executable" ]; then
        printf "Error: No executable file found in the downloaded archive.\n"
        rm -rf "$temp_dir"
        return
    fi
    
    client_path=$(readlink -f "$client_executable")
    printf "Scheduling the upgrade...\n"
    cosmovisor add-upgrade "$client_version" "$client_path" --force --upgrade-height "$upgrade_height"
    
    rm -rf "$temp_dir"
    printf "Upgrade scheduled successfully!\n"

    while true; do
        printf "\nWhat would you like to do next?\n1. Back to dashboard menu\n2. Quit\n"
        read -p "Enter your choice: " post_upgrade_choice
        case $post_upgrade_choice in
            1) return ;;
            2) printf "Exiting the script. Goodbye!\n"; exit 0 ;;
            *) printf "Invalid option. Please try again.\n" ;;
        esac
    done
}

# Function to check version
check_version() {
    printf "\nPlease choose which version to check:\n1. Story Version\n2. Story-Geth Version\n3. Back to main menu\n"
    printf "Please enter your choice: "
    read answer

    case $answer in
        1) printf "\nChecking Story version...\n"; cosmovisor run version ;;
        2) printf "\nChecking Story-Geth version...\n"; story-geth version ;;
        3) return ;;
        *) printf "Invalid option.\n" ;;
    esac

    printf "\nPress Enter to continue..."
    read
}

# Main script loop
while true; do
    dashboard_menu
    read choice
    case $choice in
        1) install_node ;;
        2) check_logs ;;
        3) check_sync_status ;;
        4) schedule_client_upgrade ;;
        5) check_version ;;
        6) printf "Exiting the dashboard.\n"; exit 0 ;;
        *) printf "Invalid option, please try again.\n" ;;
    esac
done
